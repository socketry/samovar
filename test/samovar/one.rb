# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "samovar/many"

describe Samovar::One do
	let(:default) {"1"}
	let(:input) {["2", "3", "4"]}
	
	let(:one) {subject.new(:thing, "a thing", default: default)}
	
	it "has string representation" do
		expect(one.to_s).to be == "<thing>"
	end
	
	it "should have default" do
		expect(one.default).to be == default
	end
	
	it "should use default" do
		expect(one.parse([])).to be == default
	end
	
	it "should use specified default" do
		expect(one.parse([], nil, "2")).to be == "2"
	end
	
	it "should not use default if input specified" do
		expect(one.parse(input)).to be == "2"
		expect(input).to be == ["3", "4"]
	end
	
	it "completes with no suggestions if input does not match" do
		one = subject.new(:thing, "a thing", pattern: /^valid$/, completions: ["valid"])
		context = Samovar::Completion::Context.for(Samovar::Command, ["invalid", ""])
		
		result = one.complete(["invalid"], context, [])
		
		expect(result).to be(:empty?)
	end
	
	with "required field" do
		let(:required_one) {subject.new(:thing, "a thing", required: true)}
		
		it "raises error when required field is missing" do
			expect do
				required_one.parse([])
			end.to raise_exception(Samovar::MissingValueError)
		end
		
		it "includes required in usage" do
			usage = required_one.to_a
			expect(usage.join(" ")).to be(:include?, "required")
		end
	end
	
	with "default value" do
		it "includes default in usage" do
			usage = one.to_a
			expect(usage.join(" ")).to be(:include?, "default")
		end
	end
end
