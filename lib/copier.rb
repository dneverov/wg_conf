require_relative 'config'
require_relative 'namer'

class Copier
  attr_reader :source_dir, :target_dir

  def initialize
    @source_dir = Config.source_dir
    @target_dir = Config.target_dir
  end

  def set_path(dir, file)
    "#{dir}/#{file}"
  end

  # The Main action

  def copy(source, target)
    # Set paths
    source_path = set_path(source_dir, source)
    target_path = set_path(target_dir, target)

    # Check that the source file exists
    unless File.exist?(source_path)
      puts "Error: File #{source_path} not found!"
      exit
    end

    # Call cp
    system_copy(source_path, target_path)
  end

  def rename_and_copy(source, target = nil)
    target ||= Namer.new_config_name(source)

    target if copy(source, target)
  end

  def copy_config_file(source, target = nil, show_log: false, instruction: false)
    target_file = rename_and_copy(source, target)
    target_path = set_path(target_dir, target_file)

    if target_file
      puts "Done! The file has been copied to #{target_path}" if show_log
      show_instruction(target_file) if instruction
    else
      puts "Failed to copy file. The sudo password may be incorrect." if show_log
    end
  end

  private

    def show_instruction(file)
      base_name = File.basename(file, ".*")
      puts "\nTo run the new configuration:"
      puts "  sudo systemctl start awg-quick@#{base_name}.service\n\n"
    end

    def system_copy(source_path, target_path)
      system('cp', source_path, target_path)
    end
end
