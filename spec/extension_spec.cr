require "./spec_helper"

extension = File.tempfile("sqlite3-extension", {% if flag?(:darwin) %} ".dylib" {% else %} ".so" {% end %})
extension.close

Spec.before_suite do
  args = ["-fPIC", {% if flag?(:darwin) %} "-dynamiclib" {% else %} "-shared" {% end %},
          File.join(__DIR__, "fixtures", "extension.c"), "-o", extension.path]
  status = Process.run(ENV["CC"]? || "cc", args, output: STDOUT, error: STDERR)
  raise "Failed to compile SQLite extension fixture; a C compiler and sqlite3ext.h are required" unless status.success?
rescue error
  extension.delete
  raise error
end

Spec.after_suite { extension.delete }

private def with_extension_connection(&block : SQLite3::Connection ->)
  DB.connect("sqlite3::memory:") do |connection|
    connection = connection.as(SQLite3::Connection)
    # Some SQLite builds enable the native loader by default.
    LibSQLite3.db_config(connection, LibSQLite3::DBCONFIG_ENABLE_LOAD_EXTENSION,
      0, Pointer(Int32).null).should eq(0)
    yield connection
  end
end

private def expect_extension_loading_disabled(connection, path)
  enabled = 0
  LibSQLite3.db_config(connection, LibSQLite3::DBCONFIG_ENABLE_LOAD_EXTENSION,
    -1, pointerof(enabled)).should eq(0)
  enabled.should eq(0)

  message = Pointer(UInt8).null
  begin
    LibSQLite3.load_extension(connection, path, nil, pointerof(message)).should eq(1)
    message.null?.should be_false
    String.new(message).should eq("not authorized")
  ensure
    LibSQLite3.free(message)
  end

  expect_raises(SQLite3::Exception, "not authorized") do
    connection.scalar("SELECT load_extension(?)", path)
  end
end

describe SQLite3::Connection do
  describe "#load_extension" do
    it "raises an error on a closed connection" do
      with_extension_connection do |connection|
        connection.close
        error = expect_raises(SQLite3::Exception, "Connection is closed") do
          connection.load_extension(extension.path)
        end
        error.code.should eq(LibSQLite3::Code::MISUSE.value)
      end
    end

    it "loads an extension only on the selected connection and disables loading afterward" do
      with_extension_connection do |connection|
        expect_raises(SQLite3::Exception, "no such function: test_extension") do
          connection.scalar("SELECT test_extension()")
        end
        expect_extension_loading_disabled(connection, extension.path)

        connection.load_extension(extension.path).should be_nil
        connection.scalar("SELECT test_extension()").should eq(42)
        expect_extension_loading_disabled(connection, extension.path)

        with_extension_connection do |other|
          expect_raises(SQLite3::Exception, "no such function: test_extension") do
            other.scalar("SELECT test_extension()")
          end
        end
      end
    end

    it "uses an explicit entry point" do
      with_extension_connection do |connection|
        connection.load_extension(extension.path, "sqlite3_alternative_init")
        connection.scalar("SELECT test_alternative_extension()").should eq(42)
        expect_raises(SQLite3::Exception, "no such function: test_extension") do
          connection.scalar("SELECT test_extension()")
        end
        expect_extension_loading_disabled(connection, extension.path)
      end
    end

    it "preserves a missing library error and disables loading" do
      with_extension_connection do |connection|
        missing_path = "#{extension.path}.missing"
        error = expect_raises(SQLite3::Exception, missing_path) do
          connection.load_extension(missing_path)
        end
        error.code.should eq(1)
        expect_extension_loading_disabled(connection, extension.path)
      end
    end

    it "preserves a missing entry point error and disables loading" do
      with_extension_connection do |connection|
        error = expect_raises(SQLite3::Exception, "sqlite3_missing_init") do
          connection.load_extension(extension.path, "sqlite3_missing_init")
        end
        error.code.should eq(1)
        expect_extension_loading_disabled(connection, extension.path)
      end
    end

    it "preserves an initialization error and permits a later successful load" do
      with_extension_connection do |connection|
        error = expect_raises(SQLite3::Exception, "fixture initialization failed") do
          connection.load_extension(extension.path, "sqlite3_failure_init")
        end
        error.code.should eq(1)
        expect_extension_loading_disabled(connection, extension.path)

        connection.load_extension(extension.path)
        connection.scalar("SELECT test_extension()").should eq(42)
        expect_extension_loading_disabled(connection, extension.path)
      end
    end

    it "rejects NUL bytes in paths and entry points before loading" do
      with_extension_connection do |connection|
        expect_raises(ArgumentError) do
          connection.load_extension("#{extension.path}\0ignored")
        end
        expect_raises(ArgumentError) do
          connection.load_extension(extension.path, "sqlite3_extension_init\0ignored")
        end
        expect_raises(SQLite3::Exception, "no such function: test_extension") do
          connection.scalar("SELECT test_extension()")
        end
        expect_extension_loading_disabled(connection, extension.path)
      end
    end

    it "works with setup_connection for existing and future pooled connections" do
      DB.open("sqlite3::memory:?initial_pool_size=1&max_pool_size=2") do |db|
        setups = 0
        db.setup_connection do |connection|
          connection.as(SQLite3::Connection).load_extension(extension.path)
          setups += 1
        end
        setups.should eq(1)

        db.using_connection do |first|
          first.scalar("SELECT test_extension()").should eq(42)
          db.using_connection do |second|
            first.same?(second).should be_false
            second.scalar("SELECT test_extension()").should eq(42)
            expect_extension_loading_disabled(second.as(SQLite3::Connection), extension.path)
          end
          expect_extension_loading_disabled(first.as(SQLite3::Connection), extension.path)
        end
        setups.should eq(2)
      end
    end
  end
end
