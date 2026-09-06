require_relative 'integration_test_case'

class VpnCheckScriptTest < IntegrationTestCase
  # Генерирует константы SCRIPT_PATH, TEST_DIR и CONFIG_FILE (как test_files_integration_check)
  setup_integration_paths 'vpn_check.rb', 'check'

  def test_script_returns_success_when_vpn_and_traffic_are_ok
    # Имитируем, что VPN успешно работает и трафик проходит
    stdout, _, status = run_script_with_mock(active: true)

    assert status.success?, "Код возврата должен быть 0 (успех)"
    assert_match(/Проверка VPN-соединения... РАБОТАЕТ/, stdout)
  end

  def test_script_returns_failure_when_vpn_is_down_or_blocked
    # Имитируем отключение или блокировку со стороны ТСПУ
    stdout, _, status = run_script_with_mock(active: false)

    refute status.success?, "Код возврата должен быть 1 (ошибка)"
    assert_match(/Проверка VPN-соединения... ОШИБКА/, stdout)
  end

  private

    # Локальный хелпер, который пробрасывает состояние фейкового VPN в подпроцесс
    def run_script_with_mock(active:)
      env = {
        'TEST_ENV' => 'true',
        'CONFIG_PATH' => self.class::CONFIG_FILE,
        # Если active равен false (тест ошибки), то выставляем фейковый сбой в 'true'
        'MOCK_VPN_FAIL' => active ? 'false' : 'true'
      }
      Open3.capture3(env, 'ruby', self.class::SCRIPT_PATH)
    end
end
