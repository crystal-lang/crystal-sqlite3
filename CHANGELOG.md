## v0.22.0 (2025-09-05)

* Add arg support for `Int16`, `Int8`, `UInt16`, `UInt8`. ([#98](https://github.com/crystal-lang/crystal-sqlite3/pull/98), [#99](https://github.com/crystal-lang/crystal-sqlite3/pull/99), thanks @baseballlover723, @bcardiff)
* Add docs on how to compile and link SQLite ([#74](https://github.com/crystal-lang/crystal-sqlite3/pull/74), thanks @chillfox)
* Update to crystal-db ~> 0.14.0. ([#102](https://github.com/crystal-lang/crystal-sqlite3/pull/102), thanks @bcardiff)
* Update formatting ([#100](https://github.com/crystal-lang/crystal-sqlite3/pull/100), thanks @straight-shoota)

## v0.21.0 (2023-12-12)

* Update to crystal-db ~> 0.13.0. ([#94](https://github.com/crystal-lang/crystal-sqlite3/pull/94))

## v0.20.0 (2023-06-23)

* Update to crystal-db ~> 0.12.0. ([#91](https://github.com/crystal-lang/crystal-sqlite3/pull/91))
* Fix result set & connection release lifecycle. ([#90](https://github.com/crystal-lang/crystal-sqlite3/pull/90))
* Automatically set PRAGMAs using connection query params. ([#85](https://github.com/crystal-lang/crystal-sqlite3/pull/85), thanks @luislavena)

## v0.19.0 (2022-01-28)

* Update to crystal-db ~> 0.11.0. ([#77](https://github.com/crystal-lang/crystal-sqlite3/pull/77))
* Fix timestamps support to allow dealing with exact seconds values ([#68](https://github.com/crystal-lang/crystal-sqlite3/pull/68), thanks @yujiri8, @tenebrousedge)
* Migrate CI to GitHub Actions. ([#78](https://github.com/crystal-lang/crystal-sqlite3/pull/78))

This release requires Crystal 1.0.0 or later.

## v0.18.0 (2021-01-26)

* Add `REGEXP` support powered by Crystal's std-lib Regex. ([#62](https://github.com/crystal-lang/crystal-sqlite3/pull/62), thanks @yujiri8)

## v0.17.0 (2020-09-30)

* Update to crystal-db ~> 0.10.0. ([#58](https://github.com/crystal-lang/crystal-sqlite3/pull/58))

This release requires Crystal 0.35.0 or later.

## v0.16.0 (2020-04-06)

* Update to crystal-db ~> 0.9.0. ([#55](https://github.com/crystal-lang/crystal-sqlite3/pull/55))

## v0.15.0 (2019-12-11)

* Update to crystal-db ~> 0.8.0. ([#50](https://github.com/crystal-lang/crystal-sqlite3/pull/50))

## v0.14.0 (2019-09-23)

* Update to crystal-db ~> 0.7.0. ([#44](https://github.com/crystal-lang/crystal-sqlite3/pull/44))

## v0.13.0 (2019-08-02)

* Fix compatibility issues for Crystal 0.30.0. ([#43](https://github.com/crystal-lang/crystal-sqlite3/pull/43))

## v0.12.0 (2019-06-07)

This release requires crystal >= 0.28.0

* Fix compatibility issues for crystal 0.29.0 ([#40](https://github.com/crystal-lang/crystal-sqlite3/pull/40))

## v0.11.0 (2019-04-18)

* Fix compatibility issues for crystal 0.28.0 ([#38](https://github.com/crystal-lang/crystal-sqlite3/pull/38))
* Add complete list of `LibSQLite3::Code` values. ([#36](https://github.com/crystal-lang/crystal-sqlite3/pull/36), thanks @t-richards)

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
