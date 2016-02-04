class SQLite3::Connection < DB::Connection
  def initialize(database)
    super
    filename = self.class.filename(database.uri)
    check LibSQLite3.open_v2(filename, out @db, (LibSQLite3::Flag::READWRITE | LibSQLite3::Flag::CREATE), nil)
  end

  def self.filename(uri : URI)
    URI.unescape (if path = uri.path
      (uri.host || "") + path
    else
      uri.opaque.not_nil!
    end)
  end

  def build_statement(query)
    Statement2.new(self, query)
  end

  def do_close
    @statements_cache.values.each &.close
    super
    LibSQLite3.close_v2(self)
  end

  def to_unsafe
    @db
  end

  private def check(code)
    raise Exception.new(self) unless code == 0
  end
end
