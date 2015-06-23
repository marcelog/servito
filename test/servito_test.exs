defmodule ServitoTest do
  use ExUnit.Case
  use Servito
  require Logger

  test "string http" do
    serve :myserver, :http, "127.0.0.1", 9003, 1, [], [
      post("/test1", fn(_bindings, _headers, _body, req, state) ->
        ret 202, [], "blah"
      end)
    ]
    {:ok, body} = JSX.encode %{
      key1: "value1"
    }
    {
      :ok,
      '202',
      retheaders,
      "blah"
    } = req "http://127.0.0.1:9003/test1", [
      {'Content-Type', 'application/json'},
      {'Accept', 'application/json'}
    ], :post, body
    unserve :myserver
    assert :proplists.get_value('content-type', retheaders) === 'application/json'
  end

  test "json http" do
    serve :myserver, :http, "127.0.0.1", 9003, 1, [], [
      post("/test1", fn(_bindings, _headers, _body, req, state) ->
        ret 202, [], %{resp_key_1: "resp_value_1"}
      end)
    ]
    {:ok, body} = JSX.encode %{
      key1: "value1"
    }
    {:ok, retbody} = JSX.encode %{
      "resp_key_1": "resp_value_1"
    }
    {
      :ok,
      '202',
      retheaders,
      ^retbody
    } = req "http://127.0.0.1:9003/test1", [
      {'Content-Type', 'application/json'},
      {'Accept', 'application/json'}
    ], :post, body
    unserve :myserver
    assert :proplists.get_value('content-type', retheaders) === 'application/json'
  end

  test "json https" do
    opts = [
      {:cacertfile, "test/resources/server.crt"},
      {:certfile, "test/resources/server.crt"},
      {:keyfile, "test/resources/server.key"},
      {:verify, :verify_none},
      {:fail_if_no_peer_cert, false}
    ]
    serve :myserver, :https, "127.0.0.1", 9003, 1, opts, [
      post("/test1", fn(_bindings, _headers, _body, req, state) ->
        ret 202, [], %{resp_key_1: "resp_value_1"}
      end)
    ]
    {:ok, body} = JSX.encode %{
      key1: "value1"
    }
    {:ok, retbody} = JSX.encode %{
      "resp_key_1": "resp_value_1"
    }
    {
      :ok,
      '202',
      retheaders,
      ^retbody
    } = req "https://127.0.0.1:9003/test1", [
      {'Content-Type', 'application/json'},
      {'Accept', 'application/json'}
    ], :post, body
    unserve :myserver
    assert :proplists.get_value('content-type', retheaders) === 'application/json'
  end

  test "xml http" do
    serve :myserver, :http, "127.0.0.1", 9003, 1, [], [
      post("/test1", fn(_bindings, _headers, _body, req, state) ->
        ret 202, [], [node1: [node2: "value"]]
      end)
    ]
    {
      :ok,
      '202',
      retheaders,
      "<node1>\n\t<node2>value</node2>\n</node1>"
    } = req "http://127.0.0.1:9003/test1", [
      {'Content-Type', 'application/xml'},
      {'Accept', 'application/xml'}
    ], :post, "<reqnode1><reqnode2>value</reqnode2></reqnode1>"
    unserve :myserver
    assert :proplists.get_value('content-type', retheaders) === 'application/xml'
  end

  defp req(uri, headers, method, body) do
    Logger.debug "Requesting: #{inspect uri}"
    uri = to_char_list uri
    :ibrowse.send_req(
      uri, headers, method, body, [
      {:response_format, :binary}, {:max_sessions, 50}, {:max_pipeline_size, 1},
      {:connect_timeout, 60000}, {:inactivity_timeout, 60000},
      {:stream_chunk_size, 10}, {:ssl_options, [{:verify, :verify_none}]}
    ])
  end
end
