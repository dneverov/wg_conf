require_relative 'config'
require_relative 'system_executor'

class VpnInspector
  extend SystemExecutor # Подмешивает execute_command и read_system_output

  class << self
    # Проверяет активность сервиса И реальное прохождение трафика через него
    def connection_active?
      # 1. Сначала проверяем, запущен ли сам сервис systemd
      # Перенаправляем stdout/stderr в /dev/null, чтобы команда не мусорила в консоль
      service_active = execute_command("systemctl is-active '#{Config.vpn_service}*' > /dev/null 2>&1", silent: true)
      return false unless service_active

      # 2. Пытаемся динамически узнать имя поднятого интерфейса.
      # systemctl status выведет что-то вроде "awg-quick@wg2_rus_mos_K5.service"
      # Мы вытаскиваем то, что идет после знака @
      status_output = read_system_output("systemctl list-units '#{Config.vpn_service}*' --state=active")
      interface_name = status_output.match(/#{Config.vpn_service}([^\s\.]+)/)&.captures&.first

      return false if interface_name.nil?

      # 3. Делаем проверочный пинг строго ЧЕРЕЗ этот интерфейс
      # -c 1 (один пакет), -W 2 (таймаут 2 секунды, если ТСПУ глушит пакеты)
      execute_command("ping -c 1 -W 2 -I #{interface_name} #{Config.ping_host} > /dev/null 2>&1", silent: true)
    end

    # Собирает полную карту состояния VPN для развернутого вывода
    def detailed_status
      service_pattern = "#{Config.vpn_service}*"
      service_active  = execute_command("systemctl is-active '#{service_pattern}' > /dev/null 2>&1", silent: true)

      status_output   = read_system_output("systemctl list-units '#{service_pattern}' --state=active")
      interface_name  = status_output.match(/#{Config.vpn_service}([^\s\.]+)/)&.captures&.first

      # Пинг выполняем только если интерфейс физически существует
      ping_ok = interface_name ? execute_command("ping -c 1 -W 2 -I #{interface_name} #{Config.ping_host} > /dev/null 2>&1", silent: true) : false

      {
        vpn_service: Config.vpn_service,
        service_active: service_active,
        interface_name: interface_name,
        ping_host: Config.ping_host,
        ping_successful: ping_ok
      }
    end
  end
end
