require_relative 'config'

class VpnRunner
  class << self
    def run!(config_name = nil, show_status: false)
      target_dir  = Config.target_dir
      # Метод вернет имя или выбросит raise
      config_name = get_interface_name(target_dir, config_name)

      puts "Инициализация VPN соединения: #{config_name}..."

      # 1. Останавливаем любые запущенные ранее туннели awg-quick, чтобы не было конфликтов
      stop_connections

      # 2. Запускаем новый выбранный конфиг
      start_connection(config_name, show_status: show_status)
    end

    def stop_connections
      puts "Сброс старых подключений..."
      # sudo systemctl stop 'awg-quick@*'
      execute_command("systemctl stop '#{Config.vpn_service}*'")
    end

    def start_connection(config_name, show_status:)
      service_name = "#{Config.vpn_service}#{config_name}.service"

      puts "Запуск сервиса #{service_name}..."
      if execute_command("systemctl start #{service_name}")
        puts "VPN успешно запущен!"
        puts "-" * 40
        show_status(config_name) if show_status
        true
      else
        puts "Ошибка: Не удалось запустить сервис #{service_name}."
        puts "Проверьте логи команды: sudo journalctl -u #{service_name} -n 20"
        false
      end
    end

    # Проверяет активность сервиса И реальное прохождение трафика через него
    def connection_active?
      # Если мы в режиме теста, смотрим на специальный флаг из ENV
      if ENV['TEST_ENV'] == 'true'
        return ENV['MOCK_VPN_ACTIVE'] == 'true'
      end

      # 1. Сначала проверяем, запущен ли сам сервис systemd
      # Перенаправляем stdout/stderr в /dev/null, чтобы команда не мусорила в консоль
      service_active = execute_command("systemctl is-active '#{Config.vpn_service}*' > /dev/null 2>&1")
      return false unless service_active

      # 2. Пытаемся динамически узнать имя поднятого интерфейса.
      # systemctl status выведет что-то вроде "awg-quick@wg2_rus_mos_K5.service"
      # Мы вытаскиваем то, что идет после знака @
      status_output = `systemctl list-units '#{Config.vpn_service}*' --state=active`
      interface_name = status_output.match(/#{Config.vpn_service}([^\s\.]+)/)&.captures&.first

      return false if interface_name.nil?

      # 3. Делаем проверочный пинг строго ЧЕРЕЗ этот интерфейс
      # -c 1 (один пакет), -W 2 (таймаут 2 секунды, если ТСПУ глушит пакеты)
      execute_command("ping -c 1 -W 2 -I #{interface_name} 1.1.1.1 > /dev/null 2>&1")
    end

    private

      # Обертка для всех системных вызовов
      def execute_command(cmd)
        # Если скрипт запущен внутри интеграционного теста, мы просто выводим команду в stdout
        if ENV['TEST_ENV'] == 'true'
          puts "[EXEC] #{cmd}"
          true
        else
          system(cmd)
        end
      end

      def get_interface_name(target_dir, config_name = nil)
        # Если имя конфига не передано, ищем первый доступный .conf файл в целевой папке
        config_name ||= begin
          available_configs = Config.find_files(target_dir, '*.conf')

          if available_configs.empty?
            raise "В папке #{target_dir} не найдено активных конфигураций VPN."
          end

          # Находим файл с максимальным временем изменения (mtime)
          available_configs.max_by { |file| File.mtime(file) }
        end

        # Берем базовое имя без пути и без расширения (например, "wg2_chi_san")
        File.basename(config_name, '.conf')
      end

      # Вывод реального сетевого интерфейса и статуса
      def show_status(interface_name)
        puts "Текущий статус интерфейса #{interface_name}:"
        # Показывает статус утилиты wg (или awg, в зависимости от того, что установлено в системе)
        if execute_command("which awg > /dev/null 2>&1")
          execute_command("awg show #{interface_name}")
        elsif execute_command("which wg > /dev/null 2>&1")
          execute_command("wg show #{interface_name}")
        else
          execute_command("ip a show dev #{interface_name}")
        end
      end
  end
end
