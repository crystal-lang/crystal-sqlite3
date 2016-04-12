# The ResultSet object encapsulates the enumerability of a query’s output.
# It is a simple cursor over the data that the query returns.
#
# Typical usage is:
#
# ```
# require "sqlite3"
#
# db = SQLite3::Database.new("foo.db")
# stmt = db.prepare("select * from person")
# result_set = stmt.execute
# while result_set.next
#   p result_set.to_a
# end
# stmt.close
# db.close
# ```
class SQLite3::ResultSet
  # :nodoc:
  def initialize(@statement : Statement)
  end

  # Returns the number of columns.
  def column_count
    @statement.column_count
  end

  # Returns the value of a column by index or name.
  def [](index_or_name)
    @statement[index_or_name]
  end

  # Returns the types of the columns, an `Array(Type)`.
  def types
    @statement.types
  end

  # Returns the names of the columns, an `Array(String)`.
  def columns
    @statement.columns
  end

  # Advances to the next row. Returns `true` if there's a next row,
  # `false` otherwise. Must be called at least once to advance to the first
  # row.
  def next
    case @statement.step
    when LibSQLite3::Code::ROW
      true
    when LibSQLite3::Code::DONE
      false
    else
      raise Exception.new(@statement.db)
    end
  end

  # Closes this result set, closing the associated statement.
  def close
    @statement.close
  end

  # Returns `true` if the associated statement is closed.
  def closed?
    @statement.closed?
  end

  # Return the current row's value as an `Array(Value)`.
  def to_a
    Array(Value).new(column_count) { |i| self[i] }
  end
end
