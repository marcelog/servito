defmodule Servito do
  require Logger

  defmacro __using__(_opts) do
    quote do
      import Servito
      defp format_xml(list) do
        format_xml list, []
      end

      defp format_xml([], acc) do
        Enum.reverse acc
      end

      defp format_xml([{k, v}|rest], acc) do
        v = if is_list(v) do
          format_xml v
        else
          v
        end
        format_xml rest, [{k, %{}, v}|acc]
      end
    end
  end

  defmacro post(url, fun) do
    quote [location: :keep] do
      {unquote(url), "POST", :erlang.term_to_binary(unquote(fun))}
    end
  end

  defmacro get(url, fun) do
    quote [location: :keep] do
      {unquote(url), "GET", :erlang.term_to_binary(unquote(fun))}
    end
  end

  defmacro delete(url, fun) do
    quote [location: :keep] do
      {unquote(url), "DELETE", :erlang.term_to_binary(unquote(fun))}
    end
  end

  defmacro unserve(name) do
    quote [
      location: :keep,
      bind_quoted: [name: name]
    ] do
      :cowboy.stop_listener name
    end
  end

  defmacro ret(status, headers, payload) do
    quote [location: :keep] do
      payload = unquote payload
      body = cond do
        is_map(payload) ->
          {:ok, body} = JSX.encode payload
          body
        is_binary(payload) -> payload
        is_list(payload) -> format_xml(payload) |> XmlBuilder.generate
      end
      req = var!(req)
      state = var!(state)
      {unquote(status), unquote(headers), body, req, state}
    end
  end

  defmacro serve(
    name, scheme, address, port, acceptors, cowboy_options, handlers
  ) do
    quote [
      location: :keep,
      bind_quoted: [
        scheme: scheme,
        address: address,
        port: port,
        cowboy_options: cowboy_options,
        acceptors: acceptors,
        handlers: handlers,
        name: name
      ]
    ] do
      require Logger
      fun = case scheme do
        :http -> :start_http
        :https -> :start_https
      end
      routes = Enum.map (0..(length(handlers) - 1)), fn(n) ->
        mod_name_handler = String.to_atom "__Servito__#{name}_server_#{n}"
        transport = case scheme do
          :http -> :tcp
          :https -> :ssl
        end
        {route, method, handler_fun} = Enum.at handlers, n
        m = quote do
          defmodule unquote(mod_name_handler) do
            require Logger
            use Servito

            def init({unquote(transport), :http}, _req, _opts) do
              {:upgrade, :protocol, :cowboy_rest}
            end

            def allowed_methods(req, state) do
              {[unquote(method)], req, state}
            end

            def content_types_provided(req, state) do
              {[
                {"application/json", :to_json},
                {"application/xml", :to_xml}
              ], req, state}
            end

            def content_types_accepted(req, state) do
              {[
                {{"application", "json", :*}, :from_json},
                {{"application", "xml", :*}, :from_xml}
              ], req, state}
            end

            def options(req, state) do
              headers = [
                {"Access-Control-Allow-Origin", "*"},
                {"Access-Control-Allow-Methods", "#{unquote method}"},
                {"Access-Control-Allow-Headers", "accept, content-type"}
              ]
              req = Enum.reduce headers, req, fn({k, v}, req) ->
                :cowboy_req.set_resp_header k, v, req
              end
              {:ok, req, state}
            end

            def is_authorized(req, state) do
              {true, req, state}
            end

            def delete_completed(req, state) do
              {true, req, state}
            end

            def dispatch(req, state) do
              {:ok, body, req} = :cowboy_req.body req
              {headers, req} = :cowboy_req.headers req
              {bindings, req} = :cowboy_req.bindings req
              bindings = Enum.into bindings, %{}
              {ctype, req} = :cowboy_req.header "accept", req
              data = case ctype do
                "application/json" ->
                  {:ok, json} = JSX.decode body
                  json
                "application/xml" ->
                  {doc, _} = Exmerl.from_string body
                  doc
              end
              f = :erlang.binary_to_term(unquote handler_fun)
              {status, headers, body, req, state} = f.(bindings, headers, data, req, state)
              {:ok, req} = :cowboy_req.reply status, headers, body, req
              {:halt, req, state}
            end

            def from_json(req, state) do
              dispatch req, state
            end

            def to_json(req, state) do
              dispatch req, state
            end

            def from_xml(req, state) do
              dispatch req, state
            end

            def to_xml(req, state) do
              dispatch req, state
            end

            def delete_resource(req, state) do
              dispatch req, state
            end

            def is_conflict(req, state) do
              {false, req, state}
            end

            def rest_terminate(_req, _state) do
              Logger.debug "Request finished"
              :ok
            end
          end
        end
        Code.eval_quoted m
        {route, mod_name_handler, []}
      end
      dispatch = :cowboy_router.compile [{:_, routes}]
      Logger.info "Starting #{inspect scheme} at #{address}:#{port}"
      {:ok, address} = :inet.parse_address to_char_list(address)
      apply(
        :cowboy,
        fun,
        [
          name,
          acceptors,
          [{:ip, address}, {:port, port} | cowboy_options],
          [{:env, [{:dispatch, dispatch}]}]
        ]
      )
    end
  end
end
