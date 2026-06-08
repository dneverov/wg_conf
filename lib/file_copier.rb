require 'fileutils'
require_relative 'config'

class FileCopier
  class << self
    def sync!
      # 1. Валидация директорий
      source = Config.source_dir
      target = Config.target_dir

      unless Dir.exist?(source)
        raise "Ошибка синхронизации: Исходная папка не существует (#{source})"
      end

      # Если целевой папки нет — создаем её на лету
      unless Dir.exist?(target)
        puts "Целевая папка не найдена. Создаю: #{target}"
        FileUtils.mkdir_p(target)
      end

      # 2. Поиск файлов (ищем .conf, .wg, .json файлы конфигураций)
      # Если вам нужны абсолютно все файлы, можно использовать '*.*'
      files = Dir.glob(File.join(source, '*.{conf,wg,json,vpn}'))

      if files.empty?
        puts "В папке #{source} не найдено файлов конфигураций для копирования."
        return false
      end

      # 3. Процесс копирования
      copied_count = 0
      files.each do |file_path|
        file_name = File.basename(file_path)
        target_path = File.join(target, file_name)

        # Копируем файл (FileUtils.cp перезапишет файл, если он уже есть)
        FileUtils.cp(file_path, target_path)
        puts "Скопирован: #{file_name} -> #{target}"
        copied_count += 1
      end

      puts "Успешно синхронизировано файлов: #{copied_count}."
      true
    end
  end
end
