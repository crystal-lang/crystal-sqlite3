module SQLite3
  # All possible values of each column of a row returned by `Database#execute`.
  alias Value = Nil | Int64 | Float64 | String | Slice(UInt8)
end
