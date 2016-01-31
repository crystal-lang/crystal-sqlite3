require "./spec_helper"

def with_db(&block : DB::Database ->)
  DB.open "sqlite3", {"database": DB_FILENAME}, &block
ensure
  File.delete(DB_FILENAME)
end

def with_mem_db(&block : DB::Database ->)
  DB.open "sqlite3", {"database": ":memory:"}, &block
end

def sql(s : String)
  "#{s.inspect}"
end

def sql(s)
  "#{s}"
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

describe Driver do
  it "should register sqlite3 name" do
    DB.driver_class("sqlite3").should eq(SQLite3::Driver)
  end

  it "should use database option as file to open" do
    with_db do |db|
      db.driver_class.should eq(SQLite3::Driver)
      File.exists?(DB_FILENAME).should be_true
    end
  end

  {% for value in [1, 1_i64, "hello", 1.5, 1.5_f32] %}
    it "executes and select {{value.id}}" do
      with_db do |db|
        db.scalar(typeof({{value}}), "select #{sql({{value}})}").should eq({{value}})

        db.query "select #{sql({{value}})}" do |rs|
          assert_single_read rs, typeof({{value}}), {{value}}
        end
      end
    end

    it "executes and select {{value.id}} as nillable" do
      with_db do |db|
        db.scalar?(typeof({{value}}), "select #{sql({{value}})}").should eq({{value}})

        db.query "select #{sql({{value}})}" do |rs|
          assert_single_read? rs, typeof({{value}}), {{value}}
        end
      end
    end

    it "executes and select nil as type of {{value.id}}" do
      with_db do |db|
        db.scalar?(typeof({{value}}), "select null").should be_nil

        db.query "select null" do |rs|
          assert_single_read? rs, typeof({{value}}), nil
        end
      end
    end

    it "executes with bind {{value.id}}" do
      with_db do |db|
        db.scalar(typeof({{value}}), %(select ?), {{value}}).should eq({{value}})
      end
    end

    it "executes with bind {{value.id}} read as nillable" do
      with_db do |db|
        db.scalar?(typeof({{value}}), %(select ?), {{value}}).should eq({{value}})
      end
    end

    it "executes with bind nil as typeof {{value.id}}" do
      with_db do |db|
        db.scalar?(typeof({{value}}), %(select ?), nil).should be_nil
      end
    end

    it "executes with bind {{value.id}} as array" do
      with_db do |db|
        db.scalar?(typeof({{value}}), %(select ?), [{{value}}]).should eq({{value}})
      end
    end
  {% end %}

  it "executes and selects blob" do
    with_db do |db|
      slice = db.scalar(Slice(UInt8), %(select X'53514C697465'))
      slice.to_a.should eq([0x53, 0x51, 0x4C, 0x69, 0x74, 0x65])
    end
  end

  it "executes with bind blob" do
    with_db do |db|
      ary = UInt8[0x53, 0x51, 0x4C, 0x69, 0x74, 0x65]
      slice = db.scalar Slice(UInt8), %(select cast(? as BLOB)), Slice.new(ary.to_unsafe, ary.size)
      slice.to_a.should eq(ary)
    end
  end

  it "executes with named bind using symbol" do
    with_db do |db|
      db.scalar(String, %(select :value), {value: "hello"}).should eq("hello")
    end
  end

  it "executes with named bind using string" do
    with_db do |db|
      db.scalar(String, %(select :value), {"value": "hello"}).should eq("hello")
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

  # TODO get other value types from table
  # TODO get many rows from table
  # TODO get_last_row_id
  # TODO gets column types
  # TODO migrate quotes to std

  it "gets values from table" do
    with_mem_db do |db|
      db.exec "create table person (name string, age integer)"
      db.exec %(insert into person values ("foo", 10))

      db.query "select * from person" do |rs|
        rs.move_next.should be_true
        rs.read(String).should eq("foo")
        rs.read(Int32).should eq(10)
        rs.move_next.should be_false
      end
    end
  end

  it "ensures statements are closed" do
    begin
      DB.open "sqlite3", {"database": DB_FILENAME} do |db|
        db.exec %(create table if not exists a (i int not null, str text not null);)
        db.exec %(insert into a (i, str) values (23, "bai bai");)
      end

      2.times do |i|
        DB.open "sqlite3", {"database": DB_FILENAME} do |db|
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
