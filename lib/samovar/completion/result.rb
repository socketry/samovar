# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Samovar
	module Completion
		# A collection of completion suggestions.
		class Result
			include Enumerable
			
			# Initialize a new completion result.
			# 
			# @parameter suggestions [Array(Suggestion)] The suggestions in this result.
			def initialize(suggestions = [])
				@suggestions = suggestions
			end
			
			attr :suggestions
			
			alias candidates suggestions
			
			# Iterate over each suggestion.
			# 
			# @yields {|suggestion| ...} The block to call for each suggestion.
			def each(&block)
				@suggestions.each(&block)
			end
			
			# Whether this result contains no suggestions.
			# 
			# @returns [Boolean] True if there are no suggestions.
			def empty?
				@suggestions.empty?
			end
			
			# Combine this result with another result.
			# 
			# @parameter other [Result] The other result to append.
			# @returns [Result] The combined result.
			def +(other)
				self.class.new(@suggestions + other.suggestions)
			end
			
			# Print suggestions as tab-separated completion records.
			# 
			# @parameter output [IO] The output stream to write to.
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
