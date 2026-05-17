# Config
SOURCE_DIR = '~/Downloads'
TARGET_DIR = '~/Downloads/1'
# Remname pattern
RENAME_PATTERN = 'wg2_%.3s_%.3s_%s.conf'

def expand_path(path)
  File.expand_path(path)
end

def rename(file)
  parts = File.basename(file).scan(/[A-Z][a-z]+|[A-Z]\d+/)

  sprintf(
    RENAME_PATTERN,
    parts[0].downcase,
    parts[1].downcase,
    parts.last
  )
end

# 1. Check that a file name is sent
if ARGV.empty?
  puts "Error: Needs a file name!"
  puts "E.g.: ruby copy.rb SerbiaBelgradeS3.conf"
  exit
end

source_dir = expand_path(SOURCE_DIR)
target_dir = expand_path(TARGET_DIR)

# 2. Get the file name
file_name = ARGV[0]
new_name  = ARGV[1] || rename(file_name)

puts "file_name: #{file_name}"
puts "new_name:  #{new_name}"

# abort("Hold on for now")

# 3. Set paths
source_path = "#{source_dir}/#{file_name}"
target_path = "#{target_dir}/#{new_name}"

# Check that the source file exists
unless File.exist?(source_path)
  puts "Error: File #{source_path} not found!"
  exit
end

puts "Попытка скопировать #{file_name} в системную папку..."

# 4. Call cp via sudo
result = system('sudo', 'cp', source_path, target_path)

if result
  puts "Готово! Файл скопирован в #{target_path}"
else
  puts "Не удалось скопировать файл. Возможно, неверный пароль sudo."
end
