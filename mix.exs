defmodule Servito.Mixfile do
  use Mix.Project

  def project do
    [app: :servito,
     version: "0.0.4",
     elixir: "> 1.0.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :cowboy]]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.4"},
      {:exjsx, "~> 3.2.0"},
      {:exmerl, "~> 0.1.1"},
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.3", only: :test},
      {:xml_builder, "~> 0.0.8"}
    ]
  end
end
