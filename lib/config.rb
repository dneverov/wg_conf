require 'yaml'
require 'fileutils'

class Config
  FILE_PATH    = 'config.yml'
  EXAMPLE_PATH = 'config.yml.example'

  # Если реального конфига нет, но есть шаблон — создаем его на лету
  if !File.exist?(FILE_PATH) && File.exist?(EXAMPLE_PATH)
    puts "Локальный #{FILE_PATH} не найден. Создаю из шаблона..."
    FileUtils.cp(EXAMPLE_PATH, FILE_PATH)
  end

  # Если файла все еще нет (нет и шаблона) — выкидываем ошибку
  raise "Файл конфигурации не найден: #{FILE_PATH}" unless File.exist?(FILE_PATH)

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
