class Analyzer 
  def file_violations(file_name)
    scores.select{|file, violations| file.match(/#{file_name}/)}
  end

  def scores
    @results
  end
end
