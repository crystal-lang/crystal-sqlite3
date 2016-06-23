class SQLite3::Connection < DB::Connection
  def initialize(database)
    super
    filename = self.class.filename(database.uri)
    # TODO maybe enable Flag::URI to parse query string in the uri as additional flags
    check LibSQLite3.open_v2(filename, out @db, (Flag::READWRITE | Flag::CREATE), nil)
  end

  def self.filename(uri : URI)
    URI.unescape (if path = uri.path
      (uri.host || "") + path
    else
      uri.opaque.not_nil!
    end)
  end

  def build_statement(query)
    Statement.new(self, query)
  end

  def do_close
    @statements_cache.values.each &.close
    super
    LibSQLite3.close_v2(self)
  end

  # Dump the database to another SQLite3 database. This can be used for backing up a SQLite3 Database
  # to disk or the opposite
  def dump(to : SQLite3::Connection)
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

  def to_unsafe
    @db
  end

  private def check(code)
    raise Exception.new(self) unless code == 0
  end
end
