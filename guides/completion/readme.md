# Completion

This guide explains how to add shell completion to commands built with `samovar`.

Samovar can complete command lines using the same grammar used for parsing. It can complete option flags, boolean flag variants, nested command names, option values, positional arguments, and split arguments.

## Command Entry Point

Commands expose a completion entry point alongside the normal execution entry point:

~~~ ruby
Application.call(ARGV)     # Parse and execute the command.
Application.complete(ARGV) # Print completion candidates.
~~~

`complete` expects the command-line arguments to be truncated to the cursor. The final argument is the token being completed. When completing after a space, pass an empty string as the final argument:

~~~ ruby
Application.complete(["serve", "--bind", ""])
~~~

Completion candidates are printed as tab-separated values:

~~~ text
type	value	description
~~~

## Static Completions

Option flags and nested command names are completed automatically. You can add static completions for option values and positional arguments with `completions:`.

~~~ ruby
require "samovar"

class Serve < Samovar::Command
	self.description = "Run the server."
	
	options do
		option "--format <name>", "The output format.", default: "text", completions: ["json", "text", "yaml"]
	end
end

class Application < Samovar::Command
	options do
		option "-h/--help", "Print help."
	end
	
	nested :command, {
		"serve" => Serve
	}, default: "serve"
end
~~~

Examples:

~~~ ruby
Application.complete(["ser"])
# command	serve	Run the server.

Application.complete(["serve", "--format", "j"])
# value	json
~~~

If an option has a default value, the default is offered before other value completions.

## Dynamic Completions

Use a callable provider when completions depend on runtime state.

~~~ ruby
class Serve < Samovar::Command
	def self.host_completions(context)
		["localhost", "0.0.0.0"].select do |host|
			host.start_with?(context.current)
		end
	end
	
	options do
		option "--bind <host>", "The bind address.", completions: method(:host_completions)
	end
end
~~~

The provider receives a `Samovar::Completion::Context` with:

- `current`: The token being completed.
- `argv`: The full truncated argument list.
- `environment`: The environment hash passed to `complete`.
- `row`: The parser row requesting completions.
- `option`: The option requesting completions, when completing an option value.

Providers can return strings, hashes, or `Samovar::Completion::Suggestion` instances:

~~~ ruby
option "--mode <name>", "The mode.",
	completions: [
		{value: "development", description: "Local development", type: :value},
		{value: "production", description: "Production", type: :value}
	]
~~~

## Path Completion

For path-like arguments, let the shell do native path expansion by using one of the native completion providers:

~~~ ruby
class Process < Samovar::Command
	options do
		option "--output <path>", "The output path.", completions: :path
		option "--root <path>", "The root directory.", completions: :directory
	end
	
	one :input, "The input path.", completions: :file
end
~~~

Supported native providers:

- `:path`: Complete files and directories using the shell.
- `:file`: Alias for `:path`.
- `:directory`: Complete directories using the shell.

Samovar does not inspect the filesystem for these providers. It emits a typed completion request, and the shell adapter translates it to native shell path completion.

## Dedicated Completion Executable

Shell adapters call a dedicated completion executable named `completion-<command>`. This avoids running the normal command during completion.

For a command named `falcon`, provide:

~~~ text
bin/falcon
bin/completion-falcon
~~~

The completion executable can be very small:

~~~ ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/my/application"

My::Application.complete(ARGV)
~~~

When the user completes a command by path, the shell adapter resolves the completion executable next to that command:

~~~ text
falcon          -> completion-falcon
bin/falcon      -> bin/completion-falcon
./bin/falcon    -> ./bin/completion-falcon
/path/falcon    -> /path/completion-falcon
~~~

## Installing Shell Adapters

Shell adapter generation and installation is provided by the `completion` gem.

Generate an adapter script:

~~~ bash
$ completion generate --shell zsh --command falcon
~~~

Install a generic adapter script into the default directory for the current shell:

~~~ bash
$ completion install
~~~

The generic adapter checks whether a matching `completion-<command>` executable exists before handling a command. You can install an adapter for a specific command instead:

~~~ bash
$ completion install --command falcon
~~~

You can specify the shell and directory explicitly:

~~~ bash
$ completion install --shell fish --directory ~/.config/fish/completions --command falcon
~~~

The installed adapter calls the matching `completion-<command>` executable when completion is requested.

## Testing Completion

You can test completion directly without involving a shell:

~~~ ruby
output = StringIO.new

Application.complete(["serve", "--format", "j"], output: output)

expect(output.string).to be == "value\tjson\t\n"
~~~

For a trailing-space completion, pass an empty final token:

~~~ ruby
Application.complete(["serve", "--format", ""], output: output)
~~~
