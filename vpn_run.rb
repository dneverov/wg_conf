require 'bundler/setup'
require 'optparse'
require 'wg_conf_core'

# Важно: Вызываем ДО парсинга флагов с жестким перезапуском
Config.check_root_privileges(strict: true)

options = {
  stop: false,
  status: false,
  kill_switch: false # По умолчанию Kill Switch выключен
}

opt_parser = OptionParser.new do |opts|
  opts.banner = "Использование: ruby vpn_run.rb [options] [config_name]"

  # Настраиваем ключ -s для остановки
  opts.on("-s", "--stop", "Остановить текущее VPN соединение") do
    options[:stop] = true
  end

  opts.on("-i", "--status", "Показать статус интерфейса после подключения") do
    options[:status] = true
  end

  opts.on("-k", "--kill-switch", "Активировать защиту от утечки трафика (Kill Switch)") do
    options[:kill_switch] = true
  end

  opts.on("-h", "--help", "Показать эту справку") do
    puts opts
    exit
  end
end

begin
  opt_parser.parse!
rescue OptionParser::InvalidOption => e
  puts "Ошибка: #{e.message}"
  puts opt_parser
  exit 1
end

# Если передан флаг -s, выполняем только остановку и выходим
if options[:stop]
  puts "Остановка всех VPN соединений и сброс правил файрвола..."
  VpnRunner.stop_connections
  exit 0
end

# Остаток аргументов после парсинга ключей забираем из ARGV
config_name = ARGV[0]

puts "Попытка запуска VPN: #{config_name || 'последняя конфигурация'}..."

begin
  launched_interface = VpnRunner.run!(
    config_name,
    show_status: options[:status],
    kill_switch: options[:kill_switch]
  )

  puts "VPN успешно запущен! Активный интерфейс: #{launched_interface}"
  Config.render_divider
rescue => e
  # Сюда прилетят и ошибка отсутствия файлов, и ошибка падения службы systemd
  puts "Ошибка: #{e.message}"
  exit 1
end
