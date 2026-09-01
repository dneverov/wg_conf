require_relative 'config'

class VpnRunner
  class << self
    def run!(config_name = nil)
      # TODO: Use a separate method
      target_dir = Config.target_dir rescue nil
      raise "Целевая папка не задана в конфигурации" if target_dir.nil?

      # Если имя конфига не передано, ищем первый доступный .conf файл в целевой папке
      if config_name.nil?
        available_configs = Dir.glob(File.join(target_dir, '*.conf'))
        if available_configs.empty?
          puts "Ошибка: В папке #{target_dir} не найдено активных конфигураций VPN."
          return false
        end
        # Берем базовое имя без пути и без расширения (например, "wg2_chi_san")
        config_name = File.basename(available_configs.first, '.conf')
      else
        config_name = File.basename(config_name, '.conf')
      end

      service_name = "awg-quick@#{config_name}.service" # Для AmneziaWG

      puts "Инициализация VPN соединения: #{config_name}..."

      # 1. Останавливаем любые запущенные ранее туннели awg-quick, чтобы не было конфликтов
      puts "Сброс старых подключений..."
      execute_command("sudo systemctl stop 'awg-quick@*'")

      # 2. Запускаем новый выбранный конфиг
      puts "Запуск сервиса #{service_name}..."
      if execute_command("sudo systemctl start #{service_name}")
        puts "VPN успешно запущен!"
        puts "-" * 40
        show_status(config_name)
        true
      else
        puts "Ошибка: Не удалось запустить сервис #{service_name}."
        puts "Проверьте логи команды: sudo journalctl -u #{service_name} -n 20"
        false
      end
    end

    private

      # Обертка для всех системных вызовов
      def execute_command(cmd)
        system(cmd)
      end

      # Вывод реального сетевого интерфейса и статуса
      def show_status(interface_name)
        puts "Текущий статус интерфейса #{interface_name}:"
        # Показывает статус утилиты wg (или awg, в зависимости от того, что установлено в системе)
        if execute_command("which awg > /dev/null 2>&1")
          execute_command("sudo awg show #{interface_name}")
        elsif execute_command("which wg > /dev/null 2>&1")
          execute_command("sudo wg show #{interface_name}")
        else
          execute_command("ip a show dev #{interface_name}")
        end
      end
  end
end
