require "./spec_helper"

def assert_filename(uri, filename)
  SQLite3::Connection.filename(URI.parse(uri)).should eq(filename)
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

    {% if compare_versions(Crystal::VERSION, "0.28.0") >= 0 %}
      # Before 0.28.0 the filename had the query string in this case
      # but it didn't bother when deleting the file in pool_spec.cr.
      # After 0.28.0 the behavior is changed, but can't be fixed prior that
      # due to the use of URI#opaque.
      assert_filename("sqlite3:./file.db?max_pool_size=5", "./file.db")
    {% end %}
    assert_filename("sqlite3:/path/to/file.db?max_pool_size=5", "/path/to/file.db")
    assert_filename("sqlite3://./file.db?max_pool_size=5", "./file.db")
    assert_filename("sqlite3:///path/to/file.db?max_pool_size=5", "/path/to/file.db")
  end

  it "should use database option as file to open" do
    with_db do |db|
      db.driver.should be_a(SQLite3::Driver)
      File.exists?(DB_FILENAME).should be_true
    end
  end
end
