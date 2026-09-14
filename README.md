# 🛠️ wg_conf

A lightweight and robust CLI automation toolset for managing AmneziaWG and WireGuard configuration files. It handles structured copying, renaming, sorting, listing, and network traffic status checking.

---

## 🚀 How To Use

### 📄 Single File Copier (`copy.rb`)

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


### 📂 Configuration Copier (`dir.rb`)

Copies downloaded VPN configuration files from your local directory into the system target folder (e.g., `/etc/amnezia/amneziawg/`). Source and target paths are defined in `config.yml`.

#### Usage
```bash
ruby dir.rb [options]
```

#### Available Options
* `-p, --period <value>` — Specifies the cutoff period for copying files.
  * **Integer** (e.g., `0`, `3`) — Copies files modified within the last N days.
  * `all` — Copies all available configuration files regardless of their age.
  * *Default value:* `0` (copies today's files only).
* `-h, --help` — Prints the helper banner and tool usage instructions.

#### Examples
```bash
# Copy only today's configurations (default)
ruby dir.rb

# Copy configurations added/modified in the last 3 days
ruby dir.rb -p 3

# Copy all configuration files from the source directory
ruby dir.rb -p all

# Show full help information
ruby dir.rb -h
```


### `list.rb`

Shows available VPN configurations.

```sh
# Sort by name (default)
ruby list.rb
# OR
ruby list.rb -n
# Sort by date (newest first)
ruby list.rb -t
# Sort by date and display compact time (2 columns)
ruby list.rb -d
```

### `vpn_run.rb`

Starts AmneziaWG VPN using configs from a target directory.

```bash
# By default starts the latest (most recent) config
sudo ruby vpn_run.rb
# OR without sudo (it will re-run with sudo)
ruby vpn_run.rb
# OR
ruby vpn_run.rb wg2_net_ams_H16
# To STOP services:
ruby vpn_run.rb -s
```

Type key `-h` for help:
```sh
ruby vpn_run.rb -h
```

### `vpn_check.rb`

Checks the VPN connection.

```sh
ruby vpn_check.rb
# To show detailed info (keys: -v, --verbose)
ruby vpn_check.rb -v
```

## Test

```sh
# Singe file
ruby test/units/namer_test.rb
# OR individual test
ruby test/units/namer_test.rb -n test_country_not_in_mapping
```

### Using Rake
<!--
- `rake` или `rake test` — запустит вообще все тесты (и юниты, и интеграционные)
- `rake test:units` — запустит тесты только из папки `test/units/`
- `rake test:integration` — запустит тесты только из папки `test/integration/`.
-->

```sh
# Run all tests
rake test
# OR
rake
# Run tests only from the `test/units/` directory
rake test:units
# Run tests only from the `test/integration/`
rake test:integration
```

## Related project

You can also use [awg-switch](https://github.com/dneverov/awg-switch) to start or switch the Amnezia WG configuration.

## TODO

- [x] Add shareable lib
- [ ] Gemfile (if needed)
- [x] Minitest
- [x] Add `CopierTest`
- [x] Read from config file (+ add config.example)
- [x] Process files from `Dir`
- [x] Fix `FileCopier.sync!` log output
- [x] Ref: Add methods for validations from `FileCopierTest`
- [x] Update `FileCopierTest` for `FileCopier.sync!` with period
- [x] Add an utility for selecting VPN
- [ ] Ref: Update `Copier` to work with instances (Low Priority)
