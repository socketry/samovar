# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require_relative "completion"

module Samovar
	# Represents a split point in the command-line arguments.
	# 
	# A `Split` parser divides the argument list at a marker (typically `--`), allowing you to separate arguments meant for your command from those passed to another tool.
	class Split
		# Initialize a new split parser.
		# 
		# @parameter key [Symbol] The name of the attribute to store the values after the split.
		# @parameter description [String] A description of the split for help output.
		# @parameter marker [String] The marker that indicates the split point.
		# @parameter default [Object] The default value if no split is present.
		# @parameter required [Boolean] Whether the split is required.
		# @parameter completions [Array | Proc | Nil] Completions for split arguments.
		def initialize(key, description, marker: "--", default: nil, required: false, completions: nil)
			@key = key
			@description = description
			@marker = marker
			@default = default
			@required = required
			@completions = completions
		end
		
		# The name of the attribute to store the values after the split.
		# 
		# @attribute [Symbol]
		attr :key
		
		# A description of the split for help output.
		# 
		# @attribute [String]
		attr :description
		
		# The marker that indicates the split point.
		# 
		# @attribute [String]
		attr :marker
		
		# The default value if no split is present.
		# 
		# @attribute [Object]
		attr :default
		
		# Whether the split is required.
		# 
		# @attribute [Boolean]
		attr :required
		
		# Completions for split arguments.
		# 
		# @attribute [Array | Proc | Nil]
		attr :completions
		
		# Generate a string representation for usage output.
		# 
		# @returns [String] The usage string.
		def to_s
			"#{@marker} <#{@key}...>"
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
		
		# Parse arguments after the split marker.
		# 
		# @parameter input [Array(String)] The command-line arguments.
		# @parameter parent [Command | Nil] The parent command.
		# @parameter default [Object | Nil] An override for the default value.
		# @returns [Array(String) | Object | Nil] The arguments after the split, or the default if no split.
		def parse(input, parent = nil, default = nil)
			if offset = input.index(@marker)
				input.pop(input.size - offset).tap(&:shift)
			elsif default ||= @default
				return default
			elsif @required
				raise MissingValueError.new(parent, @key)
			end
		end
		
		# Complete the split marker or arguments after it.
		# 
		# @parameter input [Array(String)] Previously completed command-line arguments.
		# @parameter context [Completion::Context] The completion context.
		# @parameter collected [Array(Completion::Suggestion)] Suggestions collected so far.
		# @returns [Completion::Result | Nil] A final completion result, or nil to continue.
		def complete(input, context, collected)
			if offset = input.index(@marker)
				input.shift(offset + 1)
				return Completion::Result.new(collected) + Completion::Provider.new(@completions, context, row: self).suggestions
			end
			
			return Completion::Result.new(collected) unless input.empty?
			
			suggestions = []
			
			if @marker.start_with?(context.current)
				suggestions << Completion::Suggestion.new(value: @marker, description: @description, type: :split)
			end
			
			Completion::Result.new(collected + suggestions)
		end
	end
end
