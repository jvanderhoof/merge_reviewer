require 'flog'
require "flog_cli"


class Flogger < Analyzer
  def initialize(folders)
    flogger = FlogCLI.new(FlogCLI.parse_options(["-b", "-g"]))
    flogger.flog(folders)
    
    file = File.new('flog-output.txt', 'w+')
    flogger.report(file)
    file = File.open("flog-output.txt")

    @results = build_file_flog_score(file)
  end

  def set_class_flog_total(class_name, score)
    @class_flog_scores ||= {}
    @class_flog_scores[class_name] = score
  end

  def get_class_flog_total(class_name)
    @class_flog_scores[class_name]
  end

  def line_to_parts(line, mapper)   
    line.strip!
    return mapper if line.empty?
    if line.match(/(\d+\.\d+):\s(.+)\stotal/)
      class_score, class_name = $1.to_f, $2
      set_class_flog_total(class_name, class_score)
    elsif line.match(/(\d+\.\d+):\s+(.+)#(.+)\s+(.+):(\d+)/)
      method_score, class_name, method_name, method_path, line_number = $1.to_f, $2, $3, $4, $5
      mapper[method_path] ||= {
        class_name: class_name, 
        class_score: get_class_flog_total(class_name), 
        problems: []
      }
      mapper[method_path][:problems] << {
        method_score: method_score,
        method_name: method_name,
        line_number: line_number
      }
    end
    mapper
  end

  def build_file_flog_score(file)
    mapper = {}
    file.each_line do |line|
      mapper = line_to_parts(line, mapper)
    end
    mapper
  end
end
