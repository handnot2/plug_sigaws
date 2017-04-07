# PlugSigaws

An Elixir Plug to verify HTTP requests signed with AWS Signature V4. 

## Installation

This package can be installed by adding `plug_sigaws` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_sigaws, "~> 0.1.0"},
    {:sigaws_quickstart_provider, "~> 0.1.0"}
  ]
end
```

You will need a companion Sigaws verification provider package as well.
If you have your own custom build provider, include that in place of
`:sigaws_quickstart_provider`.

## Documentation

+ [Blog](https://handnot2.github.io/blog/elixir/aws-signature-sigaws)
+ [Module Doc](https://hexdocs.pm/plug_sigaws)
+ [Sigaws Module Doc](https://hexdocs.pm/sigaws)
