# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar/flags"

describe Samovar::Flag do
	let(:flag) {subject.new("--flag", "--flag", ["-f"])}
	
	it "can check alternatives" do
		expect(flag.prefix?("-f")).to be == true
	end
end
