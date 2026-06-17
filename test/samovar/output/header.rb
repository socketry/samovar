# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "samovar"
require "samovar/output/header"

describe Samovar::Output::Header do
	let(:command_class) do
		Class.new(Samovar::Command) do
			self.description = "Test command"
			
			options do
				option "--help", "Show help"
			end
		end
	end
	
	it "can align header" do
		header = Samovar::Output::Header.new("test", command_class)
		result = header.align(nil)
		
		expect(result).to be(:include?, "test")
	end
end
