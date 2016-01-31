class SQLite3::Connection < DB::Connection
  def initialize(options)
    super
    filename = options["database"]
    check LibSQLite3.open_v2(filename, out @db, (LibSQLite3::Flag::READWRITE | LibSQLite3::Flag::CREATE), nil)
  end

  def prepare(query)
    Statement2.new(self, query)
  end

  def perform_close
    LibSQLite3.close_v2(self)
  end

  def to_unsafe
    @db
  end

  private def check(code)
    raise Exception.new(self) unless code == 0
  end
end
