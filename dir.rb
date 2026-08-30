require 'optparse'
require_relative 'lib/file_copier'

# Мягкое предупреждение
Config.check_root_privileges

# Значение по умолчанию
options = { period: "0" }

# Настройка парсера ключей
OptionParser.new do |opts|
  opts.banner = "Использование: ruby dir.rb [options]"

  opts.on("-p", "--period PERIOD", "Период фильтрации: число дней (например, 3), 0 (сегодня) или all (все файлы)") do |p|
    options[:period] = p
  end

  opts.on("-h", "--help", "Показать эту справку") do
    puts opts
    exit
  end
end.parse!

puts "Запуск синхронизации конфигураций VPN..."

FileCopier.sync!(period_arg: options[:period])
