require 'bundler/setup' # Динамически инициализирует Gemfile
require 'wg_conf_core'

Config.check_root_privileges(strict: true)

source_file = ARGV[0]
target_file = ARGV[1]

if source_file.nil?
  puts "Использование: ruby copy.rb <source_file.conf> [target_file.conf]"
  exit 1
end

copier = Copier.new

begin
  # Копируем и получаем реальное имя целевого файла (даже если оно сгенерировано через Namer)
  final_target = copier.rename_and_copy(source_file, target_file)

  if final_target
    target_path = copier.set_path(copier.target_dir, final_target)
    base_name = File.basename(final_target, ".*")

    puts "Готово! Файл успешно скопирован в #{target_path}"
    puts "\nДля запуска новой конфигурации выполните:"
    puts "  sudo systemctl start awg-quick@#{base_name}.service\n\n"
  else
    puts "Ошибка: Не удалось скопировать файл. Возможно, пароль sudo введен неверно."
    exit 1
  end
rescue ArgumentError => e
  puts "Ошибка: #{e.message}"
  exit 1
end
