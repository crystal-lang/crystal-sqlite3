class SQLite3::ResultSet
  def initialize(@statement)
  end

  def column_count
    @statement.column_count
  end

  def [](index)
    @statement[index]
  end

  def next
    case @statement.step
    when LibSQLite3::Code::ROW
      true
    when LibSQLite3::Code::DONE
      false
    else
      raise Exception.new(@db)
    end
  end

  def close
    @statement.close
  end

  def to_a
    Array(ColumnType).new(column_count) { |i| self[i] }
  end
end
