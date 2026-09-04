require 'minitest/autorun'
require 'fileutils'
require 'open3'
require 'yaml'
require_relative '../../lib/config'

class IntegrationTestCase < Minitest::Test
  # Хелпер для динамического определения путей на основе имени дочернего класса
  def self.setup_integration_paths(script_name, dir_suffix)
    const_set(:SCRIPT_PATH, File.expand_path("../../#{script_name}", __dir__))
    const_set(:TEST_DIR,    File.expand_path("../test_files_integration_#{dir_suffix}", __dir__))
    const_set(:CONFIG_FILE, File.join(self::TEST_DIR, 'config_test.yml'))
    const_set(:TARGET_MOCK, File.join(self::TEST_DIR, 'target_mock'))
    const_set(:SRC_MOCK,    File.join(self::TEST_DIR, 'src_mock'))
  end

  def setup
    FileUtils.mkdir_p(self.class::TEST_DIR)
    FileUtils.mkdir_p(self.class::TARGET_MOCK)
    FileUtils.mkdir_p(self.class::SRC_MOCK) if defined?(self.class::SRC_MOCK)

    # Генерируем универсальный конфиг (если папка SRC_MOCK не используется, она просто пропишется в YAML)
    hash = {
      'config' => {
        'source_dir' => self.class::SRC_MOCK,
        'target_dir' => self.class::TARGET_MOCK
      }
    }
    File.write(self.class::CONFIG_FILE, hash.to_yaml)
  end

  def teardown
    FileUtils.rm_rf(self.class::TEST_DIR)
  end

  private

    # Хелпер для запуска vpn_run.rb и dir.rb в изолированном подпроцессе
    def run_script(*args)
      # Передаем переменные окружения: 
      # TEST_ENV: чтобы заблокировать реальные системные cp/systemctl
      # CONFIG_PATH: чтобы скрипт читал наш тестовый конфиг с диска
      env = {
        'TEST_ENV' => 'true',
        'CONFIG_PATH' => self.class::CONFIG_FILE
      }
      # Важно: Так как в vpn_run.rb мы проверяем Process.uid == 0,
      # а тесты запускаются обычным пользователем, нам нужно симулировать, что мы уже под root.
      # Для этого в тестах мы временно подменим метод Process.uid на уровне подпроцесса, 
      # если бы запускали через специальную команду. Но проще в vpn_run.rb добавить проверку на TEST_ENV!

      # Open3.capture3 возвращает [stdout_string, stderr_string, process_status]
      Open3.capture3(env, 'ruby', self.class::SCRIPT_PATH, *args)
    end

    # Универсальный хелпер для создания конфигов с возможностью "состарить" их на N дней
    def create_mock_config(directory, name, days_old: 0, content: 'dummy')
      file_path = File.join(directory, name)
      File.write(file_path, content)

      if days_old > 0
        # Высчитываем время в секундах (N дней назад)
        target_time = Time.now - (days_old * 24 * 60 * 60)
        FileUtils.touch(file_path, mtime: target_time)
      end

      file_path
    end
end
