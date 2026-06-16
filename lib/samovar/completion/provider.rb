# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "result"
require_relative "suggestion"

module Samovar
	module Completion
		# Expands static, dynamic, and native completion providers.
		class Provider
			def initialize(provider, context, row:, option: nil)
				@provider = provider
				@context = context
				@row = row
				@option = option
			end
			
			def suggestions
				return Result.new unless @provider
				return native_suggestions if @provider.is_a?(Symbol)
				
				context = @context.dup
				context.row = @row
				context.option = @option
				
				values = @provider.respond_to?(:call) ? @provider.call(context) : @provider
				
				Result.new(Array(values).filter_map do |value|
					suggestion = wrap(value)
					
					suggestion if suggestion.value.to_s.start_with?(@context.current)
				end)
			end
			
			def native_suggestions
				case @provider
				when :path, :file
					Result.new([Suggestion.new(value: @context.current, description: "Path", type: :path)])
				when :directory
					Result.new([Suggestion.new(value: @context.current, description: "Directory", type: :directory)])
				else
					Result.new
				end
			end
			
			def wrap(value)
				case value
				when Suggestion
					value
				when Hash
					Suggestion.new(**value)
				else
					Suggestion.new(value: value)
				end
			end
		end
	end
end
