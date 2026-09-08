require_relative 'unit_test_case'
require_relative '../../lib/vpn_lister'

class VpnListerTest < UnitTestCase
  setup_unit_paths 'lister'

  def test_returns_friendly_message_if_directory_is_empty
    output = VpnLister.render
    assert_match(/нет доступных VPN-интерфейсов/, output)
  end

  def test_sorts_by_name_by_default_and_removes_extension
    create_mock_config(TXT_MOCK_DIR, 'wg2_rus_mos.conf')
    create_mock_config(TXT_MOCK_DIR, 'wg2_chi_san.conf')
    create_mock_config(TXT_MOCK_DIR, 'wg2_aut_vie.conf')

    output = VpnLister.render(sort_by: :name)

    # Ожидаем алфавитный порядок без расширения .conf
    expected = "wg2_aut_vie   wg2_chi_san   wg2_rus_mos"
    assert_equal expected, output.strip
  end

  def test_sorts_by_time_fresh_files_first
    # Создаем конфигурации с разным возрастом в днях
    create_mock_config(TXT_MOCK_DIR, 'wg2_old_config.conf', days_old: 5)
    create_mock_config(TXT_MOCK_DIR, 'wg2_fresh_config.conf', days_old: 0)
    create_mock_config(TXT_MOCK_DIR, 'wg2_medium_config.conf', days_old: 2)

    output = VpnLister.render(sort_by: :time)

    # Самый свежий (0 дней) должен быть первым, старый (5 дней) — последним
    expected = "wg2_fresh_config    wg2_medium_config   wg2_old_config"
    assert_equal expected, output.strip
  end
end
