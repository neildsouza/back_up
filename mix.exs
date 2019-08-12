defmodule BackUp.MixProject do
  use Mix.Project

  def project do
    [
      app: :back_up,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BackUp.Application, []}
    ]
  end

  defp aliases do
    [
      clean_compile: ["clean", "compile"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:jason, "~> 1.0"}
    ]
  end
end
