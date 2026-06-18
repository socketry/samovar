# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "samovar"

class Bottom < Samovar::Command
	self.description = "Create a new teapot package using the specified repository."
	
	one :project_name, "The name of the new project in title-case, e.g. 'My Project'."
	many :packages, "Any additional packages you'd like to include in the project."
	split :argv, "Additional arguments to be passed to the sub-process."
end

class Top < Samovar::Command
	self.description = "A decentralised package manager and build tool."
	
	options do
		option "-c/--configuration <name>", "Specify a specific build configuration.", default: "TEAPOT_CONFIGURATION"
		option "-i/--in/--root <path>", "Work in the given root directory."
		option "--verbose | --quiet", "Verbosity of output for debugging.", key: :logging
		option "--[no]-color", "Enable or disable color output.", default: true
		option "-h/--help", "Print out help information."
		option "-v/--version", "Print out the application version."
	end
	
	nested :command, {
		"bottom" => Bottom
	}
end

describe Samovar::Command do
	it "should invoke call" do
		mock(Top) do |mock|
			mock.after(:new) do |instance|
				expect(instance).to receive(:call).and_return(true)
			end
		end
		
		Top.call([])
	end
	
	with "error handling in call()" do
		let(:command_class) do
			Class.new(Samovar::Command) do
				self.description = "A command that raises errors during execution."
				
				one :action, "The action to perform."
				
				def call
					if @action == "fail"
						raise Samovar::MissingValueError.new(self, :something_required)
					end
					
					return "success"
				end
			end
		end
		
		it "handles errors raised during call execution" do
			output = StringIO.new
			result = command_class.call(["fail"], output: output)
			
			expect(result).to be_nil
			expect(output.string).to be(:include?, "something_required")
			expect(output.string).to be(:include?, "required")
		end
		
		it "returns result when call succeeds" do
			result = command_class.call(["ok"])
			
			expect(result).to be == "success"
		end
	end
	
	it "should use default value" do
		top = Top[]
		expect(top.options[:configuration]).to be == "TEAPOT_CONFIGURATION"
	end
	
	it "can update options" do
		top = Top[]
		expect(top.options[:configuration]).to be == "TEAPOT_CONFIGURATION"
		
		top = top["--verbose"]
		expect(top.options[:configuration]).to be == "TEAPOT_CONFIGURATION"
		expect(top.options[:logging]).to be == :verbose
	end
	
	it "should parse a simple command" do
		top = Top["-c", "path", "bottom", "foobar", "A", "B", "--", "args", "args"]
		
		expect(top.options[:configuration]).to be == "path"
		expect(top.command.class).to be == Bottom
		expect(top.command.project_name).to be == "foobar"
		expect(top.command.packages).to be == ["A", "B"]
		expect(top.command.argv).to be == ["args", "args"]
	end
	
	it "should generate documentation" do
		top = Top[]
		buffer = StringIO.new
		top.print_usage(output: buffer)
		
		expect(buffer.string).to be(:include?, Top.description)
	end
	
	with "specific output" do
		it "can print usage to specified outputn buffer" do
			buffer = StringIO.new
			top = Top[output: buffer]
			top.print_usage
			
			expect(buffer.string).to be(:include?, Top.description)
		end
	end
	
	with "--[no]-color flag" do
		it "should use default color output if unspecified" do
			top = Top[]
			expect(top.options[:color]).to be == true
		end
		
		it "should enable color output" do
			top = Top["--color"]
			expect(top.options[:color]).to be == true
		end
		
		it "should disable color output" do
			top = Top["--no-color"]
			expect(top.options[:color]).to be == false
		end
	end
	
	with "error handling" do
		it "handles invalid input gracefully with call()" do
			output = StringIO.new
			result = Top.call(["--invalid-option"], output: output)
			
			expect(result).to be_nil
			expect(output.string).to be(:include?, "Could not parse")
			expect(output.string).to be(:include?, "--invalid-option")
		end
		
		it "raises exception with parse() for invalid input" do
			expect do
				Top.parse(["--invalid-option"])
			end.to raise_exception(Samovar::InvalidInputError)
		end
		
		it "handles invalid input after valid command" do
			top = Top["bottom", "project"]
			
			expect do
				top.parse(["--invalid"])
			end.to raise_exception(Samovar::InvalidInputError)
		end
	end
	
	with "#to_s" do
		it "can convert command to string" do
			top = Top[]
			expect(top.to_s).to be(:include?, "Top")
		end
	end
	
	with "edge cases" do
		it "raises error for duplicate method definitions" do
			# Create a command that defines a method before adding a field with same name
			command_class = Class.new(Samovar::Command) do
				self.description = "Test duplicate keys"
				
				# Define a method first
				def name
					"existing method"
				end
			end
			
			# This should raise ArgumentError when we try to add a field with same name
			expect do
				command_class.one(:name, "This conflicts with the method")
			end.to raise_exception(ArgumentError, message: be(:include?, "already defined"))
		end
		
		it "generates command line usage for minimal command" do
			# Create a minimal command with no options/arguments
			command_class = Class.new(Samovar::Command) do
				self.description = "Minimal command"
			end
			
			# Should return the name (with trailing space from empty usage)
			usage = command_class.command_line("mycommand")
			expect(usage).to be(:start_with?, "mycommand")
		end
	end
	
	with "equals sign option syntax" do
		let(:command_class) do
			Class.new(Samovar::Command) do
				self.description = "A command that accepts a configuration file."
				
				options do
					option "--config <path>", "The configuration file path."
					option "--[no]-color", "Enable or disable color output."
				end
			end
		end
		
		it "raises for an unknown option in the equals sign form" do
			expect do
				command_class.parse(["--unknown=value"])
			end.to raise_exception(Samovar::InvalidInputError)
		end
	end
end

