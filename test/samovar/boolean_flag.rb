# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar/flags"

describe Samovar::BooleanFlag do
	let(:flag) {Samovar::Flag.parse("--[no]-color")}
	
	it "can check prefix" do
		expect(flag.prefix?("--color")).to be == true
		expect(flag.prefix?("--no-color")).to be == true
		expect(flag.prefix?("--other")).to be == false
	end
end
