require 'minitest/autorun'
require 'fileutils'
require 'open3'
require 'yaml'
require_relative '../../lib/config'

class VpnRunScriptTest < Minitest::Test
  SCRIPT_PATH = File.expand_path('../../vpn_run.rb', __dir__)
  TEST_DIR    = File.expand_path('../test_files_integration_vpn', __dir__)
  CONFIG_FILE = File.join(TEST_DIR, 'config_test.yml')
  TARGET_MOCK = File.join(TEST_DIR, 'target_mock')

  def setup
    FileUtils.mkdir_p(TEST_DIR)
    FileUtils.mkdir_p(TARGET_MOCK)

    # Записываем тестовую конфигурацию, чтобы раннер знал, где искать .conf файлы
    hash = { 'config' => { 'target_dir' => TARGET_MOCK } }
    File.write(CONFIG_FILE, hash.to_yaml)
  end

  def teardown
    FileUtils.rm_rf(TEST_DIR)
  end

  def test_script_shows_help
    stdout, _, status = run_script("-h")

    assert status.success?
    assert_match(/Использование: ruby vpn_run.rb/, stdout)
    assert_match(/-s, --stop/, stdout)
  end

  def test_script_stops_connections_with_flag
    # Запускаем с флагом -s
    stdout, _, status = run_script("-s")

    assert status.success?
    assert_match(/Сброс старых подключений.../, stdout)
    # Проверяем, что наша безопасная обертка [EXEC] вывела правильную команду systemctl
    assert_match(/\[EXEC\] systemctl stop 'awg-quick@\*'/, stdout)

    # Скрипт должен был завершиться на ветке IF и не уходить в запуск VPN
    refute_match(/Attempting to run VPN/, stdout)
  end

  def test_script_runs_latest_config_by_default
    # Создаем тестовый .conf файл в нашей фейковой целевой папке
    File.write(File.join(TARGET_MOCK, 'wg2_chi_san.conf'), 'dummy')

    stdout, _, status = run_script

    assert status.success?
    assert_match(/Attempting to run VPN with latest config.../, stdout)
    assert_match(/Инициализация VPN соединения: wg2_chi_san.../, stdout)
    assert_match(/\[EXEC\] systemctl start awg-quick@wg2_chi_san.service/, stdout)
  end

  def test_script_runs_explicit_config_if_provided
    stdout, _, status = run_script("wg2_uk_lon.conf")

    assert status.success?
    assert_match(/Attempting to run VPN with wg2_uk_lon.conf.../, stdout)
    assert_match(/\[EXEC\] systemctl start awg-quick@wg2_uk_lon.service/, stdout)
  end

  def test_script_does_not_show_status_by_default
    # Создаем фейковый конфиг, чтобы раннеру было что запускать
    File.write(File.join(TARGET_MOCK, 'wg2_chi_san.conf'), 'dummy')

    stdout, _, status = run_script

    assert status.success?
    assert_match(/VPN успешно запущен!/, stdout)

    # Проверяем, что по умолчанию диагностика скрыта
    refute_match(/Текущий статус интерфейса/, stdout)
    refute_match(/\[EXEC\] awg show/, stdout)
  end

  def test_script_shows_status_with_flag_i
    # Создаем фейковый конфиг
    File.write(File.join(TARGET_MOCK, 'wg2_chi_san.conf'), 'dummy')

    # Запускаем с флагом -i
    stdout, _, status = run_script("-i")

    assert status.success?
    assert_match(/VPN успешно запущен!/, stdout)

    # Проверяем, что флаг -i принудительно включил вывод статуса
    assert_match(/Текущий статус интерфейса wg2_chi_san:/, stdout)
    assert_match(/\[EXEC\] awg show wg2_chi_san/, stdout)
  end

  private

    # Хелпер для запуска vpn_run.rb в изолированном подпроцессе
    def run_script(*args)
      # Передаем переменные окружения: 
      # TEST_ENV: чтобы заблокировать реальные системные cp/systemctl
      # CONFIG_PATH: чтобы скрипт читал наш тестовый конфиг с диска
      env = { 
        'TEST_ENV' => 'true', 
        'CONFIG_PATH' => CONFIG_FILE
      }

      # Важно: Так как в vpn_run.rb мы проверяем Process.uid == 0,
      # а тесты запускаются обычным пользователем, нам нужно симулировать, что мы уже под root.
      # Для этого в тестах мы временно подменим метод Process.uid на уровне подпроцесса, 
      # если бы запускали через специальную команду. Но проще в vpn_run.rb добавить проверку на TEST_ENV!

      Open3.capture3(env, 'ruby', SCRIPT_PATH, *args)
    end
end
