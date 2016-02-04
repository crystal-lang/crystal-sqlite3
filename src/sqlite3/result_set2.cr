class SQLite3::ResultSet2 < DB::ResultSet
  @column_index = 0

  protected def do_close
    super
    LibSQLite3.reset(self)
  end

  # Advances to the next row. Returns `true` if there's a next row,
  # `false` otherwise. Must be called at least once to advance to the first
  # row.
  def move_next
    @column_index = 0

    case step
    when LibSQLite3::Code::ROW
      true
    when LibSQLite3::Code::DONE
      false
    else
      raise Exception.new(@statement.connection)
    end
  end

  {% for t in DB::TYPES %}
    def read?(t : {{t}}.class) : {{t}}?
      if read_nil?
        moving_column { nil }
      else
        read(t)
      end
    end
  {% end %}

  def read(t : String.class) : String
    moving_column { |col| String.new(LibSQLite3.column_text(self, col)) }
  end

  def read(t : Int32.class) : Int32
    read(Int64).to_i32
  end

  def read(t : Int64.class) : Int64
    moving_column { |col| LibSQLite3.column_int64(self, col) }
  end

  def read(t : Float32.class) : Float32
    read(Float64).to_f32
  end

  def read(t : Float64.class) : Float64
    moving_column { |col| LibSQLite3.column_double(self, col) }
  end

  def read(t : Slice(UInt8).class) : Slice(UInt8)
    moving_column do |col|
      blob = LibSQLite3.column_blob(self, col)
      bytes = LibSQLite3.column_bytes(self, col)
      ptr = Pointer(UInt8).malloc(bytes)
      ptr.copy_from(blob, bytes)
      Slice(UInt8).new(ptr, bytes)
    end
  end

  def column_count
    LibSQLite3.column_count(self)
  end

  def column_name(index)
    String.new LibSQLite3.column_name(self, index)
  end

  def column_type(index : Int32)
    case LibSQLite3.column_type(self, index)
    when Type::INTEGER; Int64
    when Type::FLOAT  ; Float64
    when Type::BLOB   ; Slice(UInt8)
    when Type::TEXT   ; String
    when Type::NULL   ; Nil
    else
      raise "not implemented"
    end
  end

  def to_unsafe
    @statement.to_unsafe
  end

  private def read_nil?
    column_sqlite_type == Type::NULL
  end

  private def column_sqlite_type
    LibSQLite3.column_type(self, @column_index)
  end

  # :nodoc:
  private def step
    LibSQLite3::Code.new LibSQLite3.step(@statement)
  end

  private def moving_column
    res = yield @column_index
    @column_index += 1
    res
  end
end
