class SQLite3::Statement2 < DB::Statement
  def initialize(@driver, sql)
    check LibSQLite3.prepare_v2(@driver, sql, sql.bytesize + 1, out @stmt, nil)
    # @closed = false
  end

  protected def before_execute
    LibSQLite3.reset(self)
  end

  protected def add_parameter(index : Int32, value)
    bind_arg(index, value)
  end

  protected def add_parameter(name : String, value)
    converted_name = ":#{name}"
    index = LibSQLite3.bind_parameter_index(self, converted_name)
    raise "Unknown parameter: #{name}" if index == 0
    bind_arg(index, value)
  end

  protected def execute
    ResultSet2.new(self)
  end

  private def bind_arg(index, value : Nil)
    check LibSQLite3.bind_null(self, index)
  end

  private def bind_arg(index, value : Int32)
    check LibSQLite3.bind_int(self, index, value)
  end

  private def bind_arg(index, value : Int64)
    check LibSQLite3.bind_int64(self, index, value)
  end

  private def bind_arg(index, value : Float32)
    check LibSQLite3.bind_double(self, index, value.to_f64)
  end

  private def bind_arg(index, value : Float64)
    check LibSQLite3.bind_double(self, index, value)
  end

  private def bind_arg(index, value : String)
    check LibSQLite3.bind_text(self, index, value, value.bytesize, nil)
  end

  private def check(code)
    raise Exception.new(@driver) unless code == 0
  end

  def to_unsafe
    @stmt
  end
end
