defmodule Test do
  use Servito
  require Logger

  def stop() do
    unserve :myserver
  end

  def test() do
    serve :myserver, :http, "127.0.0.1", 9003, 1, [], [
      post("/pepe", fn(bindings, headers, body, req, state) ->
        Logger.debug "Bindings: #{inspect bindings}"
        Logger.debug "Headers: #{inspect headers}"
        Logger.debug "Body: #{inspect body}"
        {req, state}
      end)
    ]
  end
end