# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "result"

module Samovar
	module Completion
		# The context provided to dynamic completion callbacks.
		class Context
			# Build a context for a command class and argument list.
			#
			# @parameter command_class [Class] The command class to complete.
			# @parameter arguments [Array(String)] The truncated command-line arguments.
			# @parameter environment [Hash] The environment for completion callbacks.
			# @returns [Context] The completion context.
			def self.for(command_class, arguments, environment: ENV)
				return self.new(
					command_class.table.merged,
					arguments,
					arguments.last || "",
					environment: environment,
				)
			end
			
			# Initialize a new completion context.
			#
			# @parameter table [Table] The command table to complete.
			# @parameter arguments [Array(String)] The truncated command-line arguments.
			# @parameter current [String] The token being completed.
			# @parameter row [Object | Nil] The parser row whose value is being completed.
			# @parameter environment [Hash] The environment for completion callbacks.
			def initialize(table, arguments, current, row = nil, environment: ENV)
				@table = table
				@arguments = arguments
				@current = current
				@row = row
				@environment = environment
			end
			
			# @attribute [Table] The command table to complete.
			attr :table
			
			# @attribute [Array(String)] The truncated command-line arguments.
			attr :arguments
			
			# @attribute [String] The token being completed.
			attr :current
			
			# @attribute [Object | Nil] The parser row whose value is being completed.
			attr :row
			
			# @attribute [Hash] The environment for completion callbacks.
			attr :environment
			
			# Create a context for completing the given parser row.
			#
			# @parameter row [Object] The parser row whose value is being completed.
			# @returns [Context] The specialized completion context.
			def with_row(row)
				return self.class.new(
					@table,
					@arguments,
					@current,
					row,
					environment: @environment,
				)
			end
			
			# The completed words before the current token.
			#
			# @returns [Array(String)] The arguments before the token being completed.
			def words
				return [] if @arguments.empty?
				
				@arguments.take(@arguments.size - 1)
			end
			
			# Complete the current command class.
			#
			# @returns [Result] The completion result.
			def complete
				complete_rows(@table, words)
			end
			
			# Complete the given command class with completed words.
			#
			# @parameter command_class [Class] The command class to complete.
			# @parameter words [Array(String)] The completed words before the current token.
			# @returns [Result] The completion result.
			def complete_command(command_class, words = [])
				complete_rows(command_class.table.merged, words)
			end
			
			# Complete the rows in a command table.
			# The input array is mutable and may be consumed by parser rows.
			#
			# @parameter table [Table] The command table to complete.
			# @parameter input [Array(String)] The mutable completed words to consume.
			# @returns [Result] The completion result.
			def complete_rows(table, input)
				collected = []
				
				table.each do |row|
					if row.respond_to?(:complete)
						if result = row.complete(input, self, collected)
							return result
						end
					end
				end
				
				return Result.new(collected)
			end
		end
	end
end
