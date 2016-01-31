class SQLite3::Driver < DB::Driver
  def build_connection
    SQLite3::Connection.new(options)
  end

  # Quotes the given string, making it safe to use in an SQL statement.
  # It replaces all instances of the single-quote character with two single-quote characters.
  def self.quote(string)
    string.gsub('\'', "''")
  end
end

DB.register_driver "sqlite3", SQLite3::Driver
