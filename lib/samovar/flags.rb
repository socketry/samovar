# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

module Samovar
	# Represents a collection of flag alternatives for an option.
	# 
	# Flags parse text like `-f/--flag <value>` into individual flag parsers.
	class Flags
		include Enumerable
		
		# Initialize a new flags parser.
		# 
		# @parameter text [String] The flags specification string (e.g., `-f/--flag <value>`).
		def initialize(text)
			@text = text
			
			@ordered = text.split(/\s+\|\s+/).map{|part| Flag.parse(part)}
		end
		
		# Iterate over each flag.
		# 
		# @yields {|flag| ...} Each flag in the collection.
		def each(&block)
			@ordered.each(&block)
		end
		
		# Find the flag that matches the given token.
		# 
		# @parameter token [String] The token to match.
		# @returns [Flag | Nil] The matching flag.
		def flag_for(token)
			@ordered.find{|flag| flag.prefix?(token)}
		end
		
		# The possible flag prefixes for completion.
		# 
		# @returns [Array(String)] The flag prefixes and alternatives.
		def completions
			@ordered.flat_map(&:completions)
		end
		
		# Get the first flag.
		# 
		# @returns [Flag] The first flag.
		def first
			@ordered.first
		end
		
		# Whether this flag should have a true/false value if not specified otherwise.
		# 
		# @returns [Boolean] True if this is a boolean flag.
		def boolean?
			@ordered.count == 1 and @ordered.first.boolean?
		end
		
		# The number of flag alternatives.
		# 
		# @returns [Integer] The count of flags.
		def count
			return @ordered.count
		end
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The usage string.
		def to_s
			"[#{@ordered.join(' | ')}]"
		end
		
		# Parse a flag from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @returns [Object | Nil] The parsed value, or nil if no match.
		def parse(input)
			@ordered.each do |flag|
				result = flag.parse(input)
				if result != nil
					return result
				end
			end
			
			return nil
		end
	end
	
	# Represents a single command-line flag.
	# 
	# A flag can be a simple boolean flag or a flag that accepts a value.
	class Flag
		# Parse a flag specification string into a flag instance.
		# 
		# @parameter text [String] The flag specification (e.g., `-f <value>` or `--flag`).
		# @returns [Flag] A flag instance (either {ValueFlag} or {BooleanFlag}).
		def self.parse(text)
			if text =~ /(.*?)\s(\<.*?\>)/
				ValueFlag.new(text, $1, $2)
			elsif text =~ /--\[no\]-(.*?)$/
				BooleanFlag.new(text, "--#{$1}")
			else
				ValueFlag.new(text, text, nil)
			end
		end
		
		# Initialize a new flag.
		# 
		# @parameter text [String] The full flag specification text.
		# @parameter prefix [String] The primary flag prefix (e.g., `--flag`).
		# @parameter alternatives [Array(String) | Nil] Alternative flag prefixes.
		def initialize(text, prefix, alternatives = nil)
			@text = text
			@prefix = prefix
			@alternatives = alternatives
		end
		
		# The full flag specification text.
		# 
		# @attribute [String]
		attr :text
		
		# The primary flag prefix.
		# 
		# @attribute [String]
		attr :prefix
		
		# Alternative flag prefixes.
		# 
		# @attribute [Array(String) | Nil]
		attr :alternatives
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The flag text.
		def to_s
			@text
		end
		
		# Generate a key name for this flag.
		# 
		# @returns [Symbol] The key name.
		def key
			@key ||= @prefix.sub(/^-*/, "").gsub("-", "_").to_sym
		end
		
		# Whether this is a boolean flag.
		# 
		# @returns [Boolean] False by default.
		def boolean?
			false
		end
		
		# Check if the token matches this flag.
		# 
		# @parameter token [String] The token to check.
		# @returns [Boolean] True if the token matches.
		def prefix?(token)
			@prefix == token or @alternatives&.include?(token)
		end
		
		# The possible flag prefixes for completion.
		# 
		# @returns [Array(String)] The flag prefix and alternatives.
		def completions
			[@prefix, *@alternatives]
		end
	end
	
	# Represents a flag that accepts a value or acts as a boolean.
	class ValueFlag < Flag
		# Initialize a new value flag.
		# 
		# @parameter text [String] The full flag specification text.
		# @parameter prefix [String] The primary flag prefix with alternatives (e.g., `-f/--flag`).
		# @parameter value [String | Nil] The value placeholder (e.g., `<file>`).
		def initialize(text, prefix, value)
			super(text, prefix)
			
			@value = value
			
			*@alternatives, @prefix = @prefix.split("/")
		end
		
		# Alternative flag prefixes.
		# 
		# @attribute [Array(String)]
		attr :alternatives
		
		# The value placeholder.
		# 
		# @attribute [String | Nil]
		attr :value
		
		# Whether this is a boolean flag (no value required).
		# 
		# @returns [Boolean] True if no value is required.
		def boolean?
			@value.nil?
		end
		
		# Check if the token matches this flag.
		# 
		# @parameter token [String] The token to check.
		# @returns [Boolean] True if the token matches.
		def prefix?(token)
			@prefix == token or @alternatives.include?(token)
		end
		
		# Parse this flag from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @returns [String | Symbol | Nil] The parsed value.
		def parse(input)
			if prefix?(input.first)
				# Whether we are expecting to parse a value from input:
				if @value
					# Get the actual value from input:
					flag, value = input.shift(2)
					return value
				else
					# Otherwise, we are just a boolean flag:
					input.shift
					return key
				end
			end
		end
	end
	
	# Represents a boolean flag with `--flag` and `--no-flag` variants.
	class BooleanFlag < Flag
		# Initialize a new boolean flag.
		# 
		# @parameter text [String] The full flag specification text.
		# @parameter prefix [String] The primary flag prefix (e.g., `--flag`).
		# @parameter value [Object | Nil] Reserved for future use.
		def initialize(text, prefix, value = nil)
			super(text, prefix)
			
			@value = value
			
			@negated = @prefix.sub(/^--/, "--no-")
			@alternatives = [@negated]
		end
		
		# Check if the token matches this flag.
		# 
		# @parameter token [String] The token to check.
		# @returns [Boolean] True if the token matches.
		def prefix?(token)
			@prefix == token or @negated == token
		end
		
		# Parse this flag from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @returns [Boolean | Nil] True, false, or nil.
		def parse(input)
			if input.first == @prefix
				input.shift
				return true
			elsif input.first == @negated
				input.shift
				return false
			end
		end
	end
end
