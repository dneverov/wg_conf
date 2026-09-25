require_relative 'integration_test_case'

class VpnCheckScriptTest < IntegrationTestCase
  # Генерирует константы SCRIPT_PATH, TEST_DIR и CONFIG_FILE (как test_files_integration_check)
  setup_integration_paths 'vpn_check.rb', 'check'

  def test_script_returns_success_when_vpn_and_traffic_are_ok
    # Имитируем, что VPN успешно работает и трафик проходит
    stdout, _, status = run_script(mock_fail: false)

    assert status.success?, "Код возврата должен быть 0 (успех)"
    assert_match(/Проверка VPN-соединения... РАБОТАЕТ/, stdout)
  end

  def test_script_returns_failure_when_vpn_is_down_or_blocked
    # Имитируем отключение или блокировку со стороны ТСПУ
    stdout, _, status = run_script(mock_fail: true)

    refute status.success?, "Код возврата должен быть 1 (ошибка)"
    assert_match(/Проверка VPN-соединения... ОШИБКА/, stdout)
  end

  def test_script_shows_verbose_diagnostic_report_with_flag_v
    # Запускаем скрипт с флагом -v в успешном режиме
    stdout, _, status = run_script('-v', mock_fail: false)

    assert status.success?
    assert_match(/=== ДИАГНОСТИКА VPN СОЕДИНЕНИЯ ===/, stdout)
    assert_match(/Статус службы systemd  : АКТИВЕН/, stdout)
    assert_match(/Сетевой интерфейс      : wg2_mock_interface/, stdout)
    assert_match(/Прохождение пинга      : УСПЕШНО/, stdout)
  end
end
