# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "flags"
require_relative "error"
require_relative "completion/provider"
require_relative "completion/result"

module Samovar
	# Represents a single command-line option.
	# 
	# An option is a flag-based argument that can have various forms (short, long, with or without values).
	class Option
		# Initialize a new option.
		# 
		# @parameter flags [String] The flags specification (e.g., `-f/--flag <value>`).
		# @parameter description [String] A description of the option for help output.
		# @parameter key [Symbol | Nil] The key to use for storing the value (defaults to derived from flag).
		# @parameter default [Object] The default value if the option is not provided.
		# @parameter value [Object | Nil] A fixed value to use regardless of user input.
		# @parameter type [Class | Proc | Nil] The type to coerce the value to.
		# @parameter required [Boolean] Whether the option is required.
		# @parameter completions [Array | Proc | Nil] Completions for option values.
		# @yields {|value| ...} An optional block to transform the parsed value.
		def initialize(flags, description, key: nil, default: nil, value: nil, type: nil, required: false, completions: nil, &block)
			@flags = Flags.new(flags)
			@description = description
			
			if key
				@key = key
			else
				@key = @flags.first.key
			end
			
			@default = default
			
			# If the value is given, it overrides the user specified input.
			@value = value
			@value ||= true if @flags.boolean?
			
			@type = type
			@required = required
			@completions = completions
			@block = block
		end
		
		# The flags for this option.
		# 
		# @attribute [Flags]
		attr :flags
		
		# A description of the option for help output.
		# 
		# @attribute [String]
		attr :description
		
		# The key to use for storing the value.
		# 
		# @attribute [Symbol]
		attr :key
		
		# The default value if the option is not provided.
		# 
		# @returns [Object | Nil] The resolved default value.
		def default
			if @default.respond_to?(:call)
				@default.call
			else
				@default
			end
		end
		
		# Whether this option has a default value.
		# 
		# @returns [Boolean] True if the option has a default value.
		def default?
			!@default.nil?
		end
		
		# A fixed value to use regardless of user input.
		# 
		# @attribute [Object | Nil]
		attr :value
		
		# The type to coerce the value to.
		# 
		# @attribute [Class | Proc | Nil]
		attr :type
		
		# Whether the option is required.
		# 
		# @attribute [Boolean]
		attr :required
		
		# Completions for option values.
		# 
		# @attribute [Array | Proc | Nil]
		attr :completions
		
		# An optional block to transform the parsed value.
		# 
		# @attribute [Proc | Nil]
		attr :block
		
		# Find the flag that matches the given token.
		# 
		# @parameter token [String] The token to match.
		# @returns [Flag | Nil] The matching flag.
		def flag_for(token)
			@flags.flag_for(token)
		end
		
		# Whether this option consumes a value after the flag.
		# 
		# @returns [Boolean] True if any flag for this option consumes a value.
		def value?
			@flags.any?{|flag| !flag.boolean?}
		end
		
		# Complete values for this option.
		# 
		# @parameter context [Completion::Context] The completion context.
		# @parameter row [Object] The parser row requesting completions.
		# @returns [Completion::Result] The matching option value completions.
		def suggestions(context, row:)
			suggestions = []
			
			if default?
				suggestion = Completion::Provider.new([default], context, row: row, option: self).suggestions.first
				
				suggestions << suggestion if suggestion
			end
			
			Completion::Provider.new(@completions, context, row: row, option: self).suggestions.each do |suggestion|
				suggestions << suggestion unless suggestions.any?{|existing| existing.value == suggestion.value}
			end
			
			Completion::Result.new(suggestions)
		end
		
		# Coerce the result to the specified type.
		# 
		# @parameter result [Object] The value to coerce.
		# @returns [Object] The coerced value.
		def coerce_type(result)
			if @type == Integer
				Integer(result)
			elsif @type == Float
				Float(result)
			elsif @type == Symbol
				result.to_sym
			elsif @type.respond_to? :call
				@type.call(result)
			elsif @type.respond_to? :new
				@type.new(result)
			end
		end
		
		# Coerce and transform the result.
		# 
		# @parameter result [Object] The value to coerce and transform.
		# @returns [Object] The coerced and transformed value.
		def coerce(result)
			if @type
				result = coerce_type(result)
			end
			
			if @block
				result = @block.call(result)
			end
			
			return result
		end
		
		# Parse this option from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @parameter parent [Command | Nil] The parent command (unused, kept for compatibility).
		# @parameter default [Object | Nil] An override for the default value (unused, kept for compatibility).
		# @returns [Object | Nil] The parsed value.
		def parse(input, parent = nil, default = nil)
			result = @flags.parse(input)
			
			if result != nil
				@value.nil? ? coerce(result) : @value
			end
		end
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The usage string.
		def to_s
			@flags
		end
		
		# Generate an array representation for usage output.
		# 
		# @returns [Array] The usage array.
		def to_a
			if default?
				[@flags, @description, "(default: #{default})"]
			elsif @required
				[@flags, @description, "(required)"]
			else
				[@flags, @description]
			end
		end
	end
end
