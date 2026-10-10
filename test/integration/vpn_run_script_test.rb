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
    assert_match(/Остановка всех VPN соединений и сброс правил файрвола.../, stdout)
    # Проверяем, что наша безопасная обертка [EXEC] вывела правильную команду systemctl
    assert_match(/\[EXEC\] systemctl stop 'awg-quick@\*'/, stdout)

    # Скрипт должен был завершиться на ветке IF и не уходить в запуск VPN
    refute_match(/Попытка запуска VPN/, stdout)
  end

  def test_script_runs_latest_config_by_default
    # Создаем тестовый .conf файл в нашей фейковой целевой папке
    create_mock_config

    stdout, _, status = run_script

    assert status.success?
    assert_match(/Попытка запуска VPN: последняя конфигурация.../, stdout)
    assert_match(/Инициализация VPN соединения: wg2_chi_san.../, stdout)
    assert_match(/\[EXEC\] systemctl start awg-quick@wg2_chi_san.service/, stdout)
  end

  def test_script_runs_explicit_config_if_provided
    stdout, _, status = run_script("wg2_uk_lon.conf")

    assert status.success?
    assert_match(/Попытка запуска VPN: wg2_uk_lon.conf.../, stdout)
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

  def test_script_enables_kill_switch_with_flag_k
    # Создаем фейковый WireGuard файл, но теперь с секцией Endpoint, чтобы parser не упал
    conf_content = <<~CONF
      [Interface]
      Address = 10.0.0.2/24
      [Peer]
      Endpoint = 198.51.100.42:51820
    CONF
    create_mock_config('wg2_chi_san.conf', conf_content)

    # Запускаем с новым флагом защиты -k
    stdout, _, status = run_script("-k")

    assert status.success?
    assert_match(/VPN успешно запущен!/, stdout)
    assert_match(/Активация Kill Switch для сервера 198.51.100.42.../, stdout)

    # Проверяем, что наша безопасная обертка зафиксировала вызовы iptables в правильном порядке
    assert_match(/\[EXEC\] iptables -N WG_KILL_SWITCH/, stdout)
    assert_match(/\[EXEC\] iptables -I OUTPUT -j WG_KILL_SWITCH/, stdout)
    assert_match(/\[EXEC\] iptables -A WG_KILL_SWITCH -o wg2_chi_san -j ACCEPT/, stdout)
    assert_match(/\[EXEC\] iptables -A WG_KILL_SWITCH -j DROP/, stdout)
  end

  def test_script_cleans_firewall_rules_on_stop
    # Запускаем штатную остановку с флагом -s
    stdout, _, status = run_script("-s")

    assert status.success?
    assert_match(/Остановка всех VPN соединений и сброс правил файрвола.../, stdout)

    # Проверяем, что система выполнила полную очистку таблиц сетевого фильтра
    assert_match(/\[EXEC\] iptables -D OUTPUT -j WG_KILL_SWITCH/, stdout)
    assert_match(/\[EXEC\] iptables -F WG_KILL_SWITCH/, stdout)
    assert_match(/\[EXEC\] iptables -X WG_KILL_SWITCH/, stdout)
  end

  private

    # Проксируем вызов в базовый класс
    def create_mock_config(name = 'wg2_chi_san.conf', content = 'dummy')
      super(self.class::TARGET_MOCK, name, content: content)
    end
end
