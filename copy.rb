require_relative 'lib/config'
require_relative 'lib/copier'

# 1. Check that a file name is sent
if ARGV.empty?
  puts "Error: Needs a file name!"
  puts "E.g.:  ruby copy.rb SerbiaBelgradeS3.conf"
  exit
end

# Мягкое предупреждение вместо жесткого прерывания exit 1
if Process.uid != 0
  script_name = File.basename($0)
  puts "Примечание: Скрипт запущен без прав суперпользователя."
  puts "Если целевая папка защищена от записи, может потребоваться: sudo ruby #{script_name}"
  puts "-" * 40
end

# 2. Get the file name
source_name = ARGV[0]
target_name  = ARGV[1]

copier = Copier.new

# abort("\n\nHold on for now")
puts "Attempting to copy #{source_name} to system folder..."

copier.copy_config_file(source_name, target_name, show_log: true, instruction: true)
