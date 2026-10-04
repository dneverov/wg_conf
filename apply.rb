require 'optparse'
require 'wg_conf_core'

Config.check_root_privileges

options = { period: "0" }

OptionParser.new do |opts|
  opts.banner = "Использование: ruby apply.rb [options]"

  opts.on("-p", "--period PERIOD", "Период фильтрации: число дней (например, 3), 0 (сегодня) или all (все файлы)") do |p|
    options[:period] = p
  end

  opts.on("-h", "--help", "Показать эту справку") do
    puts opts
    exit
  end
end.parse!

puts "Запуск синхронизации конфигураций VPN..."
Config.render_divider

begin
  results = FileCopier.sync!(period_arg: options[:period])

  if results.empty?
    puts "Нет подходящих файлов для копирования за указанный период."
    exit 0
  end

  # Скрипт просто выводит готовые данные из отчета
  results.each do |res|
    if res[:success]
      puts "Скопирован: #{res[:file]} -> #{res[:target_path]}"
    else
      puts "Ошибка при копировании файла #{res[:file]}: #{res[:error]}"
    end
  end

  # Считаем успешные прямо из массива результатов одной красивой строчкой
  copied_count = results.count { |res| res[:success] }

  Config.render_divider
  puts "Успешно синхронизировано файлов: #{copied_count} из #{results.size}."

rescue ArgumentError => e
  puts "Ошибка валидации: #{e.message}"
  exit 1
rescue RuntimeError => e
  # Сюда прилетит ошибка отсутствия конфигураций в папке
  puts "Уведомление: #{e.message}"
  exit 0
rescue StandardError => e
  puts "Критическая ошибка системы: #{e.message}"
  exit 1
end
