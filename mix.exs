defmodule Servito.Mixfile do
  use Mix.Project

  def project do
    [app: :servito,
     version: "0.0.10",
     elixir: "> 1.0.0",
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :cowboy]]
  end

  defp description do
    """
Launches HTTP servers for testing

    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Marcelo Gornstein"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/marcelog/servito"
      }
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.4"},
      {:ex_doc, "~> 0.14.5", only: :dev},
      {:exjsx, "~> 3.2.1"},
      {:sweet_xml, "~> 0.6.4"},
      {:ibrowse, "~> 4.4.0", only: :test},
      {:xml_builder, "~> 0.0.9"}
    ]
  end
end
