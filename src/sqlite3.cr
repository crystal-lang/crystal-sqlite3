require "db"
require "./sqlite3/**"

module SQLite3
  DATE_FORMAT_SUBSECOND = "%F %H:%M:%S.%L"
  DATE_FORMAT_SECOND    = "%F %H:%M:%S"

  alias Any = DB::Any | Int16 | Int8 | UInt32 | UInt16 | UInt8

  # :nodoc:
  TIME_ZONE = Time::Location::UTC

  # :nodoc:
  REGEXP_FN = ->(context : LibSQLite3::SQLite3Context, argc : Int32, argv : LibSQLite3::SQLite3Value*) do
    argv = Slice.new(argv, sizeof(Void*))
    pattern = LibSQLite3.value_text(argv[0])
    text = LibSQLite3.value_text(argv[1])
    LibSQLite3.result_int(context, Regex.new(String.new(pattern)).matches?(String.new(text)).to_unsafe)
    nil
  end
end
