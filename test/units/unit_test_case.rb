require 'minitest/autorun'
require 'fileutils'
require 'yaml'
require_relative '../../lib/config'

class UnitTestCase < Minitest::Test
  # Хелпер для динамического задания путей
  def self.setup_unit_paths(dir_suffix)
    const_set(:TEST_DIR,     File.expand_path("../test_files_#{dir_suffix}", __dir__))
    const_set(:CONFIG_FILE,  File.join(self::TEST_DIR, 'config_test.yml'))
    const_set(:SRC_MOCK_DIR, File.join(self::TEST_DIR, 'src_mock'))
    const_set(:TXT_MOCK_DIR, File.join(self::TEST_DIR, 'target_mock'))
  end

  def setup
    ENV['CONFIG_PATH'] = self.class::CONFIG_FILE

    FileUtils.mkdir_p(self.class::TEST_DIR)
    FileUtils.mkdir_p(self.class::SRC_MOCK_DIR)
    FileUtils.mkdir_p(self.class::TXT_MOCK_DIR)

    # Записываем конфигурацию и принудительно перечитываем её в память
    write_test_config(self.class::SRC_MOCK_DIR, self.class::TXT_MOCK_DIR)
    Config.load_data!
  end

  def teardown
    FileUtils.rm_rf(self.class::TEST_DIR)
    ENV.delete('CONFIG_PATH')
  end

  private

    # Переиспользуемый хелпер для создания файлов конфигурации
    def create_mock_config(directory, name, days_old: 0, content: 'dummy')
      file_path = File.join(directory, name)
      File.write(file_path, content)

      if days_old > 0
        target_time = Time.now - (days_old * 24 * 60 * 60)
        File.utime(target_time, target_time, file_path) # Используем File.utime вместо FileUtils.touch
      end

      file_path
    end

    def write_test_config(source, target)
      hash = { 'config' => { 'source_dir' => source, 'target_dir' => target } }
      File.write(self.class::CONFIG_FILE, hash.to_yaml)
    end
end
