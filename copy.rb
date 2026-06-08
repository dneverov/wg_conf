require_relative 'lib/config'
require_relative 'lib/copier'

# 1. Check that a file name is sent
if ARGV.empty?
  puts "Error: Needs a file name!"
  puts "E.g.:  ruby copy.rb SerbiaBelgradeS3.conf"
  exit
end

# 2. Get the file name
file_name = ARGV[0]
new_name  = ARGV[1]

puts "file_name: #{file_name}"
puts "new_name:  #{new_name}"

copier = Copier.new

# abort("\n\nHold on for now")

copier.copy_config_file(file_name, new_name, show_log: true, instruction: true)
