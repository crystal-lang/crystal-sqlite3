# The Database class encapsulates  single connection to an SQLite3 database. Its usage is very straightforward:
#
# ```
# require "sqlite3"
#
# db = SQLite3::Database.new("data.db")
# db.execute("select * from table") do |row|
#   p row
# end
# db.close
# ```
#
# Lower level methods are also provided.
class SQLite3::Database
  # Creates a new Database object that opens the given file.
  def initialize(filename)
    code = LibSQLite3.open_v2(filename, out @db, SQLite3.flags(READWRITE, CREATE), nil)
    if code != 0
      raise Exception.new(@db)
    end
    @closed = false
  end

  # Allows for initialization with specific flags. Primary use case is to allow
  # for sqlite3 URI opening and in memory DB operations.
  def initialize(filename, flags : SQLite3::Flag)
    code = LibSQLite3.open_v2(filename, out @db, flags, nil)
    if code != 0
      raise Exception.new(@db)
    end
    @closed = false
  end

  # Creates a new Database object that opens the given file, yields it, and closes it at the end.
  def self.new(filename)
    db = new filename
    begin
      yield db
    ensure
      db.close
    end
  end

  # Dump the database to another SQLite3 instance. This can be used for backing up a SQLite3::Database
  # to disk or the opposite
  #
  # Example:
  #
  # ```
  # source_database = SQLite3::Database.new("mydatabase.db")
  # in_memory_db = SQLite3::Database.new(
  #   "file:memdb1?mode=memory&cache=shared",
  #   SQLite3.flags(URI, CREATE, READWRITE, FULLMUTEX))
  # source_database.dump(in_memory_db)
  # source_database.close
  # in_memory_db.exectute do |row|
  #   # ...
  # end
  #    ```
  def dump(to : SQLite3::Database)
    backup_item = LibSQLite3.backup_init(to.@db, "main", @db, "main")
    if backup_item.null?
      raise Exception.new(to.@db)
    end
    code = LibSQLite3.backup_step(backup_item, -1)

    if code != LibSQLite3::Code::DONE
      raise Exception.new(to.@db)
    end
    code = LibSQLite3.backup_finish(backup_item)
    if code != LibSQLite3::Code::OKAY
      raise Exception.new(to.@db)
    end
  end

  # Executes the given SQL statement. If additional parameters are given, they are treated as bind variables,
  # and are bound to the placeholders in the query.
  #
  # Note that if any of the values passed to this are hashes, then the key/value pairs are each bound separately,
  # with the key being used as the name of the placeholder to bind the value to.
  #
  # Returns an `Array(Array(Value))`.
  def execute(sql, *binds)
    execute(sql, binds)
  end

  # Executes the given SQL statement. If additional parameters are given, they are treated as bind variables,
  # and are bound to the placeholders in the query.
  #
  # Note that if any of the values passed to this are hashes, then the key/value pairs are each bound separately,
  # with the key being used as the name of the placeholder to bind the value to.
  #
  # Yields one `Array(Value)` for each result.
  def execute(sql, *binds, &block)
    execute(sql, binds) do |row|
      yield row
    end
  end

  # Executes the given SQL statement. If additional parameters are given, they are treated as bind variables,
  # and are bound to the placeholders in the query.
  #
  # Note that if any of the values passed to this are hashes, then the key/value pairs are each bound separately,
  # with the key being used as the name of the placeholder to bind the value to.
  #
  # Returns an `Array(Array(Value))`.
  def execute(sql, binds : Enumerable)
    rows = [] of Array(Value)
    execute(sql, binds) do |row|
      rows << row
    end
    rows
  end

  # Executes the given SQL statement. If additional parameters are given, they are treated as bind variables,
  # and are bound to the placeholders in the query.
  #
  # Note that if any of the values passed to this are hashes, then the key/value pairs are each bound separately,
  # with the key being used as the name of the placeholder to bind the value to.
  #
  # Yields one `Array(Value)` for each result.
  def execute(sql, binds : Enumerable, &block)
    query(sql, binds) do |result_set|
      while result_set.next
        yield result_set.to_a
      end
    end
  end

  # A convenience method that returns the first row of a query result.
  def get_first_row(sql, *binds)
    get_first_row(sql, binds)
  end

  # A convenience method that returns the first row of a query result.
  def get_first_row(sql, binds : Enumerable)
    query(sql, binds) do |result_set|
      if result_set.next
        return result_set.to_a
      else
        raise "no results"
      end
    end
  end

  # A convenience method that returns the first value of the first row of a query result.
  def get_first_value(sql, *binds)
    get_first_value(sql, binds)
  end

  # A convenience method that returns the first value of the first row of a query result.
  def get_first_value(sql, binds : Enumerable)
    query(sql, binds) do |result_set|
      if result_set.next
        return result_set[0]
      else
        raise "no results"
      end
    end
  end

  # Executes a query and gives back a `ResultSet`.
  def query(sql, *binds)
    query(sql, binds)
  end

  # Executes a query and yields a `ResultSet` that will be closed at the end of the given block.
  def query(sql, *binds, &block)
    query(sql, binds) do |result_set|
      yield result_set
    end
  end

  # Executes a query and gives back a `ResultSet`.
  def query(sql, binds : Enumerable)
    prepare(sql).execute(binds)
  end

  # Executes a query and yields a `ResultSet` that will be closed at the end of the given block.
  def query(sql, binds : Enumerable, &block)
    prepare(sql).execute(binds) do |result_set|
      yield result_set
    end
  end

  # Prepares an sql statement. Returns a `Statement`.
  def prepare(sql)
    Statement.new(self, sql)
  end

  # Obtains the unique row ID of the last row to be inserted by this Database instance.
  # This is an `Int64`.
  def last_insert_row_id
    LibSQLite3.last_insert_rowid(self)
  end

  # Quotes the given string, making it safe to use in an SQL statement.
  # It replaces all instances of the single-quote character with two single-quote characters.
  def quote(string)
    string.gsub('\'', "''")
  end

  # Returns `true` if this database instance has been closed (see `#close`).
  def closed?
    @closed
  end

  # Closes this database.
  def close
    return if @closed

    @closed = true

    LibSQLite3.close_v2(@db)
  end

  # :nodoc:
  def finalize
    close
  end

  # :nodoc:
  def to_unsafe
    @db
  end
end
