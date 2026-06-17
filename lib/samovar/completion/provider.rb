# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "result"
require_relative "suggestion"

module Samovar
	module Completion
		# Expands static, dynamic, and native completion providers.
		class Provider
			# Initialize a new completion provider.
			# 
			# @parameter context [Context] The completion context.
			# @parameter completions [Array | Proc | Symbol | Nil] The static, dynamic, or native completions.
			def initialize(context, completions)
				@context = context
				@completions = completions
			end
			
			# Generate suggestions from the provider.
			# 
			# @returns [Result] The matching completion suggestions.
			def suggestions
				case @completions
				when nil
					Result.new
				when Symbol
					native_suggestions
				else
					matching_suggestions
				end
			end
			
			protected
			
			# Generate matching suggestions from static or dynamic completions.
			#
			# @returns [Result] The matching completion suggestions.
			def matching_suggestions
				values = @completions
				
				if values.respond_to?(:call)
					values = values.call(@context)
				end
				
				values = Array(values).filter_map do |value|
					suggestion = Suggestion.wrap(value)
					
					suggestion if suggestion.start_with?(@context.current)
				end
				
				return Result.new(values)
			end
			
			# Generate native shell completion requests.
			# 
			# @returns [Result] The native completion request suggestions.
			def native_suggestions
				case @completions
				when :path, :file
					Result.new([Suggestion.new(@context.current, description: "Path", type: :path)])
				when :directory
					Result.new([Suggestion.new(@context.current, description: "Directory", type: :directory)])
				when :executable
					Result.new([Suggestion.new(@context.current, description: "Executable", type: :executable)])
				else
					Result.new
				end
			end
			
		end
	end
end
