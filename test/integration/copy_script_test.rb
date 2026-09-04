require_relative 'integration_test_case'

class CopyScriptTest < IntegrationTestCase
  # Автоматически генерирует константы SCRIPT_PATH, TEST_DIR, TARGET_MOCK и SRC_MOCK
  setup_integration_paths 'copy.rb', 'copy'

  # Для удобства переопределяем константы, чтобы они совпадали с логикой Copier
  SRC_MOCK_DIR = SRC_MOCK
  TXT_MOCK_DIR = TARGET_MOCK

  def test_script_requires_file_name
    # Запускаем скрипт вообще без аргументов
    stdout, _, status = run_script

    refute status.success?
    assert_match(/Error: Needs a file name!/, stdout)
    assert_match(/E.g.:  ruby copy.rb/, stdout)
  end

  def test_script_copies_file_with_auto_renaming
    # 1. Создаем фейковый исходный файл в папке src_mock
    create_mock_config(SRC_MOCK_DIR, 'ChileSantiago.conf')

    # 2. Запускаем скрипт, передав только имя файла (target_name = nil)
    stdout, _, status = run_script('ChileSantiago.conf')

    assert status.success?
    assert_match(/Attempting to copy ChileSantiago.conf to system folder.../, stdout)
    assert_match(/Done! The file has been copied to/, stdout)

    # 3. Проверяем, что файл физически скопировался в целевую папку и переименовался через Namer
    assert File.exist?(File.join(TXT_MOCK_DIR, 'wg2_chi_san.conf'))
  end

  def test_script_copies_file_with_custom_target_name
    create_mock_config(SRC_MOCK_DIR, 'ChileSantiago.conf')

    # Запускаем скрипт, передав и исходное имя, и кастомное целевое имя
    stdout, _, status = run_script('ChileSantiago.conf', 'custom_chile.conf')

    assert status.success?
    assert_match(/Done! The file has been copied to.*custom_chile.conf/, stdout)

    # Файл должен создаться строго с тем именем, которое мы передали вручную
    assert File.exist?(File.join(TXT_MOCK_DIR, 'custom_chile.conf'))
  end
end
