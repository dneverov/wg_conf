# main.rb или bin/sync
require_relative 'lib/file_copier'

puts "Запуск синхронизации конфигураций VPN..."
FileCopier.sync!
