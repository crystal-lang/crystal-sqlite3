require "db"
require "../src/sqlite3"

db = DB.open "sqlite3://%3Amemory%3A"

db.setup_connection do |connection|
  connection.enable_extension_load true
  connection.load_extension "/usr/local/lib/mod_spatialite"
  connection.enable_extension_load false
end

INSERT_POINT_QUERY = "insert into contacts values (?, SetSRID(MakePoint(?, ?),2261))"

db.exec "create table contacts (name text, position)"
db.exec INSERT_POINT_QUERY, "John Doe", 51.5074, 0.1278
db.exec INSERT_POINT_QUERY, "Mario Rossi", 41.9028, 12.4964
db.exec INSERT_POINT_QUERY, "Dewayne Abara", 9.7054, 43.6327
db.exec INSERT_POINT_QUERY, "Toshiro Ito", 35.6762, 139.6503

db.query "select a.name, b.name, st_distance(a.position, b.position) from contacts a, contacts b where a.name != b.name" do |rs|
  rs.each do
    puts "Distance between #{rs.read(String)} and #{rs.read(String)} is #{rs.read(Float)}"
  end
end