# wg_conf

Copies Amnezia WG configuration files.

## FYI

For start or switch Amnezia WG config you can use [awg-switch](https://github.com/dneverov/awg-switch).

## How To Use

### `copy.rb`

Copies a single config file.

```bash
ruby copy.rb ConfigFileName.conf
# OR
ruby copy.rb ConfigFileName.conf NewFileName.conf
```

E.g.
```sh
ruby copy.rb SerbiaBelgradeS3.conf wg2_ser_bel_S3.conf
```

### `dir.rb`

Copies config files from a `source_dir` into a `target_dir`. (Directories are defined in the _config.yml_ file).

```bash
# By default copies today's files (same as `ruby dir.rb -p 0`)
ruby dir.rb
# OR files added in the last 3 days
ruby dir.rb -p 3
# OR all files
ruby dir.rb -p all
```

Type key `-h` for help:
```sh
ruby dir.rb -h
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
# To stop services:
ruby vpn_run.rb -s
```

Type key `-h` for help:
```sh
ruby vpn_run.rb -h
```

## Test

```sh
# Singe file
ruby test/units/namer_test.rb
# Or individual test
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
