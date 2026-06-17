# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "samovar"

class InnerA < Samovar::Command
	options
end

class InnerB < InnerA
	options do
		option "--help", "Do you need it?"
	end
end

class InnerC < InnerB
	options do
		option "--frobulate", "Zork is waiting for you."
	end
end

class Outer < Samovar::Command
	options do
	end
	
	nested :command, {
		"inner-a" => InnerA,
		"inner-b" => InnerB,
		"inner-c" => InnerC,
	}, default: "inner-b"
end

describe Samovar::Nested do
	let(:commands) do
		{
			"inner-a" => Class.new(Samovar::Command),
			"inner-b" => Class.new(Samovar::Command),
		}
	end
	
	let(:default) {"inner-a"}
	let(:input) {["inner-a"]}
	let(:nested) {subject.new(:command, commands, default: default)}
	
	it "has string representation" do
		expect(nested.to_s).to be == "<command>"
	end
	
	it "should have default" do
		expect(nested.default).to be == default
	end
	
	it "should use default" do
		expect(nested.parse([])).to be_a commands[default]
	end
	
	it "should use specified default" do
		command = commands["inner-b"].new
		
		expect(nested.parse([], nil, command)).to be_equal(command)
	end
	
	it "should not use default if input specified" do
		expect(nested.parse(input)).to be_a commands["inner-a"]
	end
	
	with "required field" do
		let(:required_nested) {subject.new(:command, commands, required: true)}
		
		it "raises error when required field is missing" do
			expect do
				required_nested.parse([])
			end.to raise_exception(Samovar::MissingValueError)
		end
		
		it "includes required in usage" do
			usage = required_nested.to_a
			expect(usage.join(" ")).to be(:include?, "required")
		end
	end
	
	with "default value" do
		it "includes default in usage" do
			usage = nested.to_a
			expect(usage.join(" ")).to be(:include?, "default")
		end
	end
	
	with "single command" do
		let(:single_commands) {{ "only" => Class.new(Samovar::Command) }}
		let(:single_nested) {subject.new(:command, single_commands)}
		
		it "shows single command in usage" do
			usage = single_nested.to_a
			expect(usage.join(" ")).to be(:include?, "Only")
		end
	end
	
	with "multiple commands" do
		it "shows command list in usage" do
			usage = nested.to_a
			expect(usage.join(" ")).to be(:include?, "inner-a, inner-b")
		end
	end
	
	with "no commands" do
		let(:empty_nested) {subject.new(:command, {})}
		
		it "shows no commands message in usage" do
			usage = empty_nested.to_a
			expect(usage.join(" ")).to be(:include?, "No commands available")
		end
	end
	
	it "should select default nested command" do
		outer = Outer[]
		expect(outer.command).to be_a(InnerB)
	end
	
	it "should select explicitly named nested command" do
		outer = Outer["inner-a"]
		expect(outer.command).to be_a(InnerA)
	end
	
	it "can parse derived options" do
		outer = Outer["inner-c", "--help"]
		expect(outer.command).to be_a(InnerC)
		expect(outer.command.options).to have_keys(help: be == true)
		expect(outer.command.parent).to be_equal(outer)
	end
	
	it "passes output to nested commands" do
		output = StringIO.new
		outer = Outer.new(["inner-a"], output: output)
		
		expect(outer.command.output).to be_equal(output)
	end
	
	# it "should parse help option at outer level" do
	# 	outer = Outer['inner-a', '--help']
	# 	expect(outer.options[:help]).to_be truthy
	# end
end
