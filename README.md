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

## TODO

- [x] Add shareable lib
- [ ] Gemfile (if needed)
- [x] Minitest
- [x] Add `CopierTest`
- [x] Read from config file (+ add config.example)
- [x] Process files from `Dir`
- [x] Fix `FileCopier.sync!` log output
- [ ] Ref: Add methods for validations from `FileCopierTest`
- [x] Update `FileCopierTest` for `FileCopier.sync!` with period
- [ ] Add an utility for selecting VPN
