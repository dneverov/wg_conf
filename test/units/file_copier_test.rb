require 'minitest/autorun'
require 'fileutils'
require 'yaml'
require_relative '../../lib/config'
require_relative '../../lib/file_copier'

class FileCopierTest < Minitest::Test
  TEST_DIR     = File.expand_path('../test_files', __dir__)
  CONFIG_FILE  = File.join(TEST_DIR, 'config_test.yml')
  
  # Создаем временные папки для симуляции копирования
  SRC_MOCK_DIR = File.join(TEST_DIR, 'src_mock')
  TXT_MOCK_DIR = File.join(TEST_DIR, 'target_mock')

  def setup
    ENV['CONFIG_PATH'] = CONFIG_FILE
    FileUtils.mkdir_p(TEST_DIR)
    FileUtils.mkdir_p(SRC_MOCK_DIR)
    FileUtils.mkdir_p(TXT_MOCK_DIR)
    
    # Записываем в конфиг пути к нашим фейковым папкам внутри test_files/
    write_test_config(SRC_MOCK_DIR, TXT_MOCK_DIR)
    Config.load_data!
  end

  def teardown
    # Полностью вычищаем всю тестовую грязь
    FileUtils.rm_rf(TEST_DIR)
    ENV.delete('CONFIG_PATH')
  end

  # --- ТЕСТЫ ---

  # TODO: Update also for supported types (without renaming)
  def test_successfully_copies_supported_files
    # 1. Создаем фейковые файлы конфигураций в папке-источнике
    File.write(File.join(SRC_MOCK_DIR, 'UnitedKingdomLondonS3.conf'), 'dummy content')
    File.write(File.join(SRC_MOCK_DIR, 'ChileSantiago.conf'), 'dummy conf')
    File.write(File.join(SRC_MOCK_DIR, 'USANewYorkCityS2.png'), 'not a config') # Этот файл копироваться НЕ должен

    # 2. Запускаем метод синхронизации
    assert FileCopier.sync!

    # 3. Проверяем, что нужные файлы скопировались, а лишние — нет
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_UK_lon_S3.conf'))
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
    refute File.exist?(File.join(TXT_MOCK_DIR, 'wg2_USA_new_S2.png')), "Файлы картинок не должны копироваться"
  end

  def test_raises_error_if_source_directory_does_not_exist
    # Удаляем исходную папку, чтобы вызвать ошибку
    FileUtils.rm_rf(SRC_MOCK_DIR)

    assert_raises(RuntimeError) do
      FileCopier.sync!
    end
  end

  def test_raises_error_if_target_directory_does_not_exist
    # Удаляем целевую папку, чтобы вызвать ошибку
    FileUtils.rm_rf(TXT_MOCK_DIR)

    assert_raises(RuntimeError) do
      FileCopier.sync!
    end
  end

  def test_returns_false_if_no_files_found_to_copy
    # Оставляем исходную папку пустой
    refute FileCopier.sync!, "Должен вернуть false, так как копировать нечего"
  end

  private

  def write_test_config(src, target)
    hash = { 'config' => { 'source_dir' => src, 'target_dir' => target } }
    File.write(CONFIG_FILE, hash.to_yaml)
  end
end
