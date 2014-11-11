require 'rubygems'
require 'flog'
require "flog_cli"

require 'yaml'

class FlogOutput
	def initialize(folders)
		flogger = FlogCLI.new(FlogCLI.parse_options(["-b", "-g"]))
		flogger.flog(folders)
		
		file = File.new('flog-output.txt', 'w+')
		flogger.report(file)
		file = File.open("flog-output.txt")

		@results = build_file_flog_score(file)
	end

	def flog_scores
		@results
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

require 'flay'

class FlayOutput
	def initialize(path)
		#files = Flay.expand_dirs_to_files(path)
		#flay = Flay.new
		#flay.process(*files)
		#file = File.new('flay-output.txt', 'w+')
		#flay.report(file)

		file = File.open("flay-output.txt")
		@results = build_file_flog_score(file)
	end

	def flay_scores
		@results
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
		#puts results_by_duplication_number.to_yaml
		duplication_number_hash_to_files(results_by_duplication_number)
	end
end

flay = FlayOutput.new('../g3')
puts flay.flay_scores.to_yaml

#score_hash 
#flog = FlogOutput.new(["../g3/lib", "../g3/app"])
#score_hash = flog.flog_scores
#puts score_hash.to_yaml