# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Samovar
	module Completion
		# A collection of completion suggestions.
		class Result
			include Enumerable
			
			def initialize(suggestions = [])
				@suggestions = suggestions
			end
			
			attr :suggestions
			
			alias candidates suggestions
			
			def each(&block)
				@suggestions.each(&block)
			end
			
			def empty?
				@suggestions.empty?
			end
			
			def +(other)
				self.class.new(@suggestions + other.suggestions)
			end
			
			def print(output = $stdout)
				each do |suggestion|
					output.puts [
						escape(suggestion.type),
						escape(suggestion.value),
						escape(suggestion.description),
					].join("\t")
				end
			end
			
			private
			
			def escape(value)
				value.to_s.gsub(/[\t\r\n]/, " ")
			end
		end
	end
end
