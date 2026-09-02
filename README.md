# wg_conf

Copies Amnezia WG configuration files.

## FYI

For start or switch Amnezia WG config you can use [awg-switch](https://github.com/dneverov/awg-switch).

## How To Use:

### `copy.rb` -- Single config file
```bash
ruby copy.rb ConfigFileName.conf
```

Or
```shell
ruby copy.rb ConfigFileName.conf NewFileName.conf
```

E.g.
```sh
ruby copy.rb SerbiaBelgradeS3.conf wg2_ser_bel_S3.conf
```

### `dir.rb` -- Copies config files from Dir
```bash
# By default copies today's files (same as `ruby dir.rb -p 0`)
ruby dir.rb
# OR
ruby dir.rb -p 3
# OR
ruby dir.rb -p all
```

Type key `-h` for help:
```sh
ruby dir.rb -h
```

## Test:

```sh
ruby test/units/namer_test.rb
```

Or individual test:
```shell
ruby test/units/namer_test.rb -n test_country_not_in_mapping
```

### Using Rake:
<!--
- `rake` или `rake test` — запустит вообще все тесты (и юниты, и интеграционные)
- `rake test:units` — запустит тесты только из папки `test/units/`
- `rake test:integration` — запустит тесты только из папки `test/integration/`.
-->

- `rake` or `rake test` — will run all tests (both unit and integration)
- `rake test:units` — will run tests only from the `test/units/` directory
- `rake test:integration` — will run tests only from the `test/integration/`.


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
