require 'fileutils'
require 'date'
require_relative 'config'
require_relative 'copier'

class FileCopier
  class << self
    def sync!(period_arg: "0")
      # 1. Валидация директорий и входных данных
      source, target = validate_directories!
      period = parse_and_validate_period!(period_arg)

      # 2. Поиск конфигурационных файлов
      files = find_config_files(source)
      return false unless files # Прерываем, если метод вернул false

      # 3. Фильтрация по дате
      recent_files = filter_files(files, period: period)

      # 4. Процесс копирования
      copy_files!(recent_files, target)
    end

    private

      # Выполняет копирование файлов с обработкой ошибок
      def copy_files!(files_to_copy, target_dir)
        copier = Copier.new
        copied_count = 0

        files_to_copy.each do |file_path|
          file_name = File.basename(file_path)

          begin
            target_name = copier.rename_and_copy(file_name)
            puts "Скопирован: #{file_name} -> #{copier.set_path(target_dir, target_name)}"
            copied_count += 1
          rescue StandardError => e
            puts "Ошибка при копировании файла #{file_name}: #{e.message}"
          end
        end

        puts "Успешно синхронизировано файлов: #{copied_count} из #{files_to_copy.size}."
        true
      end

      # Ищет поддерживаемые типы файлов в папке-источнике
      def find_config_files(source)
        files = Dir.glob(File.join(source, '*.{conf,wg,json,vpn}'))

        if files.empty?
          puts "В папке #{source} не найдено файлов конфигураций для копирования."
          return false
        end

        files
      end

      # Фильтрует массив файлов по дате
      def filter_files(files, period: 0)
        # Если :all, сразу возвращаем файлы и выходим из метода
        return files.select { |f| File.file?(f) } if period == :all

        # Гарантированно создаем диапазон дат (для 0, 3, 10 и т.д.)
        date_range = (Date.today - period)..Date.today

        files.select do |file|
          File.file?(file) && date_range.cover?(File.mtime(file).to_date)
        end
      end

      # Проверяет существование папок и возвращает их пути кортежем
      def validate_directories!
        source = Config.source_dir
        target = Config.target_dir

        raise "Исходная папка не существует (#{source})" unless Dir.exist?(source)
        raise "Целевая папка не найдена (#{target})"     unless Dir.exist?(target)

        [source, target]
      end

      # Проверяет строку из консоли и преобразует в правильный тип данных
      def parse_and_validate_period!(period_arg)
        unless period_arg == "all" || period_arg =~ /\A\d+\z/
          puts "Ошибка: Неверный формат периода '#{period_arg}'."
          puts "Используйте число дней (например: -p 3), 0 для сегодняшних файлов или 'all' для всех."
          exit 1
        end

        period_arg == "all" ? :all : period_arg.to_i
      end
  end
end
