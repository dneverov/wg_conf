require 'optparse'
require_relative 'lib/vpn_lister'

# Для безопасного чтения конфигурации (например, раскрытия путей)
Config.check_root_privileges(strict: false)

options = { sort: :name, verbose_time: false }

OptionParser.new do |opts|
  opts.banner = "Использование: ruby list.rb [options]"

  opts.on("-t", "--time", "Сортировать по дате изменения (свежие выше)") do
    options[:sort] = :time
  end

  # Новый комбинированный ключ для вывода детального времени
  opts.on("-d", "--details", "Сортировать по дате и выводить компактное время (2 колонки)") do
    options[:sort] = :time
    options[:verbose_time] = true
  end

  opts.on("-n", "--name", "Сортировать по имени по алфавиту (по умолчанию)") do
    options[:sort] = :name
  end

  opts.on("-h", "--help", "Показать эту справку") do
    puts opts
    exit
  end
end.parse!

puts "Доступные VPN-конфигурации:"
Config.render_divider

begin
  puts VpnLister.render(sort_by: options[:sort], verbose_time: options[:verbose_time])
rescue Errno::EACCES => e
  # Перехватываем ошибку отсутствия прав доступа
  puts "Ошибка доступа: #{e.message}"
  puts "Пожалуйста, перезапустите скрипт с правами суперпользователя:"
  puts "  sudo ruby list.rb"
rescue RuntimeError => e
  # Перехватываем уведомление о том, что папка пуста
  puts e.message
end

Config.render_divider
