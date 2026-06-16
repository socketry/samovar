# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require_relative "option"
require_relative "completion"

module Samovar
	# Represents a collection of command-line options.
	# 
	# Options provide a DSL for defining multiple option flags in a single block.
	class Options
		include Enumerable
		
		# Parse and create an options collection from a block.
		# 
		# @parameter arguments [Array] The arguments for the options collection.
		# @parameter options [Hash] Additional options.
		# @yields {|...| ...} A block that defines options using {#option}.
		# @returns [Options] The frozen options collection.
		def self.parse(*arguments, **options, &block)
			options = self.new(*arguments, **options)
			
			options.instance_eval(&block) if block_given?
			
			return options.freeze
		end
		
		# Initialize a new options collection.
		# 
		# @parameter title [String] The title for this options group in usage output.
		# @parameter key [Symbol] The key to use for storing parsed options.
		def initialize(title = "Options", key: :options)
			@title = title
			@ordered = []
			
			# We use this flag to option cache to improve parsing performance:
			@keyed = {}
			
			@key = key
			
			@defaults = {}
		end
		
		# Initialize a duplicate of this options collection.
		# 
		# @parameter source [Options] The source options to duplicate.
		def initialize_dup(source)
			super
			
			@ordered = @ordered.dup
			@keyed = @keyed.dup
			@defaults = @defaults.dup
		end
		
		# The title for this options group in usage output.
		# 
		# @attribute [String]
		attr :title
		
		# The ordered list of options.
		# 
		# @attribute [Array(Option)]
		attr :ordered
		
		# The key to use for storing parsed options.
		# 
		# @attribute [Symbol]
		attr :key
		
		# The default values for options.
		# 
		# @returns [Hash] The resolved default values.
		def defaults
			@defaults.transform_values(&:default)
		end
		
		# Freeze this options collection.
		# 
		# @returns [Options] The frozen options collection.
		def freeze
			return self if frozen?
			
			@ordered.freeze
			@keyed.freeze
			@defaults.freeze
			
			@ordered.each(&:freeze)
			
			super
		end
		
		# Iterate over each option.
		# 
		# @yields {|option| ...} Each option in the collection.
		def each(&block)
			@ordered.each(&block)
		end
		
		# Find the option that matches the given flag token.
		# 
		# @parameter token [String] The flag token to match.
		# @returns [Option | Nil] The matching option.
		def option_for(token)
			@keyed[token]
		end
		
		# The possible flag prefixes for completion.
		# 
		# @returns [Array(String)] The option flag prefixes and alternatives.
		def completions
			@ordered.flat_map{|option| option.flags.completions}
		end
		
		# Check if this options collection is empty.
		# 
		# @returns [Boolean] True if there are no options.
		def empty?
			@ordered.empty?
		end
		
		# Define a new option in this collection.
		# 
		# @parameter arguments [Array] The arguments for the option.
		# @parameter options [Hash] Additional options.
		# @yields {|value| ...} An optional block to transform the parsed value.
		def option(*arguments, **options, &block)
			self << Option.new(*arguments, **options, &block)
		end
		
		# Merge another options collection into this one.
		# 
		# @parameter options [Options] The options to merge.
		def merge!(options)
			options.each do |option|
				self << option
			end
		end
		
		# Add an option to this collection.
		# 
		# @parameter option [Option] The option to add.
		def << option
			@ordered << option
			option.flags.each do |flag|
				@keyed[flag.prefix] = option
				
				flag.alternatives.each do |alternative|
					@keyed[alternative] = option
				end
			end
			
			if option.default?
				@defaults[option.key] = option
			end
		end
		
		# Parse options from the input.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @parameter parent [Command | Nil] The parent command.
		# @parameter default [Hash | Nil] Default values to use.
		# @returns [Hash] The parsed option values.
		def parse(input, parent = nil, default = nil)
			values = (default || defaults).dup
			
			while option = @keyed[input.first]
				# prefix = input.first
				result = option.parse(input)
				if result != nil
					values[option.key] = result
				end
			end
			
			# Validate required options
			@ordered.each do |option|
				if option.required && !values.key?(option.key)
					raise MissingValueError.new(parent, option.key)
				end
			end
			
			return values
		end
		
		# Complete option flags or option values.
		# 
		# @parameter input [Array(String)] Previously completed command-line arguments.
		# @parameter context [Completion::Context] The completion context.
		# @parameter collected [Array(Completion::Suggestion)] Suggestions collected so far.
		# @returns [Completion::Result | Nil] A final completion result, or nil to continue.
		def complete(input, context, collected)
			result = consume(input, context)
			return result if result
			
			return nil unless input.empty?
			
			flags = suggestions(context.current)
			
			if context.current.start_with?("-") && flags.any?
				return Completion::Result.new(flags)
			elsif context.current.empty?
				collected.concat(flags)
				return nil
			end
			
			return nil
		end
		
		def consume(input, context)
			while token = input.first
				option = option_for(token)
				break unless option
				
				flag = option.flag_for(token)
				input.shift
				
				if flag && !flag.boolean?
					if input.any?
						input.shift
					else
						return option.suggestions(context, row: self)
					end
				end
			end
			
			return nil
		end
		
		def suggestions(prefix)
			flat_map do |option|
				option.flags.completions.collect do |value|
					next unless value.start_with?(prefix)
					
					Completion::Suggestion.new(value: value, description: option.description, type: :option)
				end
			end.compact
		end
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The usage string.
		def to_s
			@ordered.collect(&:to_s).join(" ")
		end
		
		# Generate usage information for this options collection.
		# 
		# @parameter rows [Output::Rows] The rows to append usage information to.
		def usage(rows)
			@ordered.each do |option|
				rows << option
			end
		end
	end
end
