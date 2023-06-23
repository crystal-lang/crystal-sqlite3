class SQLite3::Driver < DB::Driver
  class ConnectionBuilder < ::DB::ConnectionBuilder
    def initialize(@options : ::DB::Connection::Options, @sqlite3_options : SQLite3::Connection::Options)
    end

    def build : ::DB::Connection
      SQLite3::Connection.new(@options, @sqlite3_options)
    end
  end

  def connection_builder(uri : URI) : ::DB::ConnectionBuilder
    params = HTTP::Params.parse(uri.query || "")
    ConnectionBuilder.new(connection_options(params), SQLite3::Connection::Options.from_uri(uri))
  end
end

DB.register_driver "sqlite3", SQLite3::Driver
