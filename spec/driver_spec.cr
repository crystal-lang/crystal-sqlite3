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
        result_set.move_next.should be_true
        result_set.read(typeof({{value}})).should eq({{value}})
        result_set.move_next.should be_false
      end
    end

    it "executes and select {{value.id}} as nillable" do
      with_db do |db|
        result_set = db.exec("select #{sql({{value}})}")
        result_set.move_next.should be_true
        result_set.read?(typeof({{value}})).should eq({{value}})
        result_set.move_next.should be_false
      end
    end

    it "executes and select nil as type of {{value.id}}" do
      with_db do |db|
        result_set = db.exec("select null")
        result_set.move_next.should be_true
        result_set.read?(typeof({{value}})).should be_nil
        result_set.move_next.should be_false
      end
    end

  # it "executes with bind #{value}" do
  #   with_db(&.execute(%(select ?), value)).should eq([[value]])
  # end

  # it "executes with bind #{value} as array" do
  #   with_db(&.execute(%(select ?), [value])).should eq([[value]])
  # end
  {% end %}
end
