# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"
require "sus/fixtures/temporary_directory_context"

class CompletionLeaf < Samovar::Command
	self.description = "Leaf command."
	
	def self.path_completions(context)
		["app.rb", "readme.md", "test.rb"]
	end
	
	format_completions = lambda do |context|
		if context.row.is_a?(Samovar::Option) && context.row.key == :format
			return ["json", "text", "yaml"]
		end
		return []
	end
	
	options do
		option "--format <name>", "The output format.", default: "text", completions: format_completions
		option "--output <path>", "The output path.", completions: :path
		option "--root <path>", "The root directory.", completions: :directory
		option "--verbose | --quiet", "Verbosity of output for debugging.", key: :logging
		option "--[no]-color", "Enable or disable color output.", default: true
	end
	
	one :path, "The path to process.", completions: method(:path_completions)
	many :extras, "Extra values.", completions: ->(context){["extra-a", "extra-b", context.environment["EXTRA"]].compact}
	split :argv, "Additional arguments.", completions: :executable
end

class CompletionList < Samovar::Command
	self.description = "List things."
	
	options do
		option "--all", "List all things."
	end
end

class CompletionTop < Samovar::Command
	self.description = "Top command."
	
	options do
		option "-c/--configuration <name>", "Specify a configuration."
		option "-v/--verbose", "Enable verbose output."
	end
	
	nested :command, {
		"leaf" => CompletionLeaf,
		"list" => CompletionList,
	}, default: "leaf"
end

describe Samovar::Completion do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def values(result)
		result.collect(&:value)
	end
	
	def complete(input, **options)
		CompletionTop.complete(input, output: StringIO.new, **options)
	end
	
	it "completes top-level option flags" do
		result = complete(["--ver"])
		
		expect(values(result)).to be == ["--verbose"]
	end
	
	it "completes top-level options and commands for an empty token" do
		result = complete([""])
		
		expect(values(result)).to be == ["--configuration", "-c", "--verbose", "-v", "leaf", "list"]
	end
	
	it "completes nested command names" do
		result = complete(["le"])
		
		expect(values(result)).to be == ["leaf"]
	end
	
	it "completes nested command options" do
		result = complete(["leaf", "--no"])
		
		expect(values(result)).to be == ["--no-color"]
	end
	
	it "completes boolean flag variants" do
		result = complete(["leaf", "--"])
		
		expect(values(result)).to be(:include?, "--color")
		expect(values(result)).to be(:include?, "--no-color")
	end
	
	it "completes option values using static completions" do
		result = complete(["leaf", "--format", "j"])
		
		expect(values(result)).to be == ["json"]
	end
	
	it "continues completion after consuming option values" do
		result = complete(["--configuration", "development", ""])
		
		expect(values(result)).to be == ["--configuration", "-c", "--verbose", "-v", "leaf", "list"]
	end
	
	it "requests native path completion for option values" do
		result = complete(["leaf", "--output", "tmp/"])
		suggestion = result.first
		
		expect(suggestion.value).to be == "tmp/"
		expect(suggestion.type).to be == :path
	end
	
	it "requests native directory completion for option values" do
		result = complete(["leaf", "--root", "tmp/"])
		suggestion = result.first
		
		expect(suggestion.value).to be == "tmp/"
		expect(suggestion.type).to be == :directory
	end
	
	it "completes option defaults before static completions" do
		result = complete(["leaf", "--format", ""])
		
		expect(values(result)).to be == ["text", "json", "yaml"]
	end
	
	it "completes option values after a trailing option flag" do
		result = complete(["leaf", "--format", ""])
		
		expect(values(result)).to be == ["text", "json", "yaml"]
	end
	
	it "completes positional values using method completions" do
		result = complete(["leaf", "r"])
		
		expect(values(result)).to be == ["readme.md"]
	end
	
	it "completes many values using callable completions" do
		result = complete(["leaf", "app.rb", "e"], environment: {"EXTRA" => "env-extra"})
		
		expect(values(result)).to be == ["extra-a", "extra-b", "env-extra"]
	end
	
	it "completes split marker before many consumes option-looking tokens" do
		result = complete(["leaf", "app.rb", "--"])
		
		expect(values(result)).to be == ["--"]
	end
	
	it "completes split values after the marker" do
		result = complete(["leaf", "app.rb", "--", "ru"])
		suggestion = result.first
		
		expect(suggestion.value).to be == "ru"
		expect(suggestion.type).to be == :executable
	end
	
	it "delegates split completion after the executable" do
		output = StringIO.new
		
		result = CompletionTop.complete(["leaf", "app.rb", "--", "ruby", "--ver"], output: output)
		suggestion = result.first
		
		expect(suggestion.value).to be == "ruby"
		expect(suggestion.type).to be == :delegate
		expect(suggestion.options).to be == {index: 3}
		expect(output.string).to be == "delegate\truby\tDelegate completion\tindex=3\n"
	end
	
	it "uses default nested command for option-looking completions" do
		result = complete(["--no"])
		
		expect(values(result)).to be == ["--no-color"]
	end
	
	it "uses default nested command for unmatched command words" do
		result = complete(["unknown", ""])
		
		expect(values(result)).to be == ["extra-a", "extra-b"]
	end
	
	it "returns collected suggestions for unmatched nested commands without default" do
		nested = Samovar::Nested.new(:command, {"list" => CompletionList})
		context = Samovar::Completion::Context.for(CompletionTop, ["unknown", ""])
		collected = [
			Samovar::Completion::Suggestion.new("--verbose", type: :option)
		]
		
		result = nested.complete(["unknown"], context, collected)
		
		expect(values(result)).to be == ["--verbose"]
	end
	
	it "prints completion results as TSV" do
		output = StringIO.new
		result = complete(["le"])
		
		result.print(output)
		
		expect(output.string).to be == "command\tleaf\tLeaf command.\n"
	end
	
	it "prints completion metadata as trailing TSV fields" do
		output = StringIO.new
		result = Samovar::Completion::Result.new([
			Samovar::Completion::Suggestion.new(
				"tmp\nfile",
				description: "A\tpath",
				type: :path,
				suffix: "/",
				empty: nil,
			),
		])
		result.print(output)
		expect(output.string).to be == "path\ttmp file\tA path\tsuffix=/\n"
	end
	
	it "wraps existing suggestions" do
		suggestion = Samovar::Completion::Suggestion.new("value", type: :value)
		
		expect(Samovar::Completion::Suggestion.wrap(suggestion)).to be == suggestion
	end
	
	it "wraps hash suggestions" do
		suggestion = Samovar::Completion::Suggestion.wrap(
			value: "value",
			description: "Description",
			type: :value,
			suffix: " ",
		)
		
		expect(suggestion.value).to be == "value"
		expect(suggestion.description).to be == "Description"
		expect(suggestion.type).to be == :value
		expect(suggestion.options).to be == {suffix: " "}
	end
	
	it "returns no suggestions for missing completions" do
		context = Samovar::Completion::Context.for(CompletionTop, [""])
		provider = Samovar::Completion::Provider.new(context, nil)
		
		expect(provider.suggestions).to be(:empty?)
	end
	
	it "returns no suggestions for unknown native completions" do
		context = Samovar::Completion::Context.for(CompletionTop, [""])
		provider = Samovar::Completion::Provider.new(context, :unknown)
		
		expect(provider.suggestions).to be(:empty?)
	end
	
	it "returns collected suggestions after completing all rows" do
		context = Samovar::Completion::Context.for(CompletionTop, [""])
		table = [Object.new]
		
		result = context.complete_rows(table, [])
		
		expect(result).to be(:empty?)
	end
	
	it "uses the final argument as the completion token" do
		output = StringIO.new
		
		result = CompletionTop.complete(["le"], output: output)
		
		expect(values(result)).to be == ["leaf"]
		expect(output.string).to be == "command\tleaf\tLeaf command.\n"
	end
	
	it "uses an empty token when completing with no arguments" do
		output = StringIO.new
		
		result = CompletionTop.complete([""], output: output)
		
		expect(values(result)).to be(:include?, "leaf")
		expect(output.string).to be(:include?, "command\tleaf\tLeaf command.\n")
		expect(output.string).to be(:include?, "option\t--verbose\tEnable verbose output.\n")
	end
	
	it "splits completed arguments from the current token" do
		arguments = ["leaf", "--ver"]
		
		context = Samovar::Completion::Context.for(CompletionTop, arguments)
		
		expect(context.arguments).to be == ["leaf"]
		expect(context.current).to be == "--ver"
		expect(arguments).to be == ["leaf", "--ver"]
	end
	
	it "completes with no arguments" do
		output = StringIO.new
		
		result = CompletionTop.complete([], output: output)
		
		expect(values(result)).to be(:include?, "leaf")
		expect(output.string).to be(:include?, "command\tleaf\tLeaf command.\n")
		expect(output.string).to be(:include?, "option\t--verbose\tEnable verbose output.\n")
	end
end
