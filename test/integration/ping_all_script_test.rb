require_relative 'integration_test_case'

class PingAllScriptTest < IntegrationTestCase
  setup_integration_paths 'ping_all.rb', 'pinger'

  def test_ping_all_script_shows_working_statuses_when_network_is_ok
    create_mock_config(self.class::TARGET_MOCK, 'wg2_test_active.conf')

    # Имитируем, что сеть полностью исправна (MOCK_VPN_FAIL = 'false')
    stdout, stderr, status = run_script_with_network_mock(fail_network: false)

    assert status.success?, "Скрипт завершился с ошибкой: #{stderr}"
    assert_match(/Запуск полного последовательного прозвона/, stdout)

    # РАБОТАЕТ
    assert_match(/wg2_test_active\s+\[ РАБОТАЕТ \]/, stdout)
    assert_match(/Доступно рабочих конфигураций: 1 из 1/, stdout)
  end

  def test_ping_all_script_shows_failed_statuses_when_network_fails
    create_mock_config(self.class::TARGET_MOCK, 'wg2_test_broken.conf')

    # Имитируем тотальный сбой сети или блокировку ТСПУ (MOCK_VPN_FAIL = 'true')
    stdout, _, status = run_script_with_network_mock(fail_network: true)

    assert status.success?, "Скрипт должен завершаться с кодом 0 даже при сбоях туннелей"
    assert_match(/Запуск полного последовательного прозвона/, stdout)

    # СБОЙ
    assert_match(/wg2_test_broken\s+\[   СБОЙ   \]/, stdout)
    assert_match(/Доступно рабочих конфигураций: 0 из 1/, stdout)
  end

  def test_ping_all_script_handles_empty_configurations
    stdout, _, status = run_script_with_network_mock(fail_network: false)

    assert_match(/Запуск полного последовательного прозвона/, stdout)
    assert_match(/Доступные конфигурации не найдены/, stdout)
    assert status.success?
  end

  private

    # Наш адаптированный хелпер, использующий уже существующий в проекте MOCK_VPN_FAIL
    def run_script_with_network_mock(fail_network:)
      env = {
        'TEST_ENV' => 'true',
        'CONFIG_PATH' => self.class::CONFIG_FILE,
        'MOCK_VPN_FAIL' => fail_network ? 'true' : 'false'
      }
      Open3.capture3(env, 'ruby', self.class::SCRIPT_PATH)
    end
end
