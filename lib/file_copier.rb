require 'fileutils'
require_relative 'config'
require_relative 'copier'

class FileCopier
  class << self
    def sync!
      # 1. Валидация директорий
      source = Config.source_dir
      target = Config.target_dir

      unless Dir.exist?(source)
        raise "Ошибка синхронизации: Исходная папка не существует (#{source})"
      end

      unless Dir.exist?(target)
        raise "Целевая папка не найдена (#{target})"
      end

      # 2. Поиск файлов (ищем .conf, .wg, .json файлы конфигураций)
      # Если вам нужны абсолютно все файлы, можно использовать '*.*'
      files = Dir.glob(File.join(source, '*.{conf,wg,json,vpn}'))

      if files.empty?
        puts "В папке #{source} не найдено файлов конфигураций для копирования."
        return false
      end

      # 3. Процесс копирования
      copier = Copier.new
      copied_count = 0
      files.each do |file_path|
        file_name = File.basename(file_path)

        # Копируем файл (перезапишет файл, если он уже есть)
        copier.copy_config_file(file_name)
        puts "Скопирован: #{file_name} -> #{target}"
        copied_count += 1
      end

      puts "Успешно синхронизировано файлов: #{copied_count}."
      true
    end
  end
end
