# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require_relative "completion"

module Samovar
	# Represents multiple positional arguments in a command.
	# 
	# A `Many` parser extracts all arguments from the command line until it encounters a stop pattern (typically an option flag).
	class Many
		# Initialize a new multi-argument parser.
		# 
		# @parameter key [Symbol] The name of the attribute to store the values in.
		# @parameter description [String | Nil] A description of the arguments for help output.
		# @parameter stop [Regexp] A pattern that indicates the end of this argument list.
		# @parameter default [Object] The default value if no arguments are provided.
		# @parameter required [Boolean] Whether at least one argument is required.
		# @parameter completions [Array | Proc | Nil] Completions for these arguments.
		def initialize(key, description = nil, stop: /^-/, default: nil, required: false, completions: nil)
			@key = key
			@description = description
			@stop = stop
			@default = default
			@required = required
			@completions = completions
		end
		
		# The name of the attribute to store the values in.
		# 
		# @attribute [Symbol]
		attr :key
		
		# A description of the arguments for help output.
		# 
		# @attribute [String | Nil]
		attr :description
		
		# A pattern that indicates the end of this argument list.
		# 
		# @attribute [Regexp]
		attr :stop
		
		# The default value if no arguments are provided.
		# 
		# @attribute [Object]
		attr :default
		
		# Whether at least one argument is required.
		# 
		# @attribute [Boolean]
		attr :required
		
		# Completions for these arguments.
		# 
		# @attribute [Array | Proc | Nil]
		attr :completions
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The usage string.
		def to_s
			"<#{key}...>"
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
		
		# Parse multiple arguments from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @parameter parent [Command | Nil] The parent command.
		# @parameter default [Object | Nil] An override for the default value.
		# @returns [Array(String) | Object | Nil] The parsed values, or the default if none match.
		def parse(input, parent = nil, default = nil)
			if @stop and stop_index = input.index{|item| @stop === item}
				input.shift(stop_index)
			elsif input.any?
				input.shift(input.size)
			elsif default ||= @default
				return default
			elsif @required
				raise MissingValueError.new(parent, @key)
			end
		end
		
		# Complete this repeating positional argument.
		# 
		# @parameter input [Array(String)] Previously completed command-line arguments.
		# @parameter context [Completion::Context] The completion context.
		# @parameter collected [Array(Completion::Suggestion)] Suggestions collected so far.
		# @returns [Completion::Result | Nil] A final completion result, or nil to continue.
		def complete(input, context, collected)
			if @stop
				input.shift while input.any? && !(@stop === input.first)
				
				return nil if @stop === context.current
			else
				input.clear
			end
			
			if input.empty?
				return Completion::Result.new(collected) + Completion::Provider.new(@completions, context, row: self).suggestions
			end
			
			return nil
		end
	end
end
