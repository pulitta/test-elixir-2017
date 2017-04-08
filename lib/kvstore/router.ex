defmodule Router do
    import Plug.Conn
    use Plug.Router


    plug :match
    plug :dispatch

    def start_link do
        Plug.Adapters.Cowboy.http(Router, [])
    end

    get "/" do
        conn = fetch_query_params(conn)
        {code, response} = case call(conn.params) do
            :error -> {404, "error"};
            other -> {200, to_string(other)}
        end
        send_resp(conn, code, response)
    end

    match _, do: send_resp(conn, 404, "error")

    defp call(%{"action" => "create", "key" => key, "value" => value}), do: Storage.create({key, value})
    defp call(%{"action" => "read", "key" => key}), do: Storage.read(key)
    defp call(%{"action" => "update", "key" => key, "value" => value}), do: Storage.update({key, value})
    defp call(%{"action" => "delete", "key" => key}), do: Storage.delete(key)
    defp call(_), do: :error

end