require_relative 'config'

class VpnLister
  class << self
    # Основной метод, который возвращает готовую строку для вывода в терминал
    def render(sort_by: :name, columns: 3)
      files = fetch_and_sort_files(sort_by)
      return "В папке конфигураций нет доступных VPN-интерфейсов." if files.empty?

      format_columns(files, columns)
    end

    private

      def fetch_and_sort_files(sort_by)
        target_dir = Config.target_dir
        all_files = Config.find_files(target_dir, '*.conf')

        case sort_by
        when :time
          # Сортировка по времени изменения (свежие выше)
          all_files.sort_by { |f| File.mtime(f) }.reverse
        else
          # Сортировка по имени по умолчанию
          all_files.sort_by { |f| File.basename(f).downcase }
        end.map { |f| File.basename(f, '.conf') }
      end

      def format_columns(items, col_count)
        # Находим длину самого длинного имени интерфейса и добавляем отступ в 3 пробела
        max_len = items.map(&:length).max || 0
        col_width = max_len + 3

        lines = []
        # Разбиваем плоский массив на строки
        items.each_slice(col_count) do |slice|
          # Форматируем каждый элемент строки под фиксированную ширину колонки
          lines << slice.map { |item| item.ljust(col_width) }.join.strip
        end

        lines.join("\n")
      end
  end
end
