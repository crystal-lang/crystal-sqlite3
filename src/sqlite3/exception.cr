class SQLite3::Exception < ::Exception
  getter code

  def initialize(db)
    super(String.new(LibSQLite3.errmsg(db)))
    @code = LibSQLite3.errcode(db)
  end
end
