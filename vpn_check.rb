require_relative 'lib/vpn_runner'

print "Проверка VPN-соединения... "

if VpnRunner.connection_active?
  puts "РАБОТАЕТ (Трафик успешно проходит)"
  exit 0
else
  puts "ОШИБКА (Интерфейс отключен или трафик блокируется ТСПУ)"
  exit 1
end
