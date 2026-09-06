require_relative 'unit_test_case'
require_relative '../../lib/vpn_inspector'

class VpnInspectorTest < UnitTestCase
  setup_unit_paths 'inspector'

  def setup
    super

    @commands_executed = []
    commands_array = @commands_executed

    # Используем хэш в локальной переменной. Локальная переменная образует замыкание
    # и будет на 100% доступна внутри блока class_eval!
    mock_flags = { service: true, ping: true }
    @mock_flags = mock_flags # Сохраняем ссылку, чтобы менять флаги из самих тест-методов

    replace_method(VpnInspector, :execute_command, :orig_execute) do |cmd|
      commands_array << cmd

      if cmd.include?('systemctl is-active')
        mock_flags[:service]
      elsif cmd.include?('ping')
        mock_flags[:ping]
      else
        true
      end
    end

    replace_method(VpnInspector, :read_system_output, :orig_read) do |cmd|
      commands_array << cmd
      "awg-quick@wg2_rus_mos_K5.service loaded active running"
    end
  end

  def teardown
    restore_method(VpnInspector, :execute_command, :orig_execute)
    restore_method(VpnInspector, :read_system_output, :orig_read)
    super
  end

  # --- ТЕСТЫ ---

  def test_returns_true_when_service_and_ping_are_successful
    assert VpnInspector.connection_active?

    assert_includes @commands_executed, "systemctl is-active 'awg-quick@*' > /dev/null 2>&1"
    assert_includes @commands_executed, "systemctl list-units 'awg-quick@*' --state=active"
    assert_includes @commands_executed, "ping -c 1 -W 2 -I wg2_rus_mos_K5 1.1.1.1 > /dev/null 2>&1"
  end

  def test_returns_false_instantly_if_service_is_inactive
    # Меняем флаг в нашем общем хэше через сохранённую ссылку
    @mock_flags[:service] = false

    refute VpnInspector.connection_active?

    assert_includes @commands_executed, "systemctl is-active 'awg-quick@*' > /dev/null 2>&1"
    refute_includes @commands_executed, "systemctl list-units 'awg-quick@*' --state=active"
  end

  def test_returns_false_if_ping_fails_due_to_tspu_blocking
    # Симулируем, что служба активна, но пинг падает
    @mock_flags[:service] = true
    @mock_flags[:ping] = false

    refute VpnInspector.connection_active?

    assert_includes @commands_executed, "systemctl is-active 'awg-quick@*' > /dev/null 2>&1"
    assert_includes @commands_executed, "ping -c 1 -W 2 -I wg2_rus_mos_K5 1.1.1.1 > /dev/null 2>&1"
  end
end
