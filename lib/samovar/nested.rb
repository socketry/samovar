# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require_relative "completion"

module Samovar
	# Represents nested sub-commands in a command.
	# 
	# A `Nested` parser allows you to define multiple sub-commands that can be invoked from the parent command.
	class Nested
		# Initialize a new nested command parser.
		# 
		# @parameter key [Symbol] The name of the attribute to store the selected command in.
		# @parameter commands [Hash] A mapping of command names to command classes.
		# @parameter default [String | Nil] The default command name if none is provided.
		# @parameter required [Boolean] Whether a command is required.
		def initialize(key, commands, default: nil, required: false)
			@key = key
			@commands = commands
			
			# This is the default name [of a command], not the default command:
			@default = default
			
			@required = required
		end
		
		# The name of the attribute to store the selected command in.
		# 
		# @attribute [Symbol]
		attr :key
		
		# A mapping of command names to command classes.
		# 
		# @attribute [Hash]
		attr :commands
		
		# The default command name if none is provided.
		# 
		# @attribute [String | Nil]
		attr :default
		
		# Whether a command is required.
		# 
		# @attribute [Boolean]
		attr :required
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The usage string.
		def to_s
			"<#{@key}>"
		end
		
		# Generate an array representation for usage output.
		# 
		# @returns [Array] The usage array.
		def to_a
			usage = [self.to_s]
			
			if @commands.size == 0
				usage << "No commands available."
			elsif @commands.size == 1
				usage << "Only #{@commands.first}."
			else
				usage << "One of: #{@commands.keys.join(', ')}."
			end
			
			if @default
				usage << "(default: #{@default})"
			elsif @required
				usage << "(required)"
			end
			
			return usage
		end
		
		# Parse a nested command from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @parameter parent [Command | Nil] The parent command.
		# @parameter default [Command | Nil] The default command instance.
		# @returns [Command | Object | Nil] The parsed command instance, or the default if no match.
		def parse(input, parent = nil, default = nil)
			if command = @commands[input.first]
				name = input.shift
				
				# puts "Instantiating #{command} with #{input}"
				command.new(input, name: name, parent: parent, output: parent&.output)
			elsif default
				return default
			elsif @default
				@commands[@default].new(input, name: @default, parent: parent, output: parent&.output)
			elsif @required
				raise MissingValueError.new(parent, @key)
			end
		end
		
		# Complete nested command names or continue into a selected command.
		# 
		# @parameter input [Array(String)] Previously completed command-line arguments.
		# @parameter context [Completion::Context] The completion context.
		# @parameter collected [Array(Completion::Suggestion)] Suggestions collected so far.
		# @returns [Completion::Result | Nil] A final completion result, or nil to continue.
		def complete(input, context, collected)
			if input.empty?
				result = suggestions(context)
				
				if result.empty? && @default
					return Completion::Result.new(collected) + context.complete_command(@commands.fetch(@default))
				end
				
				return Completion::Result.new(collected) + result
			end
			
			if command = @commands[input.first]
				input.shift
				return context.complete_command(command, input)
			elsif @default
				return context.complete_command(@commands.fetch(@default), input)
			else
				return Completion::Result.new(collected)
			end
		end
		
		def suggestions(context)
			suggestions = @commands.collect do |name, command_class|
				next unless name.start_with?(context.current)
				
				Completion::Suggestion.new(value: name, description: command_class.description, type: :command)
			end.compact
			
			Completion::Result.new(suggestions)
		end
		
		# Generate usage information for this nested command.
		# 
		# @parameter rows [Output::Rows] The rows to append usage information to.
		def usage(rows)
			rows << self
			
			@commands.each do |key, klass|
				klass.usage(rows, key)
			end
		end
	end
end
