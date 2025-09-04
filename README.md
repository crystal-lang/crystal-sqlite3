# crystal-sqlite3 [![Build Status](https://travis-ci.org/crystal-lang/crystal-sqlite3.svg?branch=master)](https://travis-ci.org/crystal-lang/crystal-sqlite3)

SQLite3 bindings for [Crystal](http://crystal-lang.org/).

Check [crystal-db](https://github.com/crystal-lang/crystal-db) for general db driver documentation. crystal-sqlite3 driver is registered under `sqlite3://` uri.

## Installation

Add this to your application's `shard.yml`:

```yml
dependencies:
  sqlite3:
    github: crystal-lang/crystal-sqlite3
```

### Usage

```crystal
require "sqlite3"

DB.open "sqlite3://./data.db" do |db|
  db.exec "create table contacts (name text, age integer)"
  db.exec "insert into contacts values (?, ?)", "John Doe", 30

  args = [] of DB::Any
  args << "Sarah"
  args << 33
  db.exec "insert into contacts values (?, ?)", args: args

  puts "max age:"
  puts db.scalar "select max(age) from contacts" # => 33

  puts "contacts:"
  db.query "select name, age from contacts order by age desc" do |rs|
    puts "#{rs.column_name(0)} (#{rs.column_name(1)})"
    # => name (age)
    rs.each do
      puts "#{rs.read(String)} (#{rs.read(Int32)})"
      # => Sarah (33)
      # => John Doe (30)
    end
  end
end
```

### DB::Any

* `Time` is implemented as `TEXT` column using `SQLite3::DATE_FORMAT_SUBSECOND` format (or `SQLite3::DATE_FORMAT_SECOND` if the text does not contain a dot).
* `Bool` is implemented as `INT` column mapping `0`/`1` values.

### Setting PRAGMAs

You can adjust certain [SQLite3 PRAGMAs](https://www.sqlite.org/pragma.html)
automatically when the connection is created by using the query parameters:

```crystal
require "sqlite3"

DB.open "sqlite3://./data.db?journal_mode=wal&synchronous=normal" do |db|
  # this database now uses WAL journal and normal synchronous mode
  # (defaults were `delete` and `full`, respectively)
end
```

The following is the list of supported options:

| Name                      | Connection key  |
|---------------------------|-----------------|
| [Busy Timeout][pragma-to] | `busy_timeout` |
| [Cache Size][pragma-cs] | `cache_size` |
| [Foreign Keys][pragma-fk] | `foreign_keys` |
| [Journal Mode][pragma-jm] | `journal_mode` |
| [Synchronous][pragma-sync] | `synchronous` |
| [WAL autocheckoint][pragma-walck] | `wal_autocheckpoint` |

Please note there values passed using these connection keys are passed
directly to SQLite3 without check or evaluation. Using incorrect values result
in no error by the library.

[pragma-to]: https://www.sqlite.org/pragma.html#pragma_busy_timeout
[pragma-cs]: https://www.sqlite.org/pragma.html#pragma_cache_size
[pragma-fk]: https://www.sqlite.org/pragma.html#pragma_foreign_keys
[pragma-jm]: https://www.sqlite.org/pragma.html#pragma_journal_mode
[pragma-sync]: https://www.sqlite.org/pragma.html#pragma_synchronous
[pragma-walck]: https://www.sqlite.org/pragma.html#pragma_wal_autocheckpoint

## Guides

- [Compile and link SQLite](compile_and_link_sqlite.md)
