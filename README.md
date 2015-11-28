# crystal-sqlite3 [![Build Status](https://travis-ci.org/manastech/crystal-sqlite3.svg?branch=master)](https://travis-ci.org/manastech/crystal-sqlite3)

SQLite3 bindings for [Crystal](http://crystal-lang.org/).

**This is a work in progress.**

[Documentation](http://manastech.github.io/crystal-sqlite3/)

### shard.yml

```yml
dependencies:
  sqlite3:
    github: manastech/crystal-sqlite3
```

### Usage

```crystal
require "sqlite3"

db = SQLite3::Database.new( "data.db" )
db.execute("select * from table") do |row|
  p row
end
db.close
```
