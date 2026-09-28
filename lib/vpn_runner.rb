require_relative 'config'
require_relative 'system_executor'

class VpnRunner
  extend SystemExecutor # Подмешивает execute_command

  class << self
    # Возвращает имя запущенного интерфейса (String)
    def run!(config_name = nil, show_status: false)
      target_dir  = Config.target_dir
      # Метод вернет имя или выбросит raise
      config_name = get_interface_name(target_dir, config_name)

      puts "Инициализация VPN соединения: #{config_name}..."

      # 1. Останавливаем любые запущенные ранее туннели awg-quick, чтобы не было конфликтов
      stop_connections

      # 2. Запускаем новый выбранный конфиг
      if start_connection(config_name)
        show_status_info(config_name) if show_status
        config_name
      else
        false
      end
    end

    def stop_connections
      # sudo systemctl stop 'awg-quick@*'
      execute_command("systemctl stop '#{Config.vpn_service}*'")
    end

    # Просто запускает соединение и возвращает true/false
    def start_connection(config_name)
      service_name = "#{Config.vpn_service}#{config_name}.service"
      execute_command("systemctl start #{service_name}")
    end

    private

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
      def show_status_info(interface_name)
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
