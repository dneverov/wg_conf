require 'minitest/autorun'
require 'fileutils'
require 'yaml'

# Загружаем класс один раз в самом начале
require_relative '../../lib/config'

class ConfigTest < Minitest::Test
  TEST_DIR     = File.expand_path('../test_files', __dir__)
  CONFIG_FILE  = File.join(TEST_DIR, 'config_test.yml')
  EXAMPLE_FILE = "#{CONFIG_FILE}.example"

  def setup
    # Всегда явно прописываем ENV перед тестом
    ENV['CONFIG_PATH'] = CONFIG_FILE
    FileUtils.mkdir_p(TEST_DIR)
    clean_files
  end

  def teardown
    clean_files
    FileUtils.rm_rf(TEST_DIR) if Dir.exist?(TEST_DIR) && Dir.empty?(TEST_DIR)
    ENV.delete('CONFIG_PATH')
  end

  # --- ТЕСТЫ ---

  def test_correctly_parses_paths_and_expands_tilde
    write_yaml_config(
      'source_dir' => '~/Downloads/amnezia_wg2.0',
      'target_dir' => '~/Downloads/1'
    )

    # Принудительно заставляем конфиг перечитать файлы с диска
    Config.load_data!

    expected_source = File.expand_path('~/Downloads/amnezia_wg2.0')
    expected_target = File.expand_path('~/Downloads/1')

    assert_equal expected_source, Config.source_dir
    assert_equal expected_target, Config.target_dir
  end

  def test_creates_config_from_example_if_missing
    # Создаем ТОЛЬКО .example файл
    File.write(EXAMPLE_FILE, { 'config' => { 'source_dir' => '~/FromExample', 'target_dir' => '~/ToExample' } }.to_yaml)

    Config.load_data!

    assert File.exist?(CONFIG_FILE), "Тестовый конфиг должен был создаться автоматически"
    assert_equal File.expand_path('~/FromExample'), Config.source_dir
  end

  def test_raises_error_if_no_files_exist
    clean_files

    # Теперь метод гарантированно выбросит RuntimeError, так как файлов нет
    assert_raises(RuntimeError) do
      Config.load_data!
    end
  end

  private

    def clean_files
      FileUtils.rm_f(CONFIG_FILE)
      FileUtils.rm_f(EXAMPLE_FILE)
    end

    def write_yaml_config(hash)
      File.write(CONFIG_FILE, { 'config' => hash }.to_yaml)
    end
end
