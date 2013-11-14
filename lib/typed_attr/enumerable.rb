module Enumerable
  # Not sure why this doesn't exist or
  # where to put it.
  def map_with_index
    i = -1
    map { | e | yield e, i += 1 }
  end
end

