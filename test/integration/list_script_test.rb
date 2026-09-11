require_relative 'integration_test_case'

class ListScriptTest < IntegrationTestCase
  # Автоматически генерирует константы SCRIPT_PATH, TEST_DIR, TARGET_MOCK и SRC_MOCK
  setup_integration_paths 'list.rb', 'list'

  def test_script_shows_friendly_message_if_empty
    stdout, _, status = run_script

    assert status.success?
    assert_match(/В папке конфигураций нет доступных VPN-интерфейсов/, stdout)
  end

  def test_script_shows_help
    stdout, _, status = run_script('-h')

    assert status.success?
    assert_match(/Использование: ruby list.rb/, stdout)
    assert_match(/-t, --time/, stdout)
    assert_match(/-n, --name/, stdout)
  end

  def test_script_sorts_by_name_vertically_by_default
    create_mock_config('wg2_rus_mos.conf')
    create_mock_config('wg2_chi_san.conf')
    create_mock_config('wg2_aut_vie.conf')
    create_mock_config('wg2_deu_fra.conf')

    stdout, _, status = run_script

    assert status.success?
    assert_match(/Доступные VPN-конфигурации:/, stdout)

    # Разбиваем вывод на строки, отсекая заголовки и разделители
    lines = stdout.split("\n").select { |l| l.start_with?('wg2_') }

    # [aut_vie, chi_san, deu_fra, rus_mos] при row_count = 2
    assert_match(/wg2_aut_vie.*wg2_deu_fra/, lines[0])
    assert_match(/wg2_chi_san.*wg2_rus_mos/, lines[1])
  end

  def test_script_sorts_by_time_vertically_with_flag
    # Создаем файлы с разным временем изменения (days_old)
    create_mock_config('wg2_old.conf',    days_old: 5)
    create_mock_config('wg2_fresh.conf',  days_old: 0)
    create_mock_config('wg2_medium.conf', days_old: 2)
    create_mock_config('wg2_newer.conf',  days_old: 1)

    stdout, _, status = run_script('-t')

    assert status.success?

    lines = stdout.split("\n").select { |l| l.start_with?('wg2_') }

    # Массив по времени: [fresh, newer, medium, old] при row_count = 2
    # Строка 0 -> fresh, medium
    # Строка 1 -> newer, old
    assert_match(/wg2_fresh.*wg2_medium/, lines[0])
    assert_match(/wg2_newer.*wg2_old/,    lines[1])
  end

  private

    # Локальный хелпер-прокси, который автоматически подставляет TARGET_MOCK папку
    def create_mock_config(name, days_old: 0, content: 'dummy')
      super(self.class::TARGET_MOCK, name, days_old: days_old, content: content)
    end
end
