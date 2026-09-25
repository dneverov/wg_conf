require_relative 'lib/vpn_pinger'

Config.check_root_privileges(strict: true)

puts "Запуск полного последовательного прозвона VPN-конфигураций..."
puts "Каждый туннель будет временно поднят для проверки хоста #{Config.ping_host}:"
puts "-" * 50

# Передаем управление в класс, но перехватываем каждый шаг через блок { |res| ... }
results = VpnPinger.ping_all do |res|
  status_text = res[:active] ? "[ РАБОТАЕТ ]" : "[  СБОЙ   ]"
  puts "#{res[:interface].ljust(35)} #{status_text}"
end

if results.empty?
  puts "Доступные конфигурации не найдены."
  exit 0
end

success_count = results.count { |res| res[:active] }

puts "-" * 50
puts "Прозвон полностью завершен."
puts "Доступно рабочих конфигураций: #{success_count} из #{results.size}."
