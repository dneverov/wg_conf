require_relative 'lib/vpn_pinger'

Config.check_root_privileges(strict: true)

puts "Запуск полного последовательного прозвона VPN-конфигураций..."
puts "Каждый туннель будет временно поднят для проверки доступности сети:"
Config.render_divider

# Передаем оригинальный stdout прямо в блок для вывода результатов
results = Config.silence_output do |stdout|
  VpnPinger.ping_all do |res|
    status_text = res[:active] ? "[ РАБОТАЕТ ]" : "[   СБОЙ   ]"
    stdout.puts "#{res[:interface].ljust(35)} #{status_text}"
  end
end

if results.empty?
  puts "Доступные конфигурации не найдены."
  exit 0
end

Config.render_divider
puts "Прозвон полностью завершен."
puts "Доступно рабочих конфигураций: #{results.count { |r| r[:active] }} из #{results.size}."
