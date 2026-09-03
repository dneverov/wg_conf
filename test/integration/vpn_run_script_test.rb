require_relative 'integration_test_case'

class VpnRunScriptTest < IntegrationTestCase
  setup_integration_paths 'vpn_run.rb', 'vpn'

  def test_script_shows_help
    stdout, _, status = run_script("-h")

    assert status.success?
    assert_match(/Использование: ruby vpn_run.rb/, stdout)
    assert_match(/-s, --stop/, stdout)
  end

  def test_script_stops_connections_with_flag
    # Запускаем с флагом -s
    stdout, _, status = run_script("-s")

    assert status.success?
    assert_match(/Сброс старых подключений.../, stdout)
    # Проверяем, что наша безопасная обертка [EXEC] вывела правильную команду systemctl
    assert_match(/\[EXEC\] systemctl stop 'awg-quick@\*'/, stdout)

    # Скрипт должен был завершиться на ветке IF и не уходить в запуск VPN
    refute_match(/Attempting to run VPN/, stdout)
  end

  def test_script_runs_latest_config_by_default
    # Создаем тестовый .conf файл в нашей фейковой целевой папке
    create_mock_config

    stdout, _, status = run_script

    assert status.success?
    assert_match(/Attempting to run VPN with latest config.../, stdout)
    assert_match(/Инициализация VPN соединения: wg2_chi_san.../, stdout)
    assert_match(/\[EXEC\] systemctl start awg-quick@wg2_chi_san.service/, stdout)
  end

  def test_script_runs_explicit_config_if_provided
    stdout, _, status = run_script("wg2_uk_lon.conf")

    assert status.success?
    assert_match(/Attempting to run VPN with wg2_uk_lon.conf.../, stdout)
    assert_match(/\[EXEC\] systemctl start awg-quick@wg2_uk_lon.service/, stdout)
  end

  def test_script_does_not_show_status_by_default
    # Создаем фейковый конфиг, чтобы раннеру было что запускать
    create_mock_config

    stdout, _, status = run_script

    assert status.success?
    assert_match(/VPN успешно запущен!/, stdout)

    # Проверяем, что по умолчанию диагностика скрыта
    refute_match(/Текущий статус интерфейса/, stdout)
    refute_match(/\[EXEC\] awg show/, stdout)
  end

  def test_script_shows_status_with_flag_i
    # Создаем фейковый конфиг
    create_mock_config

    # Запускаем с флагом -i
    stdout, _, status = run_script("-i")

    assert status.success?
    assert_match(/VPN успешно запущен!/, stdout)

    # Проверяем, что флаг -i принудительно включил вывод статуса
    assert_match(/Текущий статус интерфейса wg2_chi_san:/, stdout)
    assert_match(/\[EXEC\] awg show wg2_chi_san/, stdout)
  end

  private

    # Проксируем вызов в базовый класс
    def create_mock_config(name = 'wg2_chi_san.conf', content = 'dummy')
      super(self.class::TARGET_MOCK, name, content: content)
    end
end
