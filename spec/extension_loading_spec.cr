require "./spec_helper"

describe SQLite3::Connection do
  describe "#enable_load_extension" do
    it "enables extension loading" do
      DB.open("sqlite3::memory:") do |db|
        conn = db.checkout
        conn.enable_load_extension(true)
        # Should not raise
      end
    end

    it "disables extension loading" do
      DB.open("sqlite3::memory:") do |db|
        conn = db.checkout
        conn.enable_load_extension(false)
        # Should not raise
      end
    end
  end

  describe "#load_extension" do
    it "raises error when extension not found" do
      DB.open("sqlite3::memory:") do |db|
        conn = db.checkout
        conn.enable_load_extension(true)
        expect_raises(SQLite3::Exception, /Failed to load extension/) do
          conn.load_extension("/nonexistent/extension.so")
        end
      end
    end

    it "loads extension with entry point" do
      # This test requires a valid extension path
      # Skip if no extension available
      {% if flag?(:darwin) %}
        ext_path = "/opt/homebrew/opt/sqlite/lib/sqlite3/fts5.dylib"
        if File.exists?(ext_path)
          DB.open("sqlite3::memory:") do |db|
            conn = db.checkout
            conn.enable_load_extension(true)
            conn.load_extension(ext_path)
            # If we get here without error, extension loaded
          end
        end
      {% end %}
    end
  end
end

describe SQLite3::Exception do
  describe ".new(String)" do
    it "creates exception with message" do
      ex = SQLite3::Exception.new("Test error message")
      ex.message.should eq("Test error message")
      ex.code.should eq(0)
    end
  end
end
