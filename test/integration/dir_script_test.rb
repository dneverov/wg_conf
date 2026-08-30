require 'minitest/autorun'
require 'fileutils'
require 'open3'
require 'yaml'
require_relative '../../lib/config'

class DirScriptTest < Minitest::Test
  SCRIPT_PATH  = File.expand_path('../../dir.rb', __dir__)
  TEST_DIR     = File.expand_path('../test_files_integration', __dir__)
  CONFIG_FILE  = File.join(TEST_DIR, 'config_test.yml')

  SRC_MOCK_DIR = File.join(TEST_DIR, 'src_mock')
  TXT_MOCK_DIR = File.join(TEST_DIR, 'target_mock')

  def setup
    FileUtils.mkdir_p(TEST_DIR)
    FileUtils.mkdir_p(SRC_MOCK_DIR)
    FileUtils.mkdir_p(TXT_MOCK_DIR)

    # Записываем конфигурацию
    hash = { 'config' => { 'source_dir' => SRC_MOCK_DIR, 'target_dir' => TXT_MOCK_DIR } }
    File.write(CONFIG_FILE, hash.to_yaml)
  end

  def teardown
    FileUtils.rm_rf(TEST_DIR)
  end

  def test_script_runs_with_default_period_without_flags
    File.write(File.join(SRC_MOCK_DIR, 'ChileSantiago.conf'), 'dummy')

    # Запускаем скрипт без флагов в отдельном процессе
    stdout, stderr, status = run_script

    assert status.success?, "Скрипт должен завершиться успешно"
    assert_match(/Запуск синхронизации конфигураций VPN.../, stdout)
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_accepts_short_period_flag
    file = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    File.write(file, 'dummy')
    FileUtils.touch(file, mtime: Time.now - (3 * 24 * 60 * 60))

    # Передаем ключ -p 3
    stdout, _, status = run_script("-p", "3")

    assert status.success?
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_accepts_long_period_flag
    file = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    File.write(file, 'dummy')
    FileUtils.touch(file, mtime: Time.now - (5 * 24 * 60 * 60))

    # Передаем ключ --period 5
    stdout, _, status = run_script("--period", "5")

    assert status.success?
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_exits_with_error_on_invalid_argument
    # Передаем некорректный параметр через ключ
    stdout, stderr, status = run_script("-p", "invalid_param")

    refute status.success?, "Скрипт должен завершиться с ошибкой"
    assert_equal 1, status.exitstatus
    assert_match(/Ошибка: Неверный формат периода 'invalid_param'/, stdout)
  end

  def test_script_shows_help
    stdout, _, status = run_script("-h")

    assert status.success?
    assert_match(/Использование: ruby dir.rb/, stdout)
    assert_match(/-p, --period PERIOD/, stdout)
  end

  private

    # Хелпер для безопасного запуска подпроцесса с пробросом нужной переменной окружения
    def run_script(*args)
      env = { 'CONFIG_PATH' => CONFIG_FILE }
      # Open3.capture3 возвращает [stdout_string, stderr_string, process_status]
      Open3.capture3(env, 'ruby', SCRIPT_PATH, *args)
    end
end
