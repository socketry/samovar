# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "result"

module Samovar
	module Completion
		# The context provided to dynamic completion callbacks.
		Context = Struct.new(:command_class, :arguments, :current, :row, :option, :environment, keyword_init: true) do
			def self.for(command_class, arguments, environment: ENV)
				self.new(
					command_class: command_class,
					arguments: arguments,
					current: arguments.last || "",
					environment: environment,
				)
			end
			
			def words
				arguments.take(arguments.size - 1)
			end
			
			def complete
				complete_command(command_class, words)
			end
			
			def complete_command(command_class, words = [])
				complete_rows(command_class.table.merged, words.dup)
			end
			
			def complete_rows(table, input)
				collected = []
				
				table.each do |row|
					next unless row.respond_to?(:complete)
					
					result = row.complete(input, self, collected)
					return result if result
				end
				
				return Result.new(collected)
			end
		end
	end
end
