require "./spec_helper"

def with_db
  yield DB.open "sqlite3", {"database": DB_FILENAME}
ensure
  File.delete(DB_FILENAME)
end

def sql(s : String)
  "#{s.inspect}"
end

def sql(s)
  "#{s}"
end

def assert_single_read(result_set, value_type, value)
  result_set.move_next.should be_true
  result_set.read(value_type).should eq(value)
  result_set.move_next.should be_false
end

def assert_single_read?(result_set, value_type, value)
  result_set.move_next.should be_true
  result_set.read?(value_type).should eq(value)
  result_set.move_next.should be_false
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
        result_set = db.exec("select #{sql({{value}})}")
        assert_single_read result_set, typeof({{value}}), {{value}}
      end
    end

    it "executes and select {{value.id}} as nillable" do
      with_db do |db|
        result_set = db.exec("select #{sql({{value}})}")
        assert_single_read? result_set, typeof({{value}}), {{value}}
      end
    end

    it "executes and select nil as type of {{value.id}}" do
      with_db do |db|
        result_set = db.exec("select null")
        assert_single_read? result_set, typeof({{value}}), nil
      end
    end

    it "executes with bind {{value.id}}" do
      with_db do |db|
        result_set = db.exec(%(select ?), {{value}})
        assert_single_read result_set, typeof({{value}}), {{value}}
      end
    end

    it "executes with bind {{value.id}} read as nillable" do
      with_db do |db|
        result_set = db.exec(%(select ?), {{value}})
        assert_single_read? result_set, typeof({{value}}), {{value}}
      end
    end

    it "executes with bind nil as typeof {{value.id}}" do
      with_db do |db|
        result_set = db.exec(%(select ?), nil)
        assert_single_read? result_set, typeof({{value}}), nil
      end
    end

    it "executes with bind {{value.id}} as array" do
      with_db do |db|
        result_set = db.exec(%(select ?), [{{value}}])
        assert_single_read result_set, typeof({{value}}), {{value}}
      end
    end
  {% end %}

  it "executes and selects blob" do
    with_db do |db|
      result_set = db.exec %(select X'53514C697465')
      result_set.move_next
      result_set.read(Slice(UInt8)).to_a.should eq([0x53, 0x51, 0x4C, 0x69, 0x74, 0x65])
    end
  end

  it "executes with bind blob" do
    with_db do |db|
      ary = UInt8[0x53, 0x51, 0x4C, 0x69, 0x74, 0x65]
      result_set = db.exec %(select cast(? as BLOB)), Slice.new(ary.to_unsafe, ary.size)
      result_set.move_next
      result_set.read(Slice(UInt8)).to_a.should eq(ary)
    end
  end

  it "executes with named bind using symbol" do
    with_db do |db|
      result_set = db.exec(%(select :value), {value: "hello"})
      assert_single_read result_set, String, "hello"
    end
  end

  it "executes with named bind using string" do
    with_db do |db|
      result_set = db.exec(%(select :value), {"value": "hello"})
      assert_single_read result_set, String, "hello"
    end
  end
end
