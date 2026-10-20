[![CI](https://github.com/crystal-lang/crystal-sqlite3/actions/workflows/ci.yml/badge.svg)](https://github.com/crystal-lang/crystal-sqlite3/actions/workflows/ci.yml)

# crystal-sqlite3

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

  contacts = db.query_all "SELECT name, age FROM contacts", as: {name: String, age: Int64}
  puts contacts # => [{name: "John Doe", age: 30}, {name: "Sarah", age: 33}]
end
```

### Loading extensions

`SQLite3::Connection#load_extension(path : String, entry_point : String? = nil)`
loads a native SQLite extension into that connection. It temporarily enables
the native loading API and disables it afterward, including when loading fails.
It does not enable the SQL `load_extension()` function. Only load trusted
extensions: their native code runs inside your application.

Use `db.setup_connection` to load an extension on existing and future pooled
connections. Register the callback before sharing the database with other fibers:

```crystal
require "sqlite3"

DB.open "sqlite3://./data.db" do |db|
  db.setup_connection do |connection|
    connection.as(SQLite3::Connection).load_extension("/path/to/extension")
  end

  # Queries can now use the extension on any pooled connection.
end
```

SQLite chooses the entry point when it is omitted. To specify one, use
`connection.load_extension(path, entry_point: "sqlite3_example_init")` on a
`SQLite3::Connection`. Loading failures raise `SQLite3::Exception` with the
loader's error message and result code.

Calling this method requires linking an SQLite library with extension loading
support. Builds with `SQLITE_OMIT_LOAD_EXTENSION` can omit the native loading
symbols entirely, causing a linker error even if loading is guarded by a runtime
check. Applications that do not call `load_extension` can still use these SQLite
builds. See [Compile and link SQLite](compile_and_link_sqlite.md) for using a
different SQLite library.

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

## Development

The specs compile a small native extension fixture. Running the full suite
requires a C compiler, SQLite development headers (including `sqlite3ext.h`),
and linking an SQLite library with extension loading support. On Ubuntu, install
the prerequisites with `sudo apt-get install build-essential libsqlite3-dev`.

```sh
shards install
crystal spec
```

## Guides

- [Compile and link SQLite](compile_and_link_sqlite.md)
