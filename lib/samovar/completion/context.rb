# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "result"

module Samovar
	module Completion
		# The context provided to dynamic completion callbacks.
		Context = Struct.new(:command_class, :arguments, :current, :row, :option, :environment, keyword_init: true) do
			# Build a context for a command class and argument list.
			# 
			# @parameter command_class [Class] The command class being completed.
			# @parameter arguments [Array(String)] The truncated command-line arguments.
			# @parameter environment [Hash] The environment for completion callbacks.
			# @returns [Context] The completion context.
			def self.for(command_class, arguments, environment: ENV)
				self.new(
					command_class: command_class,
					arguments: arguments,
					current: arguments.last || "",
					environment: environment,
				)
			end
			
			# The completed words before the current token.
			# 
			# @returns [Array(String)] The arguments before the token being completed.
			def words
				arguments.take(arguments.size - 1)
			end
			
			# Complete the current command class.
			# 
			# @returns [Result] The completion result.
			def complete
				complete_command(command_class, words)
			end
			
			# Complete the given command class with completed words.
			# 
			# @parameter command_class [Class] The command class to complete.
			# @parameter words [Array(String)] The completed words before the current token.
			# @returns [Result] The completion result.
			def complete_command(command_class, words = [])
				complete_rows(command_class.table.merged, words.dup)
			end
			
			# Complete the rows in a command table.
			# 
			# @parameter table [Table] The command table to complete.
			# @parameter input [Array(String)] The mutable completed words to consume.
			# @returns [Result] The completion result.
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
