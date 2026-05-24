class Copier
  # Config
  SOURCE_DIR = '~/Downloads/amnezia_wg2.0'
  TARGET_DIR = '~/Downloads/1'
  # Rename pattern
  RENAME_PATTERN = 'wg2_%.3s_%.3s_%s.conf'

  attr_reader :source_dir, :target_dir

  def initialize
    @source_dir = expand_path(SOURCE_DIR)
    @target_dir = expand_path(TARGET_DIR)
  end

  # The Main action

  def copy_config_file(source_file, target = nil, instruction: false)
    target_file = target || rename(source_file)

    # Set paths
    source_path = "#{source_dir}/#{source_file}"
    target_path = "#{target_dir}/#{target_file}"

    # Check that the source file exists
    unless File.exist?(source_path)
      puts "Error: File #{source_path} not found!"
      exit
    end

    puts "Attempting to copy #{source_file} to system folder..."

    # 4. Call cp via sudo
    result = system_copy(source_path, target_path)

    if result
      puts "Done! The file has been copied to #{target_path}"
      show_instruction(target_file) if instruction
    else
      puts "Failed to copy file. The sudo password may be incorrect."
    end
  end

  private

    def expand_path(path)
      File.expand_path(path)
    end

    def rename(file)
      parts = File.basename(file).scan(/[A-Z][a-z]+|[A-Z]\d+/)

      sprintf(
        RENAME_PATTERN,
        parts[0].downcase,
        parts[1].downcase,
        parts.last
      )
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
