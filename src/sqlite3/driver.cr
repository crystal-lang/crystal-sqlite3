class SQLite3::Driver < DB::Driver
  def connection_builder(uri : URI) : Proc(::DB::Connection)
    params = HTTP::Params.parse(uri.query || "")
    options = connection_options(params)
    sqlite3_options = SQLite3::Connection::Options.from_uri(uri)
    ->{ SQLite3::Connection.new(options, sqlite3_options).as(::DB::Connection) }
  end
end

DB.register_driver "sqlite3", SQLite3::Driver
