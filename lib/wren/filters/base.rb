

class Filter
  def init
  end
  
  def directive_name
    "DIRECTIVE"
  end

  def name
    :directive
  end

  def replacement_contents
    ""
  end

  def alternative_value(file_cache)
    nil
  end

  # Behaviors to support

  # 1. Erase the directive or replace with new contents
  # 2. Return the contents of the directive, if any
  # 3. Defer to another method of finding the contents, if needed (e.g. from the filename)

end
