class PostDateFilter < Filter
  def init
  end

  def name
    :post_date
  end

  def directive
    "DATE"
  end

  def value(match)
  end

  def alternative_value(file_cache)
    nil
  end
end
