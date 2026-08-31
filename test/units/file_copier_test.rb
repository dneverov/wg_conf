require 'minitest/autorun'
require 'fileutils'
require 'yaml'
require_relative '../../lib/config'
require_relative '../../lib/file_copier'

class FileCopierTest < Minitest::Test
  TEST_DIR     = File.expand_path('../test_files', __dir__)
  CONFIG_FILE  = File.join(TEST_DIR, 'config_test.yml')
  
  # Создаем временные папки для симуляции копирования
  SRC_MOCK_DIR = File.join(TEST_DIR, 'src_mock')
  TXT_MOCK_DIR = File.join(TEST_DIR, 'target_mock')

  def setup
    ENV['CONFIG_PATH'] = CONFIG_FILE
    FileUtils.mkdir_p(TEST_DIR)
    FileUtils.mkdir_p(SRC_MOCK_DIR)
    FileUtils.mkdir_p(TXT_MOCK_DIR)
    
    # Записываем в конфиг пути к нашим фейковым папкам внутри test_files/
    write_test_config(SRC_MOCK_DIR, TXT_MOCK_DIR)
    Config.load_data!
  end

  def teardown
    # Полностью вычищаем всю тестовую грязь
    FileUtils.rm_rf(TEST_DIR)
    ENV.delete('CONFIG_PATH')
  end

  # -- FileCopier.sync! --

  # --- ТЕСТЫ ---

  # TODO: Update also for supported types (without renaming)
  def test_successfully_copies_supported_files
    # 1. Создаем фейковые файлы конфигураций в папке-источнике
    File.write(File.join(SRC_MOCK_DIR, 'UnitedKingdomLondonS3.conf'), 'dummy content')
    File.write(File.join(SRC_MOCK_DIR, 'ChileSantiago.conf'), 'dummy conf')
    File.write(File.join(SRC_MOCK_DIR, 'USANewYorkCityS2.png'), 'not a config') # Этот файл копироваться НЕ должен

    # 2. Запускаем метод синхронизации
    assert execute_sync

    # 3. Проверяем, что нужные файлы скопировались, а лишние — нет
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_UK_lon_S3.conf'))
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
    refute File.exist?(File.join(TXT_MOCK_DIR, 'wg2_USA_new_S2.png')), "Файлы картинок не должны копироваться"
  end

  def test_raises_error_if_source_directory_does_not_exist
    # Удаляем исходную папку, чтобы вызвать ошибку
    FileUtils.rm_rf(SRC_MOCK_DIR)

    assert_raises(RuntimeError) do
      execute_sync
    end
  end

  def test_raises_error_if_target_directory_does_not_exist
    # Удаляем целевую папку, чтобы вызвать ошибку
    FileUtils.rm_rf(TXT_MOCK_DIR)

    assert_raises(RuntimeError) do
      execute_sync
    end
  end

  def test_returns_false_if_no_files_found_to_copy
    # Оставляем исходную папку пустой
    refute execute_sync, "Должен вернуть false, так как копировать нечего"
  end

  # --- НОВЫЕ ТЕСТЫ ДЛЯ ПЕРИОДОВ ВРЕМЕНИ ---

  def test_filters_files_by_period_today
    # Создаем один сегодняшний файл и один старый (5 дней назад)
    today_file = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    old_file = File.join(SRC_MOCK_DIR, 'UnitedKingdomLondonS3.conf')

    File.write(today_file, 'today')
    File.write(old_file, 'old')

    # Искусственно «старим» один файл на 5 дней назад
    five_days_ago = Time.now - (5 * 24 * 60 * 60)
    FileUtils.touch(old_file, mtime: five_days_ago)

    # Запускаем для "0" (сегодня)
    assert execute_sync("0")

    # Сегодняшний должен скопироваться, старый — нет
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
    refute File.exist?(File.join(TXT_MOCK_DIR, 'wg2_UK_lon_S3.conf'))
  end

  def test_filters_files_by_period_integer_days
    file_3_days_ago = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    file_5_days_ago = File.join(SRC_MOCK_DIR, 'UnitedKingdomLondonS3.conf')

    File.write(file_3_days_ago, '3 days')
    File.write(file_5_days_ago, '5 days')

    # Меняем время модификации файлов
    FileUtils.touch(file_3_days_ago, mtime: Time.now - (3 * 24 * 60 * 60))
    FileUtils.touch(file_5_days_ago, mtime: Time.now - (5 * 24 * 60 * 60))

    # Ищем файлы за последние 4 дня
    assert execute_sync("4")

    # Файл 3-дневной давности копируется, 5-дневной — игнорируется
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
    refute File.exist?(File.join(TXT_MOCK_DIR, 'wg2_UK_lon_S3.conf'))
  end

  def test_copies_all_files_when_period_is_all
    old_file = File.join(SRC_MOCK_DIR, 'ChileSantiago.conf')
    File.write(old_file, 'old')
    FileUtils.touch(old_file, mtime: Time.now - (100 * 24 * 60 * 60)) # 100 дней назад

    # С параметром "all" дата не важна
    assert execute_sync("all")
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  # Leave the original `FileCopier.sync!` to catch an error message
  def test_exits_with_error_on_invalid_period_argument
    # Отключаем вывод puts в поток $stdout на время теста, чтобы не мусорить в консоли
    captured_stdout = StringIO.new
    original_stdout = $stdout

    # Перехватываем системный вызов exit(1)
    begin
      $stdout = captured_stdout

      exception = assert_raises(SystemExit) do
        FileCopier.sync!(period_arg: "invalid_param")
      end
    ensure
      # Этот блок выполнится всегда: и при успехе, и при падении теста
      $stdout = original_stdout
    end

    # Проверяем и код завершения, и текст ошибки
    assert_equal 1, exception.status
    assert_match(/Ошибка: Неверный формат периода 'invalid_param'/, captured_stdout.string)
    assert_match(/Используйте число дней/, captured_stdout.string)
  end

  def test_continues_copying_if_one_file_fails
    # Симуляция. Сообщение об ошибке
    error_message = "Диск переполнен или доступ запрещен"
    # 1. Создаем два фейковых файла в исходной папке
    good_file = 'ChileSantiago.conf'
    bad_file  = 'UnitedKingdomLondonS3.conf'

    File.write(File.join(SRC_MOCK_DIR, good_file), 'dummy content')
    File.write(File.join(SRC_MOCK_DIR, bad_file),  'dummy content')

    # 2. Перехватываем создание объекта Copier
    original_new = Copier.method(:new)

    Copier.stub(:new, ->(*args) {
      instance = original_new.call(*args)

      # Сохраняем оригинальный метод именно этого инстанса
      original_rename = instance.method(:rename_and_copy)

      # Подменяем метод у конкретного живого объекта
      instance.define_singleton_method(:rename_and_copy) do |file_name|
        if file_name == bad_file
          raise StandardError, error_message
        else
          original_rename.call(file_name)
        end
      end

      instance
    }) do
      # 3. Запускаем синхронизацию и ловим вывод в переменную output
      output_text = nil
      result = execute_sync do |output|
        output_text = output
      end

      # 4. Проверяем отказоустойчивость
      assert result, "Метод должен вернуть true, даже если один файл сломался"

      # Хороший файл должен успешно скопироваться
      assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))

      # Плохой файл не должен появиться в целевой папке
      refute File.exist?(File.join(TXT_MOCK_DIR, 'wg2_UK_lon_S3.conf'))

      # ПРОВЕРЯЕМ, что пользователю напечатался правильный текст ошибки
      assert_match(/Ошибка при копировании файла #{bad_file}/, output_text)
      assert_match(/#{error_message}/, output_text)

      # Также проверяем, что об успехе тоже вывелась правильная информация
      assert_match(/Успешно синхронизировано файлов: 1 из 2/, output_text)
    end
    # // do
  end
  # // test_continues_copying_if_one_file_fails

  private

    def write_test_config(src, target)
      hash = { 'config' => { 'source_dir' => src, 'target_dir' => target } }
      File.write(CONFIG_FILE, hash.to_yaml)
    end

    # A wrapper method for the `FileCopier.sync!`
    def execute_sync(period_arg = "0")
      # Перенаправляем стандартный вывод в "виртуальную строку"
      original_stdout = $stdout
      captured_stdout = StringIO.new
      $stdout = captured_stdout

      # Вызываем оригинальный метод и сохраняем его результат
      result = FileCopier.sync!(period_arg: period_arg)

      # ЕСЛИ в тест передан блок, отдаем туда строку с выводом консоли
      yield(captured_stdout.string) if block_given?

      result
    ensure
      # Гарантированно возвращаем поток вывода системе, даже если sync! выбросит ошибку
      $stdout = original_stdout
    end
end
