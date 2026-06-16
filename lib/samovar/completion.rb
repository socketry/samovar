# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "completion/context"
require_relative "completion/provider"
require_relative "completion/result"
require_relative "completion/suggestion"

module Samovar
	class Command
		# Complete the command-line input without executing the command.
		# 
		# @parameter input [Array(String)] The command-line arguments to complete.
		# @parameter environment [Hash] The environment for completion callbacks.
		# @parameter output [IO] The output stream for printing completion results.
		# @returns [Completion::Result] The completion result.
		def self.complete(input = ARGV, environment: ENV, output: $stdout)
			result = Completion.complete(self, input, environment: environment)
			result.print(output)
			
			return result
		end
	end
	
	# Shell completion support for Samovar commands.
	module Completion
		# Complete the command line for the given command class.
		# 
		# @parameter command_class [Class] The command class to complete.
		# @parameter argv [Array(String)] The application arguments.
		# @parameter environment [Hash] The environment for completion callbacks.
		# @returns [Result] The completion result.
		def self.complete(command_class, argv, environment: ENV)
			Context.for(command_class, argv, environment: environment).complete
		end
	end
end
