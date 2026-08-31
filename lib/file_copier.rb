require 'fileutils'
require 'date'
require_relative 'config'
require_relative 'copier'

class FileCopier
  class << self
    require 'date'

    def filter_files(files, period: 0)
      # Если :all, сразу возвращаем файлы и выходим из метода
      return files.select { |f| File.file?(f) } if period == :all

      # Гарантированно создаем диапазон дат (для 0, 3, 10 и т.д.)
      date_range = (Date.today - period)..Date.today

      files.select do |file|
        File.file?(file) && date_range.cover?(File.mtime(file).to_date)
      end
    end

    def sync!(period_arg: "0")
      # 1. Валидация директорий и входных данных
      source, target = validate_directories!
      period = parse_and_validate_period!(period_arg)

      # 2. Поиск конфигурационных файлов
      files = find_config_files(source)
      return false unless files # Прерываем, если метод вернул false

      recent_files = filter_files(files, period: period)

      # 3. Процесс копирования
      copier = Copier.new
      recent_files.each do |file_path|
        file_name = File.basename(file_path)

        # Копируем файл (перезапишет файл, если он уже есть)
        target_name = copier.rename_and_copy(file_name)
        puts "Скопирован: #{file_name} -> #{copier.set_path(target, target_name)}"
      end

      puts "Успешно синхронизировано файлов: #{recent_files.size}."
      true
    end

    private

      # Ищет поддерживаемые типы файлов в папке-источнике
      def find_config_files(source)
        files = Dir.glob(File.join(source, '*.{conf,wg,json,vpn}'))

        if files.empty?
          puts "В папке #{source} не найдено файлов конфигураций для копирования."
          return false
        end

        files
      end

      # Проверяем существование папок и возвращаем их пути кортежем
      def validate_directories!
        source = Config.source_dir
        target = Config.target_dir

        raise "Исходная папка не существует (#{source})" unless Dir.exist?(source)
        raise "Целевая папка не найдена (#{target})"     unless Dir.exist?(target)

        [source, target]
      end

      def parse_and_validate_period!(period_arg)
        unless period_arg == "all" || period_arg =~ /\A\d+\z/
          puts "Ошибка: Неверный формат периода '#{period_arg}'."
          puts "Используйте число дней (например: -p 3), 0 для сегодняшних файлов или 'all' для всех."
          exit 1
        end

        # Превращаем строку из консоли в правильный тип данных
        period_arg == "all" ? :all : period_arg.to_i
      end
  end
end
