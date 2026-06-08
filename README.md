# wg_conf

Copies Amnezia WG configuration files.

## How To Use:

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
### Test:

```sh
ruby test/units/namer_test.rb
```

Or individual test:
```shell
ruby test/units/namer_test.rb -n test_country_not_in_mapping
```

## TODO

- [x] Add shareable lib
- [ ] Gemfile
- [x] Minitest
- [ ] Add CopierTest
- [x] Read from config file (+ add config.example)
- [ ] Process files from `Dir`
