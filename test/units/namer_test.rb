require 'minitest/autorun'

$LOAD_PATH.unshift File.expand_path('../../', __dir__)
require 'lib/namer'

class NamerTest < Minitest::Test
  # Тест для составных стран из словаря (ожидаем заглавные "UK")
  def test_compound_country_from_mapping_with_suffix
    assert_equal ["UK", "london", "S3"], Namer.extract_parts("UnitedKingdomLondonS3.conf")
  end

  # Тест для простых стран из словаря (ожидаем заглавные "USA")
  def test_complex_city_name
    assert_equal ["USA", "newyorkcity", "S2"], Namer.extract_parts("USANewYorkCityS2.conf")
  end

  # Тест для простых стран, которых НЕТ в словаре (остается нижний регистр)
  def test_simple_country_with_suffix
    assert_equal ["serbia", "belgrade", "S3"], Namer.extract_parts("SerbiaBelgradeS3.conf")
  end

  def test_simple_country_without_suffix
    assert_equal ["serbia", "belgrade", ""], Namer.extract_parts("SerbiaBelgrade.conf")
  end

  def test_country_not_in_mapping
    assert_equal ["germany", "berlin", "S4"], Namer.extract_parts("GermanyBerlinS4.conf")
  end

  def test_no_suffix_handling
    assert_equal ["chile", "santiago", ""], Namer.extract_parts("ChileSantiago.conf")
  end

  def test_fallback_for_invalid_names
    assert_equal ["short", "", ""], Namer.extract_parts("Short.conf")
  end
end
