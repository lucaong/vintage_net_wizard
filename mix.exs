defmodule VintageNetWizard.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/nerves-networking/vintage_net_wizard"

  def project do
    [
      app: :vintage_net_wizard,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      aliases: [docs: ["docs", &copy_images/1]],
      package: package(),
      description: description()
    ]
  end

  def application do
    [
      mod: {VintageNetWizard.Application, []},
      extra_applications: [:logger, :eex]
    ]
  end

  defp description do
    "WiFi Setup Wizard that uses VintageNet"
  end

  def elixirc_paths(:test), do: ["test/support", "lib"]
  def elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: [
        "assets",
        "CHANGELOG.md",
        "json-api.md",
        "lib",
        "LICENSE",
        "mix.exs",
        "priv",
        "README.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      # Dependencies for all targets
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_html, "~> 2.13"},
      {:jason, "~> 1.0"},
      {:vintage_net_wifi, "~> 0.7.0"},
      {:nerves_runtime, "~> 0.10"},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs],
      list_unused_filters: true
    ]
  end

  defp docs do
    [
      extras: ["README.md", "json-api.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  # Copy the images referenced by docs, since ex_doc doesn't do this.
  defp copy_images(_) do
    File.cp_r("assets", "doc/assets")
  end
end
