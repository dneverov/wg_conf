# wg_conf

A lightweight and robust CLI automation toolset for managing AmneziaWG and WireGuard configuration files. It handles structured copying, renaming, sorting, listing, and network traffic status checking.

The project architecture relies on an externalized backend library [wg_conf_core](https://github.com/dneverov/wg_conf_core) to handle pure business logic, while this repository acts as the clean execution interface.

---

## Prerequisites

Before installing and running the scripts, ensure your Linux system meets the following requirements:

### 1. AmneziaWG Kernel Module & Tools
The system must have the active AmneziaWG kernel module and its associated CLI tools installed and configured:
* **Kernel Module:** `amneziawg` (See [AmneziaWG Kernel Module Installation](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module))
* **CLI Tools:** `amneziawg-tools` (providing `awg` and `awg-quick` binaries, see [AmneziaWG Tools](https://github.com/amnezia-vpn/amneziawg-tools))

### 2. VPN Configuration Files
You must already possess valid, working `.conf` configuration files provided by an AmneziaWG-compatible VPN provider.
* Place these initial raw files into your designated local `source_dir` before starting the automation flow.

---

## Installation & Setup

1. Clone this repository to your target machine:
   ```bash
   git clone https://github.com/dneverov/wg_conf.git
   cd wg_conf
   ```

2. Configure your local paths in `config.yml`.

3. Install all toolset dependencies including the core gem via Bundler:
   ```bash
   bundle install
   ```

---

## How To Use

### Single File Copier (`copy.rb`)

Copies a single specified configuration file from the source directory to the system target directory (defined in `config.yml`). It safely copies the file, automatically creates missing directories, and updates target paths.

#### Usage
```bash
ruby copy.rb <source_file.conf> [target_file.conf]
```

#### Arguments
* `<source_file.conf>` — **Required**. The exact name of the file in your source directory that you want to copy.
* `[target_file.conf]` — **Optional**. A new name for the file in the target directory. If omitted, the script automatically formats the name using the project's internal naming scheme (via `Namer`).

#### Examples
```bash
# Copy a file and automatically determine its optimized target name
ruby copy.rb SerbiaBelgradeS3.conf

# Copy a file and explicitly force a specific target name
ruby copy.rb SerbiaBelgradeS3.conf wg2_ser_bel_S3.conf
```


### Configuration Applier (`apply.rb`)

Applies downloaded VPN configuration files from your local directory into the system target folder (e.g., `/etc/amnezia/amneziawg/`). Source and target paths are defined in `config.yml`.

#### Usage
```bash
ruby apply.rb [options]
```

#### Available Options
* `-p, --period <value>` — Specifies the cutoff period for filtering files.
  * **Integer** (e.g., `0`, `3`) — Applies files modified within the last N days.
  * `all` — Applies all available configuration files regardless of their age.
  * *Default value:* `0` (applies today's files only).
* `-h, --help` — Prints the helper banner and tool usage instructions.

#### Examples
```bash
# Apply only today's configurations (default)
ruby apply.rb

# Apply configurations added/modified in the last 3 days
ruby apply.rb -p 3

# Apply all configuration files from the source directory
ruby apply.rb -p all

# Show full help information
ruby apply.rb -h
```


### VPN Configuration Lister (`list.rb`)

Scans your system target directory and displays all available VPN configurations in clean, vertically-aligned columns without the `.conf` extension.

#### Usage
```bash
ruby list.rb [options]
```

#### Available Options
* `-n, --name` — Sorts configurations alphabetically by name in 3 columns. This is the default behavior.
* `-t, --time` — Sorts configurations by modification date, placing the newest files at the top (3 columns).
* `-d, --details` — Sorts configurations by modification date and appends a clean, right-aligned timestamp (`YYYY-MM-DD HH:MM`) next to each name. Automatically switches the layout to 2 columns for optimal readability.
* `-h, --help` — Prints the helper banner and tool usage instructions.

#### Examples
```bash
# List all configurations alphabetically in 3 vertical columns (default)
ruby list.rb

# List configurations by date, freshest first (3 columns)
ruby list.rb -t

# List configurations with dates aligned cleanly to the right (2 columns)
ruby list.rb -d

# Show help information
ruby list.rb -h
```


### VPN Connection Manager (`vpn_run.rb`)

Manages your AmneziaWG/WireGuard connections using configuration files from the system target directory. It handles stopping previous connections, dynamic configuration resolution, interface diagnostics, and automatically requests `sudo` privileges if launched by a regular user.

#### Usage
```bash
ruby vpn_run.rb [options] [config_name]
```

#### Arguments
* `[config_name]` — **Optional**. The name of a specific VPN configuration file (without the `.conf` extension) to start. If omitted, the script automatically detects and starts the **latest (most recently modified)** configuration file in the directory.

#### Available Options
* `-s, --stop` — Stops all currently active systemd units matching your project's VPN service prefix, resetting all connections.
* `-h, --help` — Prints the helper banner and tool usage instructions.

#### Examples
```bash
# Start the most recent configuration file (auto-escalates to sudo if needed)
ruby vpn_run.rb

# Start a specific configuration interface explicitly
ruby vpn_run.rb wg2_net_ams_H16

# Stop all active VPN connections and clean up routing tables
ruby vpn_run.rb -s

# Show help information
ruby vpn_run.rb -h
```


### VPN Traffic Inspector (`vpn_check.rb`)

Verifies the active VPN status and tests real data flow through the tunnel using an isolated ping check. It bypasses TSPU/ISP interference by forcing traffic strictly through the active interface.

#### Usage
```bash
ruby vpn_check.rb [options]
```

#### Exit Codes
The script returns system codes instantly, allowing scripts or status bars to monitor connection health:
* `0` — **Success**: Service is active, the interface is parsed correctly, and traffic flows successfully.
* `1` — **Error**: The service is down, the interface is missing, or traffic is blocked by TSPU/ISP filters.

#### Available Options
* `-v, --verbose` — Prints a complete diagnostic summary map (systemd state, interface name, fallback host, ping validation) using an optimized single-pass check.
* `-h, --help` — Prints the helper banner and tool usage instructions.

#### Examples
```bash
# Quietly check the connection (returns exit code 0 or 1, prints a single result line)
ruby vpn_check.rb

# Run an extended live diagnostic breakdown when troubleshooting connection drops
ruby vpn_check.rb -v

# Show help information
ruby vpn_check.rb -h
```


### VPN Configuration Sequential Pinger (`ping_all.rb`)

Sequentially tests all available VPN configurations by temporarily bringing up each tunnel and verifying the real data flow. It automatically suppresses underlying systemd output, tracks results interactively, and safely restores your initial network state upon completion.

#### Usage
```bash
# Sequentially test all configurations (automatically requests sudo privileges)
ruby ping_all.rb
```


## Testing Suite

The project includes an isolated integration testing infrastructure running inside the Bundler environment to spawn real CLI subprocesses.

### Running with Rake (Recommended)
Integration tasks are managed via `Rake` alongside `minitest-rg` to provide clean visual test evaluations.

```bash
# Run the integration test suite
bundle exec rake test
```

<!--
---

## Related project

You can also use [awg-switch](https://github.com/dneverov/awg-switch) (Shell) to start or switch the AmneziaWG configuration.
-->

<!--
## TODO

- [x] Add shareable lib
- [x] Gemfile (if needed)
- [x] Minitest
- [x] Add `CopierTest`
- [x] Read from config file (+ add config.example)
- [x] Process files from `Dir`
- [x] Fix `FileCopier.sync!` log output
- [x] Ref: Add methods for validations from `FileCopierTest`
- [x] Update `FileCopierTest` for `FileCopier.sync!` with period
- [x] Add an utility for selecting VPN
- [ ] Ref: Update `Copier` to work with instances (Low Priority)
-->
