require_relative 'config'

class VpnLister
  class << self
    # Основной метод, который возвращает готовую строку для вывода в терминал
    def render(sort_by: :name, columns: 3, verbose_time: false)
      files = fetch_and_normalize_files
      return "В папке конфигураций нет доступных VPN-интерфейсов." if files.empty?

      sorted_files = sort_files(files, sort_by)
      items        = prepare_items(sorted_files, verbose_time)
      actual_cols  = verbose_time ? 2 : columns

      format_vertical_columns(items, actual_cols)
    end

    private

      # 1. Шаг: Собираем файлы и сразу нормализуем их в понятную структуру хэшей
      def fetch_and_normalize_files
        target_dir = Config.target_dir
        all_files  = Config.find_files(target_dir, '*.conf')

        all_files.map do |f|
          full_path = f.start_with?('/') ? f : File.join(target_dir, f)
          {
            name:  File.basename(f, '.conf'),
            mtime: File.mtime(full_path)
          }
        end
      end

      # 2. Шаг: Чистая сортировка массива хэшей в памяти
      def sort_files(files, sort_by)
        case sort_by
        when :time
          # Сортировка по времени изменения (свежие выше)
          files.sort_by { |item| item[:mtime] }.reverse
        else
          # Сортировка по имени по умолчанию
          files.sort_by { |item| item[:name].downcase }
        end
      end

      # 3. Шаг: Превращение структуры в плоские строки для колонок (с датой или без)
      def prepare_items(files, verbose_time)
        # Считаем максимальную длину имени
        max_name_len = files.map { |f| f[:name].length }.max || 0

        files.map do |item|
          if verbose_time
            formatted_time = item[:mtime].strftime('%Y-%m-%d %H:%M')
            "#{item[:name].ljust(max_name_len)} #{formatted_time}"
          else
            item[:name]
          end
        end
      end

      # 4. Шаг: Математика вертикального распределения колонок
      def format_vertical_columns(items, col_count)
        # Находим длину самого длинного имени интерфейса и добавляем отступ в 3 пробела
        max_len = items.map(&:length).max || 0
        col_width = max_len + 3

        # Рассчитываем, сколько строк нам понадобится (округление вверх)
        row_count = (items.size.to_f / col_count).ceil

        lines = []
        # Итерируемся по строкам
        row_count.times do |row_idx|
          row_items = []

          # Для каждой строки собираем элементы, которые должны стоять в разных колонках
          col_count.times do |col_idx|
            # Индекс элемента в плоском массиве при вертикальном заполнении
            item_idx = col_idx * row_count + row_idx

            if item_idx < items.size
              row_items << items[item_idx].ljust(col_width)
            end
          end

          lines << row_items.join.strip
        end

        lines.join("\n")
      end
  end
end
