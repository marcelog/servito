defmodule Test do
  use Servito
  require Logger

  def stop() do
    unserve :myserver
  end

  def test() do
    serve :myserver, :http, "127.0.0.1", 9003, 1, [], [
      post("/pepe", fn(bindings, headers, body, req, state) ->
        Logger.debug "POST Bindings: #{inspect bindings}"
        Logger.debug "POST Headers: #{inspect headers}"
        Logger.debug "POST Body: #{inspect body}"
        ret 202, [], %{resp_key_1: "resp_value_1"}
      end)
    ]
  end
end