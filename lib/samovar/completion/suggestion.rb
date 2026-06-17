# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Samovar
	module Completion
		# A single completion suggestion.
		class Suggestion
			# Wrap a raw completion value in a suggestion.
			#
			# @parameter value [Suggestion | Hash | Object] The value to wrap.
			# @returns [Suggestion] The normalized suggestion.
			def self.wrap(value)
				case value
				when self
					return value
				when Hash
					value = value.dup
					suggestion = value.fetch(:value)
					value.delete(:value)
					
					return self.new(suggestion, **value)
				else
					return self.new(value)
				end
			end
			
			# Initialize a new completion suggestion.
			#
			# @parameter value [Object] The completion value.
			# @parameter type [Symbol | String | Nil] The completion type.
			# @parameter description [String | Nil] The completion description.
			# @parameter options [Hash] Additional completion metadata.
			def initialize(value, type: nil, description: nil, **options)
				@type = type
				@value = value
				@description = description
				@options = options
			end
			
			# @attribute [Symbol | String | Nil] The completion type.
			attr :type
			
			# @attribute [Object] The completion value.
			attr :value
			
			# @attribute [String | Nil] The completion description.
			attr :description
			
			# @attribute [Hash] Additional completion metadata.
			attr :options
			
			# Whether this suggestion starts with the given prefix.
			#
			# @parameter prefix [String] The prefix to check.
			# @returns [Boolean] True if the suggestion starts with the given prefix.
			def start_with?(prefix)
				to_s.start_with?(prefix)
			end
			
			# Convert the suggestion to a tab-separated completion record.
			#
			# @returns [String] The escaped completion record.
			def to_record
				fields = [
					escape(@type),
					escape(@value),
					escape(@description),
				]
				@options.each do |key, value|
					next if value.nil?
					
					fields << "#{escape(key)}=#{escape(value)}"
				end
				
				return fields.join("\t")
			end
			
			# Convert the suggestion to its value.
			#
			# @returns [String] The suggestion value.
			def to_s
				@value.to_s
			end
			
			private
			
			def escape(value)
				value.to_s.gsub(/[\t\r\n]/, " ")
			end
		end
	end
end
