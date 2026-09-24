require_relative 'lib/vpn_pinger'

Config.check_root_privileges(strict: false)

puts "Запуск массового прозвона VPN-конфигураций..."
puts "Проверка доступности хоста #{Config.ping_host} через каждый туннель:"
puts "-" * 50

results = VpnPinger.ping_all

if results.empty?
  puts "Доступные конфигурации не найдены."
  exit 0
end

success_count = 0

results.each do |res|
  status_text = if res[:active]
                  success_count += 1
                  "[ РАБОТАЕТ ]"
                else
                  "[  СБОЙ   ]"
                end

  puts "#{res[:interface].ljust(35)} #{status_text}"
end

puts "-" * 50
puts "Прозвон завершен. Успешно: #{success_count} из #{results.size}."
