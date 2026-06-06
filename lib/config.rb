require 'yaml'

class Config
  FILE_PATH = 'config.yml'

  raise "Файл конфигурации не найден" unless File.exist?(FILE_PATH)

  # Сразу загружаем данные при старте класса
  DATA = YAML.load_file(FILE_PATH)

  class << self
    def source_dir
      expand_path(DATA.dig('config', 'source_dir') || '')
    end

    def target_dir
      expand_path(DATA.dig('config', 'target_dir') || '')
    end

    private

      # File.expand_path автоматически превратит '~/' в '/home/user/'
      def expand_path(path)
        File.expand_path(path)
      end
  end
end
