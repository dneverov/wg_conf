require 'minitest/autorun'
require 'fileutils'
require 'stringio'
require_relative '../../lib/config'
require_relative '../../lib/vpn_runner'

class VpnRunnerTest < Minitest::Test
  TEST_DIR    = File.expand_path('../test_files_vpn', __dir__)
  TARGET_MOCK = File.join(TEST_DIR, 'target_mock')

  def setup
    FileUtils.mkdir_p(TARGET_MOCK)

    # 1. Безопасно глушим Config
    replace_method(Config, :target_dir, :orig_target) { TARGET_MOCK }

    # 2. Глушим execute_command у VpnRunner
    @executed_commands = []

    # Создаем ЛОКАЛЬНУЮ переменную. Она гарантированно пробросится внутрь блока class_eval
    commands_array = @executed_commands 

    replace_method(VpnRunner, :execute_command, :orig_execute) do |cmd|
      commands_array << cmd # Пишем в локальную переменную, контекст её видит!
      true
    end

    # Глушим puts, чтобы лог тестов оставался чистым
    @original_stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    # Возвращаем оригинальный вывод системе
    $stdout = @original_stdout

    # 3. Восстанавливаем оригинальные методы из файлов lib/
    restore_method(Config, :target_dir, :orig_target)
    restore_method(VpnRunner, :execute_command, :orig_execute)

    FileUtils.rm_rf(TEST_DIR)
  end

  # --- ТЕСТЫ ---

  def test_runs_with_explicit_config_name
    assert VpnRunner.run!("wg2_chi_san.conf")

    assert_includes @executed_commands, "systemctl stop 'awg-quick@*'"
    assert_includes @executed_commands, "systemctl start awg-quick@wg2_chi_san.service"
    assert_includes @executed_commands, "awg show wg2_chi_san"
  end

  def test_automatically_picks_latest_config_if_none_provided
    old_file    = File.join(TARGET_MOCK, 'wg2_old_config.conf')
    latest_file = File.join(TARGET_MOCK, 'wg2_UK_lon_S3.conf')

    # Создаем два файла
    File.write(old_file,    'dummy old')
    File.write(latest_file, 'dummy latest')

    # Искусственно старим один из них на час назад
    FileUtils.touch(old_file,    mtime: Time.now - 3600)
    FileUtils.touch(latest_file, mtime: Time.now)

    # Вызываем метод без аргументов
    assert VpnRunner.run!

    # Скрипт должен выбрать именно самый свежий файл, проигнорировав старый
    assert_includes @executed_commands, "systemctl start awg-quick@wg2_UK_lon_S3.service"
    refute_includes @executed_commands, "systemctl start awg-quick@wg2_old_config.service"
  end

  def test_returns_false_if_no_configs_found_and_no_argument_provided
    # Папка пустая, аргументов нет — ожидаем падение с RuntimeError
    assert_raises(RuntimeError) do
      VpnRunner.run!
    end

    assert_empty @executed_commands
  end

  def test_returns_false_if_systemctl_command_fails
    # Локально меняем поведение нашего фейкового метода на время одного теста
    VpnRunner.singleton_class.class_eval do
      remove_method :execute_command
      def execute_command(cmd)
        !cmd.include?('systemctl start')
      end
    end

    refute VpnRunner.run!("wg2_chi_san")
  ensure
    # Обязательно возвращаем базовую заглушку обратно для корректного teardown
    replace_method(VpnRunner, :execute_command, :orig_execute) do |cmd|
      @executed_commands << cmd
      true
    end
  end

  private

    # Универсальные хелперы, которые работают на уровне singleton_class
    def replace_method(klass, original_name, backup_name, &block)
      klass.singleton_class.class_eval do
        # Проверяем и публичные, и приватные методы для бэкапа
        is_private = private_method_defined?(original_name)
        alias_method backup_name, original_name if method_defined?(original_name) || is_private

        define_method(original_name, &block)

        # Если оригинальный метод был приватным, сохраняем эту приватность и для заглушки
        private original_name if is_private
      end
    end

    def restore_method(klass, original_name, backup_name)
      klass.singleton_class.class_eval do
        is_private = private_method_defined?(backup_name)

        if method_defined?(backup_name) || is_private
          remove_method original_name
          alias_method original_name, backup_name

          # Явно возвращаем методу статус private, если он был таким изначально
          private original_name if is_private

          remove_method backup_name
        end
      end
    end
end
