require "./spec_helper"

lib LibSQLite3
  fun stmt_busy = sqlite3_stmt_busy(stmt : Statement) : Int32
  fun next_stmt = sqlite3_next_stmt(db : SQLite3, stmt : Statement) : Statement
end

private def active_statements(cnn : DB::Connection)
  handle = cnn.as(SQLite3::Connection).to_unsafe
  count = 0
  stmt = LibSQLite3.next_stmt(handle, Pointer(Void).null.as(LibSQLite3::Statement))
  while !stmt.null?
    count += 1 unless LibSQLite3.stmt_busy(stmt) == 0
    stmt = LibSQLite3.next_stmt(handle, stmt)
  end
  count
end

# a second handle outside crystal-db, so the refusal is a real SQLITE_BUSY
private def holding_the_write_lock(filename, &)
  handle = uninitialized LibSQLite3::SQLite3
  code = LibSQLite3.open_v2(filename, pointerof(handle), SQLite3::Flag::READWRITE, nil)
  raise SQLite3::Exception.new(handle) unless code.zero?
  begin
    LibSQLite3.exec(handle, "PRAGMA busy_timeout=0;BEGIN IMMEDIATE;", nil, nil, nil)
    yield
  ensure
    LibSQLite3.exec(handle, "COMMIT;", nil, nil, nil)
    LibSQLite3.close(handle)
  end
end

# one pooled connection, and no busy_timeout so the refusal is immediate
private def with_contended_db(&)
  filename = "./test_reset.db"
  files = ["", "-wal", "-shm"].map { |ext| "#{filename}#{ext}" }
  files.each { |f| File.delete(f) rescue nil }
  DB.open "sqlite3:#{filename}?journal_mode=wal&busy_timeout=0" \
          "&max_pool_size=1&initial_pool_size=1&checkout_timeout=2" do |db|
    db.exec "create table t (id integer primary key, v text)"
    db.exec "insert into t (id, v) values (1, 'first')"
    yield db, filename
  end
ensure
  files.try &.each { |f| File.delete(f) rescue nil }
end

private def refuse_a_write(db, filename)
  holding_the_write_lock(filename) do
    expect_raises(SQLite3::Exception) do
      db.exec "update t set v = ? where id = 1", "second"
    end
  end
end

describe "a statement whose step fails" do
  it "is not left active on the connection" do
    with_contended_db do |db, filename|
      refuse_a_write(db, filename)
      db.using_connection { |cnn| active_statements(cnn).should eq(0) }
    end
  end

  # not the refused statement's sql: re-running that would reset it by accident
  it "does not stop the next transaction committing" do
    with_contended_db do |db, filename|
      refuse_a_write(db, filename)
      db.transaction { |tx| tx.connection.exec "update t set v = 'committed' where id = 1" }
      db.scalar("select v from t where id = 1").should eq("committed")
    end
  end

  it "does not pin the connection to the snapshot it was refused on" do
    with_contended_db do |db, filename|
      DB.open "sqlite3:#{filename}?journal_mode=wal&busy_timeout=2000" do |peer|
        refuse_a_write(db, filename)
        db.scalar("select v from t where id = 1").should eq("first")

        peer.exec "update t set v = 'from the peer' where id = 1"
        db.scalar("select v from t where id = 1").should eq("from the peer")
      end
    end
  end
end
