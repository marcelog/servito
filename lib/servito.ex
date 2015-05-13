defmodule Servito do
  require Logger

  defmacro __using__(_opts) do
    quote do
      import Servito
    end
  end

  defmacro post(url, fun) do
    quote do
      {unquote(url), "POST", unquote(fun)}
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

            def init({unquote(transport), unquote(scheme)}, _req, _opts) do
              {:upgrade, :protocol, :cowboy_rest}
            end

            def allowed_methods(req, state) do
              {[unquote(method)], req, state}
            end

            def content_types_provided(req, state) do
              {[{"application/json", :to_json}], req, state}
            end

            def content_types_accepted(req, state) do
              {[{{"application", "json", :*}, :from_json}], req, state}
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
              {:ok, json} = JSX.decode body
              f = unquote handler_fun
              {req, state} = f.(bindings, headers, body, req, state)
              {:halt, req, state}
            end

            def from_json(req, state) do
              dispatch req, state
            end

            def to_json(req, state) do
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
      Logger.info "Starting HTTP at #{address}:#{port}"
      {:ok, address} = :inet.parse_address to_char_list(address)
      apply(
        :cowboy,
        fun,
        [
          name,
          1,
          [{:ip, address}, {:port, port} | cowboy_options],
          [{:env, [{:dispatch, dispatch}]}]
        ]
      )
    end
  end
end
