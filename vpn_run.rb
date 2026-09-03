require 'optparse'
require_relative 'lib/vpn_runner'

# Важно: Вызываем ДО парсинга флагов с жестким перезапуском
Config.check_root_privileges(strict: true)

options = { stop: false, status: false }

OptionParser.new do |opts|
  opts.banner = "Использование: ruby vpn_run.rb [options] [config_name]"

  # Настраиваем ключ -s для остановки
  opts.on("-s", "--stop", "Остановить текущее VPN соединение") do
    options[:stop] = true
  end

  opts.on("-i", "--status", "Показать статус интерфейса после подключения") do
    options[:status] = true
  end

  opts.on("-h", "--help", "Показать эту справку") do
    puts opts
    exit
  end
end.parse!

# Остаток аргументов после парсинга ключей забираем из ARGV
config_name = ARGV[0]

# Если передан флаг -s, выполняем только остановку и выходим
if options[:stop]
  VpnRunner.stop_connections
  exit 0
end

puts "Attempting to run VPN with #{config_name || 'latest config'}..."

VpnRunner.run!(config_name, show_status: options[:status])
