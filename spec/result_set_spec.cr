require "./spec_helper"

describe SQLite3::ResultSet do
  it "reads integer data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_int integer)"
      db.exec "INSERT INTO test_table (test_int) values (?)", 42
      db.query("SELECT test_int FROM test_table") do |rs|
        rs.each do
          rs.read.should eq(42)
        end
      end
    end
  end

  it "reads string data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_text text)"
      db.exec "INSERT INTO test_table (test_text) values (?), (?)", "abc", "123"
      db.query("SELECT test_text FROM test_table") do |rs|
        rs.each do
          rs.read.should match(/abc|123/)
        end
      end
    end
  end

  it "reads time data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_date datetime)"
      timestamp = Time.utc
      db.exec "INSERT INTO test_table (test_date) values (current_timestamp)"
      db.query("SELECT test_date FROM test_table") do |rs|
        rs.each do
          rs.read(Time).should be_close(timestamp, 1.second)
        end
      end
    end
  end

  it "reads time stored in text fields, too" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_date text)"
      timestamp = Time.utc
      # Try 3 different ways: our own two formats and using SQLite's current_timestamp.
      # They should all work.
      db.exec "INSERT INTO test_table (test_date) values (?)", timestamp.to_s SQLite3::DATE_FORMAT_SUBSECOND
      db.exec "INSERT INTO test_table (test_date) values (?)", timestamp.to_s SQLite3::DATE_FORMAT_SECOND
      db.exec "INSERT INTO test_table (test_date) values (current_timestamp)"
      db.query("SELECT test_date FROM test_table") do |rs|
        rs.each do
          rs.read(Time).should be_close(timestamp, 1.second)
        end
      end
    end
  end
end
