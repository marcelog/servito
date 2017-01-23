defmodule Servito.Mixfile do
  use Mix.Project

  def project do
    [app: :servito,
     version: "0.0.10",
     elixir: "> 1.0.0",
     deps: deps()]
  end

  def application do
    [applications: [:logger, :cowboy]]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.4"},
      {:exjsx, "~> 3.2.1"},
      {:sweet_xml, "~> 0.6.4"},
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.3", only: :test},
      {:xml_builder, "~> 0.0.9"}
    ]
  end
end
