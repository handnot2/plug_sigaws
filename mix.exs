defmodule PlugSigaws.Mixfile do
  use Mix.Project

  @version "0.1.1"
  @description """
  Elixir Plug for authenticating HTTP requests using AWS Signature V4.
  """
  @source_url "https://github.com/handnot2/plug_sigaws"
  @blog_url "https://handnot2.github.io/blog/elixir/aws-signature-sigaws"

  def project do
    [app: :plug_sigaws,
     version: @version,
     description: @description,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:inch_ex, "~> 0.5", only: :docs},
      {:plug, "~> 1.2"},
      {:sigaws, "~> 0.1"}
    ]
  end

  defp package do
    [
      maintainers: ["handnot2"],
      files: ["config", "lib", "LICENSE", "mix.exs", "README.md"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Blog" => @blog_url
      }
    ]
  end
end
