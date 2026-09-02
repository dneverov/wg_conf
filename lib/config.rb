require 'yaml'
require 'fileutils'

class Config
  AVAILABLE_SERVICES = {
    amnezia:   'awg-quick@', # AmneziaWG
    wireguard: 'wg-quick@'   # WireGuard
  }.freeze # Замораживаем хэш, чтобы защитить от случайного изменения

  # По умолчанию используем amnezia, но в будущем сюда можно добавить чтение из @data.dig(...)
  VPN_SERVICE = AVAILABLE_SERVICES[:amnezia]

  class << self
    def source_dir
      expand_path(@data.dig('config', 'source_dir') || '')
    end

    def target_dir
      expand_path(@data.dig('config', 'target_dir') || '')
    end

    # Публичный хелпер для получения префикса сервиса
    def vpn_service
      VPN_SERVICE
    end

    # Универсальный хелпер для поиска файлов по маске
    def find_files(directory, extension_mask)
      Dir.glob(File.join(directory, extension_mask))
    end

    # Выносим инициализацию в метод класса, чтобы его можно было безопасно перезапускать
    def load_data!
      file_path = ENV['CONFIG_PATH'] || 'config.yml'
      example_path = "#{file_path}.example"

      if !File.exist?(file_path) && File.exist?(example_path)
        puts "Локальный #{file_path} не найден. Создаю из шаблона..."
        FileUtils.cp(example_path, file_path)
      end

      raise "Файл конфигурации не найден: #{file_path}" unless File.exist?(file_path)

      @data = YAML.load_file(file_path)
    end

    # Мягкое предупреждение вместо жесткого прерывания exit 1
    def check_root_privileges(script_name = File.basename($0))
      return if Process.uid == 0

      puts "Примечание: Скрипт запущен без прав суперпользователя."
      puts "Если целевая папка защищена от записи, может потребоваться: sudo ruby #{script_name}"
      puts "-" * 40
    end

    private

      # File.expand_path автоматически превратит '~/' в '/home/user/'
      def expand_path(path)
        File.expand_path(path)
      end
  end

  # Запускаем загрузку данных при первом чтении файла
  load_data!
end
