require 'flay'

class Flayer < Analyzer
  def initialize(path)
    files = Flay.expand_dirs_to_files(path)
    flay = Flay.new
    flay.process(*files)
    file = Tempfile.new('flay-output')
    flay.report(file)
    file.rewind
    @results = build_file_flog_score(file)
  end

  def parse_summary_line(line)
    if line.match(/^(\d+)\)\s([a-z]+)\s.+(:[a-z]+)\s.+=\s(\d+)/i)
      return [$1, {match: $2, type: $3, score: $4, similarities: []}]
    end
    raise "invalid line: #{line.inspect}"
  end

  def parse_file_dup_line(line)
    if line.match(/(.+):(\d+)/)
      return {method_path: $1, line_number: $2, raw_line: line}
    end
    raise "invalid line: #{line.inspect}"
  end

  def parse_file_to_hash(file)
    result = {}
    current_number = ''
    file.each_line do |line|
      line.strip!
      next if line.empty?
      if line.match(/^(\d+)/)
        #puts line
        current_number, result[current_number] = parse_summary_line(line)
      elsif line.match(/Total score/)
        next
      else
        result[current_number][:similarities] << parse_file_dup_line(line)
      end
    end
    result
  end

  def similar_combinations(arr)
    rtn = {}
    arr.each do |item|
      rtn[item[:raw_line]] = arr.select{|i| i[:raw_line] != item[:raw_line]}
    end
    rtn
  end

  def duplication_number_hash_to_files(hsh)
    result = {}
    hsh.each do |number, match|
      similar_combinations(match[:similarities]).each do |raw_line, similar_to|
        next if result.has_key?(raw_line)
        result[raw_line] ||= {
          match: match[:match],
          type: match[:type],
          score: match[:score],
          similar_to: similar_to
        }
        similar_to.each do |similar_item|
          unless result[raw_line][:similar_to].include?(similar_item)
            result[raw_line][:similar_to] << similar_item 
          end
        end
      end
    end
    result
  end

  def build_file_flog_score(file)
    results_by_duplication_number = parse_file_to_hash(file)
    duplication_number_hash_to_files(results_by_duplication_number)
  end
end
