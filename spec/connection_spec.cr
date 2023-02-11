require "./spec_helper"

private def dump(source, target)
  source.using_connection do |conn|
    conn = conn.as(SQLite3::Connection)
    target.using_connection do |backup_conn|
      backup_conn = backup_conn.as(SQLite3::Connection)
      conn.dump(backup_conn)
    end
  end
end

private def it_sets_pragma_on_connection(pragma : String, value : String, expected, file = __FILE__, line = __LINE__)
  it "sets pragma '#{pragma}' to #{expected}", file, line do
    with_db("#{DB_FILENAME}?#{pragma}=#{value}") do |db|
      db.scalar("PRAGMA #{pragma}").should eq(expected)
    end
  end
end

describe Connection do
  it "opens a database and then backs it up to another db" do
    with_db do |db|
      with_db("./test2.db") do |backup_db|
        db.exec "create table person (name text, age integer)"
        db.exec "insert into person values (\"foo\", 10)"

        dump db, backup_db

        backup_name = backup_db.scalar "select name from person"
        backup_age = backup_db.scalar "select age from person"
        source_name = db.scalar "select name from person"
        source_age = db.scalar "select age from person"

        {backup_name, backup_age}.should eq({source_name, source_age})
      end
    end
  end

  it "opens a database, inserts records, dumps to an in-memory db, insers some more, then dumps to the source" do
    with_db do |db|
      with_mem_db do |in_memory_db|
        db.exec "create table person (name text, age integer)"
        db.exec "insert into person values (\"foo\", 10)"
        dump db, in_memory_db

        in_memory_db.scalar("select count(*) from person").should eq(1)
        in_memory_db.exec "insert into person values (\"bar\", 22)"
        dump in_memory_db, db

        db.scalar("select count(*) from person").should eq(2)
      end
    end
  end

  it "opens a database, inserts records (>1024K), and dumps to an in-memory db" do
    with_db do |db|
      with_mem_db do |in_memory_db|
        db.exec "create table person (name text, age integer)"
        db.transaction do |tx|
          100_000.times { tx.connection.exec "insert into person values (\"foo\", 10)" }
        end
        dump db, in_memory_db
        in_memory_db.scalar("select count(*) from person").should eq(100_000)
      end
    end
  end

  it "opens a connection without the pool" do
    with_cnn do |cnn|
      cnn.should be_a(SQLite3::Connection)

      cnn.exec "create table person (name text, age integer)"
      cnn.exec "insert into person values (\"foo\", 10)"

      cnn.scalar("select count(*) from person").should eq(1)
    end
  end

  # adjust busy_timeout pragma (default is 0)
  it_sets_pragma_on_connection "busy_timeout", "1000", 1000

  # adjust cache_size pragma (default is -2000, 2MB)
  it_sets_pragma_on_connection "cache_size", "-4000", -4000

  # enable foreign_keys, no need to test off (is the default)
  it_sets_pragma_on_connection "foreign_keys", "1", 1
  it_sets_pragma_on_connection "foreign_keys", "yes", 1
  it_sets_pragma_on_connection "foreign_keys", "true", 1
  it_sets_pragma_on_connection "foreign_keys", "on", 1

  # change journal_mode (default is delete)
  it_sets_pragma_on_connection "journal_mode", "delete", "delete"
  it_sets_pragma_on_connection "journal_mode", "truncate", "truncate"
  it_sets_pragma_on_connection "journal_mode", "persist", "persist"

  # change synchronous mode (default is 2, FULL)
  it_sets_pragma_on_connection "synchronous", "0", 0
  it_sets_pragma_on_connection "synchronous", "off", 0
  it_sets_pragma_on_connection "synchronous", "1", 1
  it_sets_pragma_on_connection "synchronous", "normal", 1
  it_sets_pragma_on_connection "synchronous", "2", 2
  it_sets_pragma_on_connection "synchronous", "full", 2
  it_sets_pragma_on_connection "synchronous", "3", 3
  it_sets_pragma_on_connection "synchronous", "extra", 3

  # change wal_autocheckpoint (default is 1000)
  it_sets_pragma_on_connection "wal_autocheckpoint", "0", 0
end
