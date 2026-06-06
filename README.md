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

## TODO

- [x] Add shareable lib
- [ ] Gemfile
- [ ] Minitest
- [ ] Read from config file (+ add config.example)
- [ ] Process files from `Dir`
