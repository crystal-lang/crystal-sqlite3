require "./spec_helper"

describe SQLite3::ResultSet do
  it "reads integer data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table(test_int integer);"
      db.exec "INSERT INTO test_table(test_int) values(?);", 42
      db.query("SELECT test_int FROM test_table") do |rs|
        rs.each do
          rs.read.should be_a(Int64)
        end
      end
    end
  end

  it "reads string data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table(test_text text);"
      db.exec "INSERT INTO test_table(test_text) VALUES (?), (?)", "abc", "123"
      db.query("SELECT test_text FROM test_table") do |rs|
        rs.each do
          r = rs.read
          r.should be_a(String)
          r.should match(/abc|123/)
        end
      end
    end
  end

  it "reads time data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table(test_date datetime);"
      db.exec "INSERT INTO test_table(test_date) values(current_timestamp);"
      db.query("SELECT test_date FROM test_table") do |rs|
        rs.each do
          rs.read(Time).should be_a(Time)
        end
      end
    end
  end

  it "reads time stored in text fields, too" do
    with_db do |db|
      db.exec "CREATE TABLE test_table(test_date text);"
      db.exec "INSERT INTO test_table(test_date) values(current_timestamp);"
      db.query("SELECT test_date FROM test_table") do |rs|
        rs.each do
          rs.read(Time).should be_a(Time)
        end
      end
    end
  end
end
