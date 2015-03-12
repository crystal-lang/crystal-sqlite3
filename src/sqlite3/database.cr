class SQLite3::Database
  def initialize(filename)
    code = LibSQLite3.open_v2(filename, out @db, (LibSQLite3::Flag::READWRITE | LibSQLite3::Flag::CREATE), nil)
    if code != 0
      raise Exception.new(@db)
    end
    @closed = false
  end

  def self.new(filename)
    db = new filename
    begin
      yield db
    ensure
      db.close
    end
  end

  def execute(sql, *binds)
    execute(sql, binds)
  end

  def execute(sql, *binds, &block)
    execute(sql, binds) do |row|
      yield row
    end
  end

  def execute(sql, binds : Enumerable)
    rows = [] of Array(SQLite3::ColumnType)
    execute(sql, binds) do |row|
      rows << row
    end
    rows
  end

  def execute(sql, binds : Enumerable, &block)
    query(sql, binds) do |result_set|
      while result_set.next
        yield result_set.to_a
      end
    end
  end

  def get_first_row(sql, *binds)
    get_first_row(sql, binds)
  end

  def get_first_row(sql, binds : Enumerable)
    query(sql, binds) do |result_set|
      if result_set.next
        return result_set.to_a
      else
        raise "no results"
      end
    end
  end

  def get_first_value(sql, *binds)
    get_first_value(sql, binds)
  end

  def get_first_value(sql, binds : Enumerable)
    query(sql, binds) do |result_set|
      if result_set.next
        return result_set[0]
      else
        raise "no results"
      end
    end
  end

  def query(sql, *binds)
    query(sql, binds)
  end

  def query(sql, *binds, &block)
    query(sql, binds) do |result_set|
      yield result_set
    end
  end

  def query(sql, binds : Enumerable)
    prepare(sql).execute(binds)
  end

  def query(sql, binds : Enumerable, &block)
    prepare(sql).execute(binds) do |result_set|
      yield result_set
    end
  end

  def prepare(sql)
    Statement.new(self, sql)
  end

  def last_insert_row_id
    LibSQLite3.last_insert_rowid(self)
  end

  def quote(string)
    string.gsub('\'', "''")
  end

  def closed?
    @closed
  end

  def close
    return if @closed

    @closed = true

    LibSQLite3.close_v2(@db)
  end

  def finalize
    close
  end

  def to_unsafe
    @db
  end
end
