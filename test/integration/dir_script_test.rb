require_relative 'integration_test_case'

class DirScriptTest < IntegrationTestCase
  # Генерирует константы SCRIPT_PATH, TEST_DIR, TARGET_MOCK и SRC_MOCK внутри класса
  setup_integration_paths 'dir.rb', 'dir'

  # Переопределяем константы для обратной совместимости со старыми тестами
  SRC_MOCK_DIR = SRC_MOCK
  TXT_MOCK_DIR = TARGET_MOCK

  def test_script_runs_with_default_period_without_flags
    File.write(File.join(SRC_MOCK_DIR, 'ChileSantiago.conf'), 'dummy')

    # Запускаем скрипт без флагов в отдельном процессе
    stdout, _, status = run_script

    assert status.success?, "Скрипт должен завершиться успешно"
    assert_match(/Запуск синхронизации конфигураций VPN.../, stdout)
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_accepts_short_period_flag
    file = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    File.write(file, 'dummy')
    FileUtils.touch(file, mtime: Time.now - (3 * 24 * 60 * 60))

    # Передаем ключ -p 3
    _, _, status = run_script("-p", "3")

    assert status.success?
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_accepts_long_period_flag
    file = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    File.write(file, 'dummy')
    FileUtils.touch(file, mtime: Time.now - (5 * 24 * 60 * 60))

    # Передаем ключ --period 5
    _, _, status = run_script("--period", "5")

    assert status.success?
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_exits_with_error_on_invalid_argument
    # Передаем некорректный параметр через ключ
    stdout, _, status = run_script("-p", "invalid_param")

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
end
