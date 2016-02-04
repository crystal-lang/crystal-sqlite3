class SQLite3::Driver < DB::Driver
  def build_connection(db)
    SQLite3::Connection.new(db)
  end
end

DB.register_driver "sqlite3", SQLite3::Driver
