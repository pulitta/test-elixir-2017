defmodule KVstore do
    use Application
    
    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        children = [
            worker(Storage, []),
            worker(Router, [])
        ]

        opts = [strategy: :one_for_one, name: KVstore.Supervisor]
        Supervisor.start_link(children, opts)
    end

end

