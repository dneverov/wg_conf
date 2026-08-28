require_relative 'lib/file_copier'

puts "Запуск синхронизации конфигураций VPN..."

argument = ARGV[0] || "0"

FileCopier.sync!(period_arg: argument)
