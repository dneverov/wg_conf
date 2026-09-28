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
  puts "Сброс старых подключений..."
  VpnRunner.stop_connections
  exit 0
end

puts "Попытка запуска VPN: #{config_name || 'последняя конфигурация'}..."

# Запускаем и получаем либо имя интерфейса, либо false
launched_interface = VpnRunner.run!(config_name, show_status: options[:status])

if launched_interface
  puts "VPN успешно запущен! Активный интерфейс: #{launched_interface}"
  Config.render_divider
else
  # Если запуск провалился, выводим диагностическую ошибку здесь
  failed_service = "#{Config.vpn_service}#{config_name || 'selected'}.service"
  puts "Ошибка: Не удалось запустить сервис #{failed_service}."
  puts "Проверьте логи команды: sudo journalctl -u #{failed_service} -n 20"
  exit 1
end
