# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require_relative "completion"

module Samovar
	# Represents a single positional argument in a command.
	# 
	# A `One` parser extracts exactly one argument from the command line that matches the specified pattern.
	class One
		# Initialize a new positional argument parser.
		# 
		# @parameter key [Symbol] The name of the attribute to store the value in.
		# @parameter description [String] A description of the argument for help output.
		# @parameter pattern [Regexp] A pattern to match valid values.
		# @parameter default [Object] The default value if no argument is provided.
		# @parameter required [Boolean] Whether the argument is required.
		# @parameter completions [Array | Proc | Nil] Completions for this argument.
		def initialize(key, description, pattern: //, default: nil, required: false, completions: nil)
			@key = key
			@description = description
			@pattern = pattern
			@default = default
			@required = required
			@completions = completions
		end
		
		# The name of the attribute to store the value in.
		# 
		# @attribute [Symbol]
		attr :key
		
		# A description of the argument for help output.
		# 
		# @attribute [String]
		attr :description
		
		# A pattern to match valid values.
		# 
		# @attribute [Regexp]
		attr :pattern
		
		# The default value if no argument is provided.
		# 
		# @attribute [Object]
		attr :default
		
		# Whether the argument is required.
		# 
		# @attribute [Boolean]
		attr :required
		
		# Completions for this argument.
		# 
		# @attribute [Array | Proc | Nil]
		attr :completions
		
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
			usage = [to_s, @description]
			
			if @default
				usage << "(default: #{@default.inspect})"
			elsif @required
				usage << "(required)"
			end
			
			return usage
		end
		
		# Parse a single argument from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @parameter parent [Command | Nil] The parent command.
		# @parameter default [Object | Nil] An override for the default value.
		# @returns [String | Object | Nil] The parsed value, or the default if no match.
		def parse(input, parent = nil, default = nil)
			if input.first =~ @pattern
				input.shift
			elsif default ||= @default
				return default
			elsif @required
				raise MissingValueError.new(parent, @key)
			end
		end
		
		# Complete this positional argument.
		# 
		# @parameter input [Array(String)] Previously completed command-line arguments.
		# @parameter context [Completion::Context] The completion context.
		# @parameter collected [Array(Completion::Suggestion)] Suggestions collected so far.
		# @returns [Completion::Result | Nil] A final completion result, or nil to continue.
		def complete(input, context, collected)
			if input.empty?
				return Completion::Result.new(collected) + Completion::Provider.new(@completions, context, row: self).suggestions
			elsif @pattern =~ input.first
				input.shift
				return nil
			else
				return Completion::Result.new(collected)
			end
		end
	end
end
