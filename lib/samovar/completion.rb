# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/completion"

module Samovar
	# Shell completion support for Samovar commands.
	module Completion
		Suggestion = ::Protocol::Completion::Candidate
		Result = ::Protocol::Completion::Result
		
		# The context provided to dynamic completion callbacks.
		Context = Struct.new(:command_class, :argv, :index, :current, :row, :option, :environment, keyword_init: true)
		
		# Complete the command line for the given command class.
		# 
		# @parameter command_class [Class] The command class to complete.
		# @parameter argv [Array(String)] The application arguments.
		# @parameter index [Integer] The zero-based application argument cursor index.
		# @parameter environment [Hash] The environment for completion callbacks.
		# @returns [Result] The completion result.
		def self.complete(command_class, argv, index:, environment: ENV)
			argv = argv.collect(&:to_s)
			index = Integer(index)
			
			if index < 0 || index > argv.size
				raise ArgumentError, "Completion index out of range: #{index}"
			end
			
			current = index < argv.size ? argv[index] : ""
			words = argv.take(index)
			
			context = Context.new(
				command_class: command_class,
				argv: argv,
				index: index,
				current: current,
				environment: environment,
			)
			
			complete_command(command_class, words, context)
		end
		
		def self.extract_index(environment = ENV)
			::Protocol::Completion::Index.extract(environment)
		end
		
		# Generate a shell completion script for an executable.
		# 
		# @parameter shell [String | Symbol] The shell name: bash, zsh, or fish.
		# @parameter executable [String] The executable name.
		# @returns [String] The shell completion script.
		def self.script(shell:, executable:)
			::Protocol::Completion::Shell.script(shell: shell, executable: executable)
		end
		
		def self.complete_command(command_class, words, context)
			complete_rows(command_class.table.merged, words.dup, context)
		end
		
		def self.complete_rows(table, input, context)
			collected = []
			
			table.each do |row|
				next unless row.respond_to?(:complete)
				
				result = row.complete(input, context, collected)
				return result if result
			end
			
			Result.new(collected)
		end
		
		def self.consume_options(options, input, context)
			while token = input.first
				option = options.option_for(token)
				break unless option
				
				flag = option.flag_for(token)
				input.shift
				
				if flag && !flag.boolean?
					if input.any?
						input.shift
					else
						return option_value_suggestions(option, context, row: options)
					end
				end
			end
			
			nil
		end
		
		def self.option_suggestions(options, prefix)
			options.flat_map do |option|
				option.flags.completions.collect do |value|
					next unless value.start_with?(prefix)
					
					Suggestion.new(value: value, description: option.description, type: :option)
				end
			end.compact
		end
		
		def self.nested_suggestions(nested, context)
			suggestions = nested.commands.collect do |name, command_class|
				next unless name.start_with?(context.current)
				
				Suggestion.new(value: name, description: command_class.description, type: :command)
			end.compact
			
			Result.new(suggestions)
		end
		
		def self.option_value_suggestions(option, context, row:)
			suggestions = []
			
			if option.default?
				suggestion = wrap_suggestion(option.default)
				
				suggestions << suggestion if suggestion.value.to_s.start_with?(context.current)
			end
			
			(result = provider_suggestions(option.completions, context, row: row, option: option)).each do |suggestion|
				suggestions << suggestion unless suggestions.any?{|existing| existing.value == suggestion.value}
			end
			
			Result.new(suggestions)
		end
		
		def self.provider_suggestions(provider, context, row:, option: nil)
			return Result.new unless provider
			
			context = context.dup
			context.row = row
			context.option = option
			
			values = provider.respond_to?(:call) ? provider.call(context) : provider
			
			Result.new(Array(values).filter_map do |value|
				suggestion = wrap_suggestion(value)
				
				suggestion if suggestion.value.to_s.start_with?(context.current)
			end)
		end
		
		def self.wrap_suggestion(value)
			case value
			when Suggestion
				value
			when Hash
				Suggestion.new(**value)
			else
				Suggestion.new(value: value)
			end
		end
		
		def self.command_name(executable)
			::Protocol::Completion::Shell.command_name(executable)
		end
	end
end
