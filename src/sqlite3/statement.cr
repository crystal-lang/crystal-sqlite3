class SQLite3::Statement
  def initialize(@db, sql)
    check LibSQLite3.prepare_v2(@db, sql, sql.bytesize + 1, out @stmt, nil)
    @closed = false
  end

  def self.new(db, sql)
    statement = new db, sql
    begin
      yield statement
    ensure
      statement.close
    end
  end

  def step
    LibSQLite3::Code.new LibSQLite3.step(self)
  end

  def column_count
    LibSQLite3.column_count(self)
  end

  def column_type(index)
    LibSQLite3::Type.new LibSQLite3.column_type(self, index.to_i32)
  end

  def column_name(index)
    String.new LibSQLite3.column_name(self, index.to_i32)
  end

  def column_int64(index)
    LibSQLite3.column_int64(self, index.to_i32)
  end

  def column_double(index)
    LibSQLite3.column_double(self, index.to_i32)
  end

  def column_text(index)
    LibSQLite3.column_text(self, index.to_i32)
  end

  def column_blob(index)
    LibSQLite3.column_blob(self, index.to_i32)
  end

  def column_bytes(index)
    LibSQLite3.column_bytes(self, index.to_i32)
  end

  def execute(*binds)
    execute binds
  end

  def execute(*binds)
    execute(binds) do |row|
      yield row
    end
  end

  def execute(binds : Slice(UInt8))
    reset
    self[1] = binds
    ResultSet.new self
  end

  def execute(binds : Enumerable)
    reset
    binds.each_with_index(1) do |bind_value, index|
      self[index] = bind_value
    end
    ResultSet.new self
  end

  def execute(binds : Enumerable | Slice(UInt8), &block)
    result_set = execute(binds)
    yield result_set
    close
  end

  def [](index : Int)
    case type = column_type(index)
    when LibSQLite3::Type::INTEGER
      column_int64(index)
    when LibSQLite3::Type::FLOAT
      column_double(index)
    when LibSQLite3::Type::TEXT
      String.new(column_text(index))
    when LibSQLite3::Type::BLOB
      blob = column_blob(index)
      bytes = column_bytes(index)
      ptr = Pointer(UInt8).malloc(bytes)
      ptr.copy_from(blob, bytes)
      Slice.new(ptr, bytes)
    when LibSQLite3::Type::NULL
      nil
    else
      raise "Unknown column type: #{type}"
    end
  end

  def [](name : String)
    column_count.times do |i|
      if column_name(i) == name
        return self[i]
      end
    end
    raise "Unknown column: #{name}"
  end

  def []=(index : Int, value : Nil)
    check LibSQLite3.bind_null(self, index.to_i32)
  end

  def []=(index : Int, value : Int32)
    check LibSQLite3.bind_int(self, index.to_i32, value)
  end

  def []=(index : Int, value : Int64)
    check LibSQLite3.bind_int64(self, index.to_i32, value)
  end

  def []=(index : Int, value : Float)
    check LibSQLite3.bind_double(self, index.to_i32, value.to_f64)
  end

  def []=(index : Int, value : String)
    check LibSQLite3.bind_text(self, index.to_i32, value, value.bytesize, nil)
  end

  def []=(index : Int, value : Slice(UInt8))
    check LibSQLite3.bind_blob(self, index.to_i32, value, value.length, nil)
  end

  def []=(name : String | Symbol, value)
    converted_name = ":#{name}"
    index = LibSQLite3.bind_parameter_index(self, converted_name)
    if index == 0
      raise "Unknown parameter: #{name}"
    end
    self[index] = value
  end

  def []=(index : Int, hash : Hash)
    hash.each do |key, value|
      self[key] = value
    end
  end

  def columns
    Array.new(column_count) { |i| column_name(i) }
  end

  def reset
    LibSQLite3.reset(self)
  end

  def close
    raise "Statement already closed" if @closed
    @closed = true

    check LibSQLite3.finalize(self)
  end

  def closed?
    @closed
  end

  def to_unsafe
    @stmt
  end

  private def check(code)
    raise Exception.new(@db) unless code == 0
  end
end
