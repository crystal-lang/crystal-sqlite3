class SQLite3::Driver < DB::Driver
  def initialize(options)
    super
    filename = options["database"]
    check LibSQLite3.open_v2(filename, out @db, (LibSQLite3::Flag::READWRITE | LibSQLite3::Flag::CREATE), nil)
    # @closed = false
  end

  def prepare(query)
    Statement2.new(self, query)
  end

  def to_unsafe
    @db
  end

  private def check(code)
    raise Exception.new(@db) unless code == 0
  end
end

DB.register_driver "sqlite3", SQLite3::Driver
