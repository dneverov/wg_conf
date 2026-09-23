require_relative 'vpn_inspector'

class VpnPinger
  class << self
    def ping_all
      target_dir = Config.target_dir
      all_files  = Config.find_files(target_dir, '*.conf')
      return [] if all_files.empty?

      interfaces = all_files.map { |f| File.basename(f, '.conf') }.sort

      interfaces.map do |interface|
        # Переиспользуем готовый метод инспектора, защищенный вашим TEST_ENV!
        status = VpnInspector.ping_successful?(interface)
        { interface: interface, active: status }
      end
    end
  end
end
