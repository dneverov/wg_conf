require 'optparse'
require_relative 'lib/vpn_inspector'

options = { verbose: false }

OptionParser.new do |opts|
  opts.banner = "Использование: ruby vpn_check.rb [options]"

  opts.on("-v", "--verbose", "Показать детальный диагностический отчет") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Показать эту справку") do
    puts opts
    exit
  end
end.parse!

# Переменная -- финальный результат проверки для exit-кода
is_active = false

# Если запрошен подробный режим, выводим полную карту параметров
if options[:verbose]
  status = VpnInspector.detailed_status

  puts "=== ДИАГНОСТИКА VPN СОЕДИНЕНИЯ ==="
  puts "Шаблон сервиса systemd : #{status[:vpn_service]}*"
  puts "Статус службы systemd  : #{status[:service_active] ? 'АКТИВЕН' : 'ВЫКЛЮЧЕН / НЕ НАЙДЕН'}"
  puts "Сетевой интерфейс      : #{status[:interface_name] || 'НЕ ПОДНЯТ'}"
  puts "Хост проверки трафика  : #{status[:ping_host]}"
  puts "Прохождение пинга      : #{status[:ping_successful] ? 'УСПЕШНО' : 'СБОЙ / БЛОКИРОВКА ТСПУ'}"
  puts "=" * 34

  is_active = status[:ping_successful]
else
  # Если режим не подробный — вызываем легковесный метод напрямую
  is_active = VpnInspector.connection_active?
end

# Финальный лаконичный вывод
print "Проверка VPN-соединения... "

if is_active
  puts "РАБОТАЕТ (Трафик успешно проходит)"
  exit 0
else
  puts "ОШИБКА (Интерфейс отключен или трафик блокируется ТСПУ)"
  exit 1
end
