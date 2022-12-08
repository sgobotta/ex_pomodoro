defmodule ExPomodoro.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_pomodoro,
      version: "0.1.1",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # Hex
      description: description(),
      package: package(),
      source_url: "https://github.com/sgobotta/ex_pomodoro",
      # Docs
      name: "ExPomodoro",
      docs: [
        main: "ExPomodoro",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Code quality and Testing
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.15.0", only: [:test]},
      {:git_hooks, "~> 0.6.2", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev], runtime: false},
      {:patch, "~> 0.12.0", only: [:test]},

      # Documentation
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      # Setup the whole library
      setup: ["deps.get", "deps.compile", "compile"],
      # Run code checks
      check: [
        "check.format",
        "check.credo",
        "check.dialyzer"
      ],
      "check.format": ["format --check-formatted"],
      "check.credo": ["credo --strict"],
      "check.dialyzer": ["dialyzer --format dialyxir"]
    ]
  end

  defp description() do
    "An Elixir Pomodoro for tasks and time management"
  end

  defp package() do
    [
      files: ~w(doc lib mix.exs README* LICENSE*),
      name: "ex_pomodoro",
      licenses: ["GPL-3.0-or-later"],
      links: %{"Github" => "https://github.com/sgobotta/ex_pomodoro"}
    ]
  end
end
