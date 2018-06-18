## v0.10.0 (2018-06-18)

* Fix compatibility issues for crystal 0.25.0 ([#34](https://github.com/crystal-lang/crystal-sqlite3/pull/34))
  * All the time instances are translated to UTC before saving them in the db

## v0.9.0 (2017-12-31)

* Update to crystal-db ~> 0.5.0

## v0.8.3 (2017-11-07)

* Update to crystal-db ~> 0.4.1
* Add `SQLite3::VERSION` constant with shard version.
* Add support for multi-steps statements execution. (see [#27](https://github.com/crystal-lang/crystal-sqlite3/pull/27), thanks @t-richards)
* Fix how resources are released. (see [#23](https://github.com/crystal-lang/crystal-sqlite3/pull/23), thanks @benoist)
* Fix blob c bindings. (see [#28](https://github.com/crystal-lang/crystal-sqlite3/pull/28), thanks @rufusroflpunch)

## v0.8.2 (2017-03-21)
