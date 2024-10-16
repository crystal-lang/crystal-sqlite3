class SQLite3::ResultSet < DB::ResultSet
  @column_index = 0

  protected def do_close
    LibSQLite3.reset(self)
    super
  end

  # Advances to the next row. Returns `true` if there's a next row,
  # `false` otherwise. Must be called at least once to advance to the first
  # row.
  def move_next : Bool
    @column_index = 0

    case step
    when LibSQLite3::Code::ROW
      true
    when LibSQLite3::Code::DONE
      false
    else
      raise Exception.new(sqlite3_statement.sqlite3_connection)
    end
  end

  def read
    col = @column_index
    value =
      case LibSQLite3.column_type(self, col)
      when Type::INTEGER
        LibSQLite3.column_int64(self, col)
      when Type::FLOAT
        LibSQLite3.column_double(self, col)
      when Type::BLOB
        blob = LibSQLite3.column_blob(self, col)
        bytes = LibSQLite3.column_bytes(self, col)
        ptr = Pointer(UInt8).malloc(bytes)
        ptr.copy_from(blob, bytes)
        Bytes.new(ptr, bytes)
      when Type::TEXT
        String.new(LibSQLite3.column_text(self, col))
      when Type::NULL
        nil
      else
        raise Exception.new(sqlite3_statement.sqlite3_connection)
      end
    @column_index += 1
    value
  end

  def next_column_index : Int32
    @column_index
  end

  def read(t : UInt8.class) : UInt8
    read(Int64).to_u8
  end

  def read(type : UInt8?.class) : UInt8?
    read(Int64?).try &.to_u8
  end

  def read(t : UInt16.class) : UInt16
    read(Int64).to_u16
  end

  def read(type : UInt16?.class) : UInt16?
    read(Int64?).try &.to_u16
  end

  def read(t : UInt32.class) : UInt32
    read(Int64).to_u32
  end

  def read(type : UInt32?.class) : UInt32?
    read(Int64?).try &.to_u32
  end

  def read(t : Int8.class) : Int8
    read(Int64).to_i8
  end

  def read(type : Int8?.class) : Int8?
    read(Int64?).try &.to_i8
  end

  def read(t : Int16.class) : Int16
    read(Int64).to_i16
  end

  def read(type : Int16?.class) : Int16?
    read(Int64?).try &.to_i16
  end

  def read(t : Int32.class) : Int32
    read(Int64).to_i32
  end

  def read(type : Int32?.class) : Int32?
    read(Int64?).try &.to_i32
  end

  def read(t : Float32.class) : Float32
    read(Float64).to_f32
  end

  def read(type : Float32?.class) : Float32?
    read(Float64?).try &.to_f32
  end

  def read(t : Time.class) : Time
    text = read(String)
    if text.includes? "."
      Time.parse text, SQLite3::DATE_FORMAT_SUBSECOND, location: SQLite3::TIME_ZONE
    else
      Time.parse text, SQLite3::DATE_FORMAT_SECOND, location: SQLite3::TIME_ZONE
    end
  end

  def read(t : Time?.class) : Time?
    read(String?).try { |v|
      if v.includes? "."
        Time.parse v, SQLite3::DATE_FORMAT_SUBSECOND, location: SQLite3::TIME_ZONE
      else
        Time.parse v, SQLite3::DATE_FORMAT_SECOND, location: SQLite3::TIME_ZONE
      end
    }
  end

  def read(t : Bool.class) : Bool
    read(Int64) != 0
  end

  def read(t : Bool?.class) : Bool?
    read(Int64?).try &.!=(0)
  end

  def column_count : Int32
    LibSQLite3.column_count(self)
  end

  def column_name(index) : String
    String.new LibSQLite3.column_name(self, index)
  end

  def to_unsafe
    sqlite3_statement.to_unsafe
  end

  # :nodoc:
  private def step
    LibSQLite3::Code.new LibSQLite3.step(sqlite3_statement)
  end

  protected def sqlite3_statement
    @statement.as(Statement)
  end

  private def moving_column(&)
    res = yield @column_index
    @column_index += 1
    res
  end
end
