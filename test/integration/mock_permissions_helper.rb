# Этот файл подгрузится интерпретатором ДО старта list.rb
# Подменяем метод на уровне синглтон-класса File для этого подпроцесса
class << File
  alias_method :orig_readable?, :readable?
  def readable?(path)
    # Если проверяется тестовая папка конфигураций — симулируем отказ прав
    path == Config.target_dir ? false : orig_readable?(path)
  end
end
