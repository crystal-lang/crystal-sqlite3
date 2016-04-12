# A statement represents a prepared-but-unexecuted SQL query.
class SQLite3::Statement
  getter db

  # :nodoc:
  def initialize(@db : Database, sql : String)
    check LibSQLite3.prepare_v2(@db, sql, sql.bytesize + 1, out @stmt, nil)
    @closed = false
  end

  # :nodoc:
  def self.new(db, sql)
    statement = new db, sql
    begin
      yield statement
    ensure
      statement.close
    end
  end

  # :nodoc:
  def step
    LibSQLite3::Code.new LibSQLite3.step(self)
  end

  # Returns the number of columns in this statement.
  def column_count
    LibSQLite3.column_count(self)
  end

  # Returns the `Type` of the column at the given index.
  def column_type(index : Int)
    LibSQLite3.column_type(self, index)
  end

  # Returns the name of the column at the given index.
  def column_name(index)
    String.new LibSQLite3.column_name(self, index)
  end

  # Executes this statement with the given binds and returns a `ResultSet`.
  def execute(*binds)
    execute binds
  end

  # Executes this statement with the given binds and yields a `ResultSet` that
  # will be closed at the end of the block.
  def execute(*binds)
    execute(binds) do |row|
      yield row
    end
  end

  # Executes this statement with a single BLOB bind and returns a `ResultSet`.
  def execute(binds : Slice(UInt8))
    reset
    self[1] = binds
    ResultSet.new self
  end

  # Executes this statement with the given binds and returns a `ResultSet`.
  def execute(binds : Enumerable)
    reset
    # TODO use offset after Crystal 0.6.2
    binds.each_with_index do |bind_value, index|
      self[index + 1] = bind_value
    end
    ResultSet.new self
  end

  # Executes this statement with the given binds and yields a `ResultSet` that
  # will be closed at the end of the block.
  def execute(binds : Enumerable | Slice(UInt8), &block)
    result_set = execute(binds)
    yield result_set
  ensure
    close
  end

  # Returns the value of the given column by index (1-based).
  def [](index : Int)
    case type = column_type(index)
    when Type::INTEGER
      column_int64(index)
    when Type::FLOAT
      column_double(index)
    when Type::TEXT
      String.new(column_text(index))
    when Type::BLOB
      blob = column_blob(index)
      bytes = column_bytes(index)
      ptr = Pointer(UInt8).malloc(bytes)
      ptr.copy_from(blob, bytes)
      Slice.new(ptr, bytes)
    when Type::NULL
      nil
    else
      raise "Unknown column type: #{type}"
    end
  end

  # Returns the value of the given column by name.
  def [](name : String)
    column_count.times do |i|
      if column_name(i) == name
        return self[i]
      end
    end
    raise "Unknown column: #{name}"
  end

  # Binds the parameter at the given index to an Int.
  def []=(index : Int, value : Nil)
    check LibSQLite3.bind_null(self, index)
  end

  # Binds the parameter at the given index to an Int32.
  def []=(index : Int, value : Int32)
    check LibSQLite3.bind_int(self, index, value)
  end

  # Binds the parameter at the given index to an Int64.
  def []=(index : Int, value : Int64)
    check LibSQLite3.bind_int64(self, index, value)
  end

  # Binds the parameter at the given index to a Float.
  def []=(index : Int, value : Float)
    check LibSQLite3.bind_double(self, index, value.to_f64)
  end

  # Binds the parameter at the given index to a String.
  def []=(index : Int, value : String)
    check LibSQLite3.bind_text(self, index, value, value.bytesize, nil)
  end

  # Binds the parameter at the given index to a BLOB.
  def []=(index : Int, value : Slice(UInt8))
    check LibSQLite3.bind_blob(self, index, value, value.size, nil)
  end

  # Binds a named parameter, using the `:AAAA` naming scheme for parameters.
  def []=(name : String | Symbol, value)
    converted_name = ":#{name}"
    index = LibSQLite3.bind_parameter_index(self, converted_name)
    if index == 0
      raise "Unknown parameter: #{name}"
    end
    self[index] = value
  end

  # Binds a hash to this statement (the `index` is ignored).
  def []=(index : Int, hash : Hash)
    hash.each do |key, value|
      self[key] = value
    end
  end

  # Returns the column names of this statement.
  def columns
    Array.new(column_count) { |i| column_name(i) }
  end

  # Returns an `Array(Type)` of this statement's columns. Note that the statement
  # must be executed in order for this to return sensible values, otherwise all types
  # will be NULL.
  def types
    Array.new(column_count) { |i| column_type(i) }
  end

  # Reset this statment, allowing to re-execute it with new binds.
  def reset
    LibSQLite3.reset(self)
  end

  # Closes this statement.
  def close
    raise "Statement already closed" if @closed
    @closed = true

    check LibSQLite3.finalize(self)
  end

  # Returns `true` if this statement is closed. See `#close`.
  def closed?
    @closed
  end

  # :nodoc:
  def to_unsafe
    @stmt
  end

  private def column_int64(index)
    LibSQLite3.column_int64(self, index)
  end

  private def column_double(index)
    LibSQLite3.column_double(self, index)
  end

  private def column_text(index)
    LibSQLite3.column_text(self, index)
  end

  private def column_blob(index)
    LibSQLite3.column_blob(self, index)
  end

  private def column_bytes(index)
    LibSQLite3.column_bytes(self, index)
  end

  private def check(code)
    raise Exception.new(@db) unless code == 0
  end
end
