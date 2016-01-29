class SQLite3::Statement2 < DB::Statement
  def initialize(@driver, sql)
    check LibSQLite3.prepare_v2(@driver, sql, sql.bytesize + 1, out @stmt, nil)
    # @closed = false
  end

  def exec(*args)
    LibSQLite3.reset(self)
    ResultSet2.new(self)
  end

  private def check(code)
    raise Exception.new(@driver) unless code == 0
  end

  def to_unsafe
    @stmt
  end
end
