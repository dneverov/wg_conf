require_relative 'unit_test_case'
require_relative '../../lib/vpn_lister'

class VpnListerTest < UnitTestCase
  setup_unit_paths 'lister'

  def test_returns_friendly_message_if_directory_is_empty
    output = VpnLister.render
    assert_match(/нет доступных VPN-интерфейсов/, output)
  end

  def test_sorts_by_name_vertical_columns
    create_mock_config(TXT_MOCK_DIR, 'wg2_rus_mos.conf')
    create_mock_config(TXT_MOCK_DIR, 'wg2_chi_san.conf')
    create_mock_config(TXT_MOCK_DIR, 'wg2_aut_vie.conf')
    create_mock_config(TXT_MOCK_DIR, 'wg2_deu_fra.conf')

    output = VpnLister.render(sort_by: :name)

    # Алфавитный массив: [aut_vie, chi_san, deu_fra, rus_mos]
    # При 4 элементах и row_count = 2:
    # Строка 0 (idx 0, idx 2) -> aut_vie, deu_fra
    # Строка 1 (idx 1, idx 3) -> chi_san, rus_mos
    lines = output.split("\n")
    assert_equal "wg2_aut_vie   wg2_deu_fra", lines[0].strip
    assert_equal "wg2_chi_san   wg2_rus_mos", lines[1].strip
  end

  def test_sorts_by_time_vertical_columns
    create_mock_config(TXT_MOCK_DIR, 'wg2_old.conf', days_old: 5)
    create_mock_config(TXT_MOCK_DIR, 'wg2_fresh.conf', days_old: 0)
    create_mock_config(TXT_MOCK_DIR, 'wg2_medium.conf', days_old: 2)
    create_mock_config(TXT_MOCK_DIR, 'wg2_newer.conf', days_old: 1)

    output = VpnLister.render(sort_by: :time)

    # Массив по времени: [fresh, newer, medium, old]
    # При 4 элементах и row_count = 2:
    # Строка 0 (idx 0, idx 2) -> fresh, medium
    # Строка 1 (idx 1, idx 3) -> newer, old
    lines = output.split("\n")
    assert_equal "wg2_fresh    wg2_medium", lines[0].strip
    assert_equal "wg2_newer    wg2_old", lines[1].strip
  end

  def test_sorts_by_time_with_verbose_dates_in_two_columns
    # Замораживаем или симулируем фиксированное время для проверки strftime
    t1 = Time.new(2026, 9, 11, 13, 5, 0)
    t2 = Time.new(2026, 9, 10, 12, 0, 0)

    # Используем File.utime, встроеный в UnitTestCase через create_mock_config
    file1 = create_mock_config(TXT_MOCK_DIR, 'wg2_fresh.conf')
    file2 = create_mock_config(TXT_MOCK_DIR, 'wg2_old.conf')

    File.utime(t1, t1, file1)
    File.utime(t2, t2, file2)

    output = VpnLister.render(sort_by: :time, verbose_time: true)

    # При 2 элементах и 2 колонках row_count = 1
    # Ожидаем, что они встанут в одну строку как две колонки
    assert_match(/wg2_fresh\s*2026-09-11 13:05.*wg2_old\s*2026-09-10 12:00/, output)
  end
end
