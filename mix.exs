defmodule Servito.Mixfile do
  use Mix.Project

  def project do
    [app: :servito,
     version: "0.0.1",
     elixir: "~> 1.1-dev",
     deps: deps]
  end

  def application do
    [applications: [:logger, :cowboy]]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:exjsx, "~> 3.1.0"}
    ]
  end
end
