module ValuesMatch
  def values_match?(actual, expected)
    if expected.is_a? Regexp
      (actual =~ expected) ? true : false
    else
      expected == actual
    end
  end  
end
