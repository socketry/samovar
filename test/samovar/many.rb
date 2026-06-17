# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "samovar/many"

describe Samovar::Many do
	let(:default) {["1", "2", "3"]}
	let(:input) {["2", "3", "--else"]}
	
	let(:many) {subject.new(:items, "some items", default: default)}
	
	it "has string representation" do
		expect(many.to_s).to be == "<items...>"
	end
	
	it "should have default" do
		expect(many.default).to be == default
	end
	
	it "should use default" do
		expect(many.parse([])).to be == default
	end
	
	it "should use specified default" do
		expect(many.parse([], nil, ["2"])).to be == ["2"]
	end
	
	it "should not use default if input specified" do
		expect(many.parse(input)).to be == ["2", "3"]
		expect(input).to be == ["--else"]
	end
	
	with "required field" do
		let(:required_many) {subject.new(:items, "some items", required: true)}
		
		it "raises error when required field is missing" do
			expect do
				required_many.parse([])
			end.to raise_exception(Samovar::MissingValueError)
		end
		
		it "includes required in usage" do
			usage = required_many.to_a
			expect(usage.join(" ")).to be(:include?, "required")
		end
	end
	
	with "default value" do
		it "includes default in usage" do
			usage = many.to_a
			expect(usage.join(" ")).to be(:include?, "default")
		end
	end
	
	with "no stop pattern" do
		let(:many_no_stop) {subject.new(:items, "all items", stop: nil)}
		let(:all_input) {["1", "2", "3", "--also"]}
		
		it "consumes all remaining input" do
			expect(many_no_stop.parse(all_input)).to be == ["1", "2", "3", "--also"]
			expect(all_input).to be(:empty?)
		end
		
		it "clears previous input before completing" do
			many_no_stop = subject.new(:items, "all items", stop: nil, completions: ["one", "two"])
			context = Samovar::Completion::Context.for(Samovar::Command, ["previous", "t"])
			input = ["previous"]
			
			result = many_no_stop.complete(input, context, [])
			
			expect(input).to be(:empty?)
			expect(result.collect(&:value)).to be == ["two"]
		end
	end
end
