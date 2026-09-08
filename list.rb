require 'optparse'
require_relative 'lib/vpn_lister'

# Для безопасного чтения конфигурации (например, раскрытия путей)
Config.check_root_privileges(strict: false)

options = { sort: :name }

OptionParser.new do |opts|
  opts.banner = "Использование: ruby list.rb [options]"

  opts.on("-t", "--time", "Сортировать по дате изменения (свежие выше)") do
    options[:sort] = :time
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
puts "-" * 40
puts VpnLister.render(sort_by: options[:sort])
puts "-" * 40
