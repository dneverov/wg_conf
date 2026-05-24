require_relative 'lib/utils'

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

# abort("Hold on for now")

copy_config_file(file_name, new_name, instruction: true)
