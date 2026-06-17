# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "samovar"

describe Samovar::Options do
	let(:options) do
		subject.parse do
			option "-x <value>", "The x factor", default: 2
			option "-y <value>", "The y factor"
			
			option "--symbol <value>", "A symbol", type: Symbol
		end
	end
	
	it "should set defaults" do
		values = options.parse([], nil, nil)
		expect(values).to be == {x: 2}
	end
	
	it "should resolve callable defaults" do
		count = 0
		
		options = subject.parse do
			option "--value <value>", "The value", default: ->{count += 1}
		end
		
		expect(options.parse([], nil, nil)).to be == {value: 1}
		expect(options.parse([], nil, nil)).to be == {value: 2}
	end
	
	it "should preserve false defaults" do
		options = subject.parse do
			option "--enabled", "Whether enabled", default: false
		end
		
		expect(options.parse([], nil, nil)).to be == {enabled: false}
	end
	
	it "should preserve current values" do
		values = options.parse([], nil, {x: 1, y: 2, z: 3})
		expect(values).to be == {x: 1, y: 2, z: 3}
	end
	
	it "should update specified values" do
		values = options.parse(["-x", 10], nil, {x: 1, y: 2, z: 3})
		expect(values).to be == {x: 10, y: 2, z: 3}
	end
	
	it "converts to symbol" do
		values = options.parse(["--symbol", "thing"], {})
		expect(values[:symbol]).to be == :thing
	end
	
	with "required option" do
		let(:required_options) do
			subject.parse do
				option "-r <value>", "Required value", required: true
			end
		end
		
		let(:command_class) do
			Class.new(Samovar::Command) do
				self.description = "A command with required options."
				
				options do
					option "--config <path>", "The configuration file path.", required: true
					option "--verbose", "Enable verbose output."
				end
			end
		end
		
		it "includes required in usage" do
			option = required_options.ordered.first
			usage = option.to_a
			expect(usage.join(" ")).to be(:include?, "required")
		end
		
		it "raises exception when required option is missing" do
			expect do
				command_class.parse([])
			end.to raise_exception(Samovar::MissingValueError)
		end
		
		it "raises exception when only optional options are provided" do
			expect do
				command_class.parse(["--verbose"])
			end.to raise_exception(Samovar::MissingValueError)
		end
		
		it "succeeds when required option is provided" do
			command = command_class.parse(["--config", "config.yml"])
			
			expect(command).not.to be_nil
			expect(command.options[:config]).to be == "config.yml"
		end
		
		it "succeeds when both required and optional options are provided" do
			command = command_class.parse(["--config", "config.yml", "--verbose"])
			
			expect(command).not.to be_nil
			expect(command.options[:config]).to be == "config.yml"
			expect(command.options[:verbose]).to be == true
		end
		
		it "handles errors gracefully with call()" do
			output = StringIO.new
			result = command_class.call([], output: output)
			
			expect(result).to be_nil
			expect(output.string).to be(:include?, "config")
			expect(output.string).to be(:include?, "required")
		end
	end
	
	with "option with fixed value" do
		let(:fixed_options) do
			subject.parse do
				option "--flag", "A flag", value: :custom_value
			end
		end
		
		it "uses fixed value instead of parsed value" do
			values = fixed_options.parse(["--flag"], {})
			expect(values[:flag]).to be == :custom_value
		end
	end
	
	with "type coercion" do
		let(:typed_options) do
			subject.parse do
				option "--int <value>", "An integer", type: Integer
				option "--float <value>", "A float", type: Float
			end
		end
		
		it "coerces to integer" do
			values = typed_options.parse(["--int", "42"], {})
			expect(values[:int]).to be == 42
		end
		
		it "coerces to float" do
			values = typed_options.parse(["--float", "3.14"], {})
			expect(values[:float]).to be == 3.14
		end
	end
	
	with "callable type" do
		let(:callable_options) do
			subject.parse do
				option "--upcase <value>", "Uppercase it", type: ->(val){val.upcase}
			end
		end
		
		it "calls the proc" do
			values = callable_options.parse(["--upcase", "hello"], {})
			expect(values[:upcase]).to be == "HELLO"
		end
	end
	
	with "type with new" do
		it "calls new on the type" do
			newable_class = Class.new do
				def initialize(value)
					@value = value
				end
				
				attr :value
			end
			
			newable_options = subject.parse do
				option "--thing <value>", "A thing", type: newable_class
			end
			
			values = newable_options.parse(["--thing", "test"], {})
			expect(values[:thing]).to be_a(newable_class)
			expect(values[:thing].value).to be == "test"
		end
	end
end
