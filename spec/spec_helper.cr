require "spec"
require "../src/sqlite3"

include SQLite3

DB_FILENAME = "./test.db"

def with_db(&block : DB::Database ->)
  File.delete(DB_FILENAME) rescue nil
  DB.open "sqlite3:#{DB_FILENAME}", &block
ensure
  File.delete(DB_FILENAME)
end

def with_cnn(&block : DB::Connection ->)
  File.delete(DB_FILENAME) rescue nil
  DB.connect "sqlite3:#{DB_FILENAME}", &block
ensure
  File.delete(DB_FILENAME)
end

def with_db(name, &block : DB::Database ->)
  File.delete(name) rescue nil
  DB.open "sqlite3:#{name}", &block
ensure
  File.delete(name)
end

def with_mem_db(&block : DB::Database ->)
  DB.open "sqlite3://%3Amemory%3A", &block
end
