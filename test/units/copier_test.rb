require 'minitest/autorun'
require 'fileutils'

require_relative '../../lib/config'
require_relative '../../lib/namer'
# Подключаем тестируемый класс
require_relative '../../lib/copier'

class CopierTest < Minitest::Test
  def setup
    # 1. Безопасно сохраняем оригинальные методы и подставляем заглушки
    Config.singleton_class.class_eval do
      alias_method :original_source_dir, :source_dir if method_defined?(:source_dir)
      alias_method :original_target_dir, :target_dir if method_defined?(:target_dir)

      def source_dir; '/mock/source'; end
      def target_dir; '/mock/target'; end
    end

    Namer.singleton_class.class_eval do
      alias_method :original_new_config_name, :new_config_name if method_defined?(:new_config_name)

      def new_config_name(source)
        "mocked_#{source}"
      end
    end

    @copier = Copier.new

    # Перехватываем вывод puts, чтобы тесты не спамили в консоль
    @original_stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    $stdout = @original_stdout

    # Возвращаем оригинальные методы на место, предварительно удаляя заглушки
    Config.singleton_class.class_eval do
      if method_defined?(:original_source_dir)
        remove_method :source_dir # Удаляем тестовую заглушку, чтобы избежать варнинга
        alias_method :source_dir, :original_source_dir
        remove_method :original_source_dir
      end
      if method_defined?(:original_target_dir)
        remove_method :target_dir
        alias_method :target_dir, :original_target_dir
        remove_method :original_target_dir
      end
    end

    Namer.singleton_class.class_eval do
      if method_defined?(:original_new_config_name)
        remove_method :new_config_name
        alias_method :new_config_name, :original_new_config_name
        remove_method :original_new_config_name
      end
    end
  end

  # --- ТЕСТЫ ---

  def test_initialize_sets_correct_directories
    assert_equal '/mock/source', @copier.source_dir
    assert_equal '/mock/target', @copier.target_dir
  end

  def test_set_path_joins_directory_and_file
    assert_equal '/mock/source/file.conf', @copier.set_path('/mock/source', 'file.conf')
  end

  def test_copy_exits_if_source_file_does_not_exist
    File.stub :exist?, false do
      # Создаем лямбду, которая бросает ошибку вместо падения всего процесса Ruby
      exit_stub = lambda { raise "system_exit_triggered" }

      @copier.stub :exit, exit_stub do
        assert_raises(RuntimeError, "system_exit_triggered") do
          @copier.copy('missing.conf', 'target.conf')
        end

        # Проверяем, что лог об ошибке был выведен в консоль
        $stdout.rewind
        assert_match(/Error: File .*missing.conf not found!/, $stdout.read)
      end
    end
  end

  def test_copy_calls_system_copy_when_file_exists
    # Мокаем существование файла и системный вызов
    File.stub :exist?, true do
      # Проверяем, что system_copy вызывается с правильными аргументами
      mock_system_copy = lambda { |src, tgt|
        assert_equal '/mock/source/amnezia.conf', src
        assert_equal '/mock/target/target.conf', tgt
        true # Возвращаем true (успешное копирование)
      }

      @copier.stub :system_copy, mock_system_copy do
        assert @copier.copy('amnezia.conf', 'target.conf')
      end
    end
  end

  def test_rename_and_copy_uses_namer_if_target_is_nil
    File.stub :exist?, true do
      @copier.stub :system_copy, true do
        # Dynamically stub the real Namer class method
        Namer.stub :new_config_name, "mocked_amnezia.conf" do
          result = @copier.rename_and_copy('amnezia.conf')
          assert_equal 'mocked_amnezia.conf', result
        end
      end
    end
  end

  def test_rename_and_copy_uses_provided_target
    File.stub :exist?, true do
      @copier.stub :system_copy, true do
        result = @copier.rename_and_copy('amnezia.conf', 'custom.conf')
        assert_equal 'custom.conf', result
      end
    end
  end

  def test_copy_config_file_shows_log_and_instructions
    File.stub :exist?, true do
      @copier.stub :system_copy, true do
        @copier.copy_config_file('amnezia.conf', 'custom.conf', show_log: true, instruction: true)

        $stdout.rewind
        output = $stdout.read

        # Проверяем логи вывода
        assert_match(/Done! The file has been copied to \/mock\/target\/custom.conf/, output)
        assert_match(/To run the new configuration:/, output)
        assert_match(/sudo systemctl start awg-quick@custom.service/, output)
      end
    end
  end

  def test_copy_config_file_shows_failure_log_if_copy_fails
    File.stub :exist?, true do
      # Симулируем ошибку копирования (например, неверный пароль sudo)
      @copier.stub :system_copy, false do
        @copier.copy_config_file('amnezia.conf', 'custom.conf', show_log: true)

        $stdout.rewind
        output = $stdout.read
        assert_match(/Failed to copy file. The sudo password may be incorrect./, output)
      end
    end
  end
end
