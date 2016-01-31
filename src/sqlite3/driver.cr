class SQLite3::Driver < DB::Driver
  def build_connection
    SQLite3::Connection.new(connection_string)
  end
end

DB.register_driver "sqlite3", SQLite3::Driver
