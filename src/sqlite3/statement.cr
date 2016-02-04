class SQLite3::Statement < DB::Statement
  def initialize(connection, sql)
    super(connection)
    check LibSQLite3.prepare_v2(@connection, sql, sql.bytesize + 1, out @stmt, nil)
  end

  protected def perform_query(args : Slice(DB::Any))
    LibSQLite3.reset(self)
    args.each_with_index(1) do |arg, index|
      bind_arg(index, arg)
    end
    ResultSet.new(self)
  end

  protected def perform_exec(args : Slice(DB::Any))
    rs = perform_query(args)
    rs.move_next
    rs.close

    rows_affected = LibSQLite3.changes(connection)
    last_id = LibSQLite3.last_insert_rowid(connection)

    DB::ExecResult.new rows_affected, last_id
  end

  protected def on_close
    super
    check LibSQLite3.finalize(self)
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

  private def bind_arg(index, value : Slice(UInt8))
    check LibSQLite3.bind_blob(self, index, value, value.size, nil)
  end

  private def check(code)
    raise Exception.new(@connection) unless code == 0
  end

  def to_unsafe
    @stmt
  end
end
