require "./spec_helper"

def sql(s : String)
  "#{s.inspect}"
end

def sql(s)
  "#{s}"
end

def sqlite_type_for(v)
  case v
  when String          ; "text"
  when Int32, Int64    ; "int"
  when Float32, Float64; "float"
  when Time            ; "text"
  else
    raise "not implemented for #{typeof(v)}"
  end
end

def assert_single_read(rs, value_type, value)
  rs.move_next.should be_true
  rs.read(value_type).should eq(value)
  rs.move_next.should be_false
end

def assert_single_read?(rs, value_type, value)
  rs.move_next.should be_true
  rs.read?(value_type).should eq(value)
  rs.move_next.should be_false
end

def assert_filename(uri, filename)
  SQLite3::Connection.filename(URI.parse(uri)).should eq(filename)
end

class NotSupportedType
end

describe Driver do
  it "should register sqlite3 name" do
    DB.driver_class("sqlite3").should eq(SQLite3::Driver)
  end

  it "should get filename from uri" do
    assert_filename("sqlite3:%3Amemory%3A", ":memory:")
    assert_filename("sqlite3://%3Amemory%3A", ":memory:")

    assert_filename("sqlite3:./file.db", "./file.db")
    assert_filename("sqlite3://./file.db", "./file.db")

    assert_filename("sqlite3:/path/to/file.db", "/path/to/file.db")
    assert_filename("sqlite3:///path/to/file.db", "/path/to/file.db")
  end

  it "should use database option as file to open" do
    with_db do |db|
      db.driver.should be_a(SQLite3::Driver)
      File.exists?(DB_FILENAME).should be_true
    end
  end

  {% for value in [1, 1_i64, "hello", 1.5, 1.5_f32] %}
    it "executes and select {{value.id}}" do
      with_db do |db|
        db.scalar("select #{sql({{value}})}").should eq({{value}})

        db.query "select #{sql({{value}})}" do |rs|
          assert_single_read rs, typeof({{value}}), {{value}}
        end
      end
    end

    it "executes and select nil as type of {{value.id}}" do
      with_db do |db|
        db.scalar("select null").should be_nil

        db.query "select null" do |rs|
          assert_single_read? rs, typeof({{value}}), nil
        end
      end
    end

    it "executes with bind {{value.id}}" do
      with_db do |db|
        db.scalar(%(select ?), {{value}}).should eq({{value}})
      end
    end

    it "executes with bind nil as typeof {{value.id}}" do
      with_db do |db|
        db.scalar("select ?", nil).should be_nil
      end
    end

    it "executes with bind {{value.id}} as array" do
      with_db do |db|
        db.scalar(%(select ?), [{{value}}]).should eq({{value}})
      end
    end
  {% end %}

  it "executes and selects blob" do
    with_db do |db|
      slice = db.scalar(%(select X'53514C697465')).as(Bytes)
      slice.to_a.should eq([0x53, 0x51, 0x4C, 0x69, 0x74, 0x65])
    end
  end

  it "executes with bind blob" do
    with_db do |db|
      ary = UInt8[0x53, 0x51, 0x4C, 0x69, 0x74, 0x65]
      slice = db.scalar(%(select cast(? as BLOB)), Bytes.new(ary.to_unsafe, ary.size)).as(Bytes)
      slice.to_a.should eq(ary)
    end
  end

  it "gets column count" do
    with_mem_db do |db|
      db.exec "create table person (name string, age integer)"

      db.query "select * from person" do |rs|
        rs.column_count.should eq(2)
      end
    end
  end

  it "gets column name" do
    with_mem_db do |db|
      db.exec "create table person (name string, age integer)"

      db.query "select * from person" do |rs|
        rs.column_name(0).should eq("name")
        rs.column_name(1).should eq("age")
      end
    end
  end

  it "gets column types" do
    with_mem_db do |db|
      db.exec "create table table1 (aText text, anInteger integer, aReal real, aBlob blob)"
      db.exec "insert into table1 (aText, anInteger, aReal, aBlob) values ('a', 1, 1.5, X'53')"

      # sqlite is unable to get column_type information
      # from the query itself without executing and getting
      # actual data.
      db.query "select * from table1" do |rs|
        rs.move_next
        rs.column_type(0).should eq(String)
        rs.column_type(1).should eq(Int64)
        rs.column_type(2).should eq(Float64)
        rs.column_type(3).should eq(Bytes)
      end
    end
  end

  it "gets last insert row id" do
    with_mem_db do |db|
      db.exec "create table person (name string, age integer)"

      db.exec %(insert into person values ("foo", 10))

      res = db.exec %(insert into person values ("foo", 10))
      res.last_insert_id.should eq(2)
      res.rows_affected.should eq(1)
    end
  end

  {% for value in [1, 1_i64, "hello", 1.5, 1.5_f32] %}
    it "insert/get value {{value.id}} from table" do
      with_db do |db|
        db.exec "create table table1 (col1 #{sqlite_type_for({{value}})})"
        db.exec %(insert into table1 values (#{sql({{value}})}))
        db.scalar("select col1 from table1").should eq({{value}})
      end
    end
  {% end %}

  it "insert/get blob value from table" do
    with_db do |db|
      ary = UInt8[0x53, 0x51, 0x4C, 0x69, 0x74, 0x65]

      db.exec "create table table1 (col1 blob)"
      db.exec %(insert into table1 values (?)), Bytes.new(ary.to_unsafe, ary.size)

      slice = db.scalar("select cast(col1 as blob) from table1").as(Bytes)
      slice.to_a.should eq(ary)
    end
  end

  it "insert/get value date from table" do
    with_db do |db|
      value = Time.new(2016, 7, 22, 15, 0, 0, 0)
      db.exec "create table table1 (col1 #{sqlite_type_for(value)})"
      db.exec %(insert into table1 values (?)), value

      db.query "select col1 from table1" do |rs|
        rs.move_next
        rs.read(Time).should eq(value)
      end

      db.query "select col1 from table1" do |rs|
        rs.move_next
        rs.read?(Time).should eq(value)
      end
    end
  end

  it "raises on unsupported param types" do
    with_db do |db|
      expect_raises Exception, "SQLite3::Statement does not support NotSupportedType params" do
        db.query "select 1", NotSupportedType.new
      end
      # TODO raising exception does not close the connection and pool is exhausted
    end

    with_db do |db|
      expect_raises Exception, "SQLite3::Statement does not support NotSupportedType params" do
        db.exec "select 1", NotSupportedType.new
      end
    end
  end

  it "gets many rows from table" do
    with_mem_db do |db|
      db.exec "create table person (name string, age integer)"
      db.exec %(insert into person values ("foo", 10))
      db.exec %(insert into person values ("bar", 20))
      db.exec %(insert into person values ("baz", 30))

      names = [] of String
      ages = [] of Int32
      db.query "select * from person" do |rs|
        rs.each do
          names << rs.read(String)
          ages << rs.read(Int32)
        end
      end
      names.should eq(["foo", "bar", "baz"])
      ages.should eq([10, 20, 30])
    end
  end

  it "ensures statements are closed" do
    begin
      DB.open "sqlite3:#{DB_FILENAME}" do |db|
        db.exec %(create table if not exists a (i int not null, str text not null);)
        db.exec %(insert into a (i, str) values (23, "bai bai");)
      end

      2.times do |i|
        DB.open "sqlite3:#{DB_FILENAME}" do |db|
          begin
            db.query("SELECT i, str FROM a WHERE i = ?", 23) do |rs|
              rs.move_next
              break
            end
          rescue e : SQLite3::Exception
            fail("Expected no exception, but got \"#{e.message}\"")
          end

          begin
            db.exec("UPDATE a SET i = ? WHERE i = ?", 23, 23)
          rescue e : SQLite3::Exception
            fail("Expected no exception, but got \"#{e.message}\"")
          end
        end
      end
    ensure
      File.delete(DB_FILENAME)
    end
  end
end
