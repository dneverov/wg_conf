require_relative 'config'

class VpnInspector
  class << self
    # Проверяет активность сервиса И реальное прохождение трафика через него
    def connection_active?
      # 1. Сначала проверяем, запущен ли сам сервис systemd
      # Перенаправляем stdout/stderr в /dev/null, чтобы команда не мусорила в консоль
      service_active = execute_command("systemctl is-active '#{Config.vpn_service}*' > /dev/null 2>&1")
      return false unless service_active

      # 2. Пытаемся динамически узнать имя поднятого интерфейса.
      # systemctl status выведет что-то вроде "awg-quick@wg2_rus_mos_K5.service"
      # Мы вытаскиваем то, что идет после знака @
      status_output = read_system_output("systemctl list-units '#{Config.vpn_service}*' --state=active")
      interface_name = status_output.match(/#{Config.vpn_service}([^\s\.]+)/)&.captures&.first

      return false if interface_name.nil?

      # 3. Делаем проверочный пинг строго ЧЕРЕЗ этот интерфейс
      # -c 1 (один пакет), -W 2 (таймаут 2 секунды, если ТСПУ глушит пакеты)
      execute_command("ping -c 1 -W 2 -I #{interface_name} 1.1.1.1 > /dev/null 2>&1")
    end

    private

      # Обертка для мутирующих команд (system)
      def execute_command(cmd)
        if ENV['TEST_ENV'] == 'true'
          # Если явно передали флаг сбоя — возвращаем false
          return false if ENV['MOCK_VPN_FAIL'] == 'true'
          return true
        end
        system(cmd)
      end

      # Обертка для инспектирующих команд (бэктики)
      def read_system_output(cmd)
        if ENV['TEST_ENV'] == 'true'
          # Если в тесте симулируем, что VPN выключен — возвращаем пустую строку
          return "" if ENV['MOCK_VPN_FAIL'] == 'true'

          # В режиме теста возвращаем строку с фейковым интерфейсом для парсинга
          return "awg-quick@wg2_mock_interface.service loaded active running"
        end
        `#{cmd}`
      end
  end
end
