require_relative 'lib/vpn_pinger'

Config.check_root_privileges(strict: true)

puts "Запуск полного последовательного прозвона VPN-конфигураций..."
puts "Каждый туннель будет временно поднят для проверки хоста #{Config.ping_host}:"
puts "-" * 50

# Хелпер для выборочного подавления вывода
def silence_system_output(original_stdout)
  $stdout = File.open(File::NULL, 'w')
  yield
ensure
  $stdout.close rescue nil
  $stdout = original_stdout
end

# Запускаем пинггер в "тихом режиме" для внутренних системных puts/print
original = $stdout
results = silence_system_output(original) do
  VpnPinger.ping_all do |res|
    # На время работы нашего блока возвращаем оригинальный $stdout, чтобы напечатать строку
    $stdout = original

    status_text = res[:active] ? "[ РАБОТАЕТ ]" : "[   СБОЙ   ]"
    puts "#{res[:interface].ljust(35)} #{status_text}"

    # Снова включаем тишину перед тем, как управление вернется в недра VpnPinger/VpnRunner
    $stdout = File.open(File::NULL, 'w')
  end
end

if results.empty?
  puts "Доступные конфигурации не найдены."
  exit 0
end

success_count = results.count { |res| res[:active] }

puts "-" * 50
puts "Прозвон полностью завершен."
puts "Доступно рабочих конфигураций: #{success_count} из #{results.size}."
