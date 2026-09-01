require_relative 'lib/vpn_runner'

config_name = ARGV[0]

puts "Attempting to run VPN with #{config_name}..."

VpnRunner.run!(config_name)
