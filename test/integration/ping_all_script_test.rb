require_relative 'integration_test_case'

class PingAllScriptTest < IntegrationTestCase
  # Автоматически настраиваем все константы путей через хелпер базового класса
  setup_integration_paths 'ping_all.rb', 'pinger'

  def test_ping_all_script_execution_flow
    # Создаем тестовые файлы конфигураций в нашей изолированной директории TARGET_MOCK
    create_mock_config(self.class::TARGET_MOCK, 'wg2_test_active.conf')
    create_mock_config(self.class::TARGET_MOCK, 'wg2_test_broken.conf')

    # Запускаем скрипт через встроенный метод run_script, который возвращает [stdout, stderr, status]
    stdout, stderr, status = run_script

    # Проверяем структуру шапки в stdout
    assert_match(/Запуск полного последовательного прозвона/, stdout)
    assert_match(/Каждый туннель будет временно поднят/, stdout)

    # Проверяем корректность вывода статусов интерфейсов
    assert_match(/wg2_test_active\s+\[ (РАБОТАЕТ|СБОЙ) \]/, stdout)
    assert_match(/wg2_test_broken\s+\[ (РАБОТАЕТ|СБОЙ) \]/, stdout)

    # Проверяем финальную статистику в футере
    assert_match(/Прозвон полностью завершен/, stdout)
    assert status.success?, "Скрипт завершился с ошибкой: #{stderr}"
  end

  # Тест на сценарий отказа / отсутствия конфигураций
  def test_ping_all_script_handles_empty_configurations
    # В этом тесте мы намеренно НЕ создаем файлы в TARGET_MOCK (папка пустая)
    stdout, stderr, status = run_script

    # Проверяем, что шапка вывелась, но скрипт корректно обработал пустоту
    assert_match(/Запуск полного последовательного прозвона/, stdout)
    assert_match(/Доступные конфигурации не найдены/, stdout)

    # Скрипт должен завершиться успешно (exit 0), а не упасть по ошибке
    assert status.success?, "Скрипт упал вместо корректного выхода: #{stderr}"
  end
end
