class Copier
  require_relative 'namer'

  attr_reader :source_dir, :target_dir

  def initialize
    @source_dir = Config.source_dir
    @target_dir = Config.target_dir
  end

  # The Main action

  def copy_config_file(source_file, target = nil, show_log: false, instruction: false)
    target_file = target || Namer.new_config_name(source_file)

    # Set paths
    source_path = set_path(source_dir, source_file)
    target_path = set_path(target_dir, target_file)

    # Check that the source file exists
    unless File.exist?(source_path)
      puts "Error: File #{source_path} not found!"
      exit
    end

    puts "Attempting to copy #{source_file} to system folder..." if show_log

    # 4. Call cp via sudo
    result = system_copy(source_path, target_path)

    if result
      puts "Done! The file has been copied to #{target_path}" if show_log
      show_instruction(target_file) if instruction
    else
      puts "Failed to copy file. The sudo password may be incorrect." if show_log
    end
  end

  private

    def set_path(dir, file)
      "#{dir}/#{file}"
    end

    def show_instruction(file)
      base_name = File.basename(file, ".*")
      puts 'To run the new configuration:'
      puts "  sudo systemctl start awg-quick@#{base_name}.service"
    end

    def system_copy(source_path, target_path)
      system('sudo', 'cp', source_path, target_path)
    end
end
