class Namer
  COUNTRY_MAPPING = {
    "unitedkingdom" => "UK",
    "czechrepublic" => "cze",
    "usa"           => "USA"
  }

  # Rename pattern
  RENAME_PATTERN = 'wg2_%.3s_%.3s_%s'

  def self.new_config_name(source_file)
    # Get [country_code, city_code, suffix]
    parts = Namer.extract_parts(source_file)

    # Склеиваем по шаблону с помощью оператора %
    RENAME_PATTERN % parts
  end

  # Returns [country_code, city_code, suffix]
  def self.extract_parts(source_file)
    # 1. Разделяем CamelCase пробелами
    formatted = source_file
                  .gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
                  .gsub(/([a-z\d])([A-Z])/, '\1 \2')
    parts = formatted.split

    # Фолбек на случай некорректного имени
    return [source_file, "", ""] if parts.size < 3

    suffix = parts.last
    country_code = nil
    city_words = []

    # 2. Проверяем составную страну (из двух слов)
    first_two_joined = (parts[0..1] || []).join.downcase

    if COUNTRY_MAPPING.key?(first_two_joined)
      country_code = COUNTRY_MAPPING[first_two_joined]
      city_words = parts[2...-1]
    else
      # 3. Проверяем простую страну (одно слово)
      first_word = parts.first.downcase

      if COUNTRY_MAPPING.key?(first_word)
        country_code = COUNTRY_MAPPING[first_word]
      else
        country_code = first_word
      end

      city_words = parts[1...-1]
    end

    # Собираем полное название города в нижнем регистре без пробелов
    city_code = city_words.join.downcase

    [country_code, city_code, suffix]
  end
end
