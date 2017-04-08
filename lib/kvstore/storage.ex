defmodule Storage do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, %{}, name: Storage)
    end

    def create(kv_ttl) do
        GenServer.call(__MODULE__, {:create, kv_ttl})
    end

    def read(key) do
        GenServer.call(__MODULE__, {:read, key})
    end

    def update(kv) do
        GenServer.call(__MODULE__, {:update, kv})
    end

    def delete(key) do
        GenServer.call(__MODULE__, {:delete, key})
    end

    def init(_) do
        timer = 1000
        storage = Application.get_env(:kvstore, :storage, :kv_storage)
        {:ok, storage_table} = :dets.open_file(storage, [type: :set])
        start_timer(timer)
        {:ok, %{:storage_table => storage_table, :timer => timer}}
    end

    def handle_call({:create, {key, value, ttl}}, _from, %{:storage_table => storage_table} = state) do
        expiration = :os.system_time(:seconds) + ttl
        :dets.insert_new(storage_table, {key, value, expiration})
        {:reply, :ok, state}
    end

    def handle_call({:read, key}, _from, %{:storage_table => storage_table} = state) do
        value = case :dets.lookup(storage_table, key) do
            [{_,v,_}] -> v
            _ -> :none
        end
        {:reply, value, state}
    end

    def handle_call({:update, {key, value}}, _from, %{:storage_table => storage_table} = state) do
        case :dets.lookup(storage_table, key) do
            [{_,_,timestamp}] -> 
                :dets.delete(storage_table, key)
                :dets.insert(:kv_storage, {key,value,timestamp});
            _ -> :none
        end
        {:reply, :ok, state}
    end

    def handle_call({:delete, key}, _from, %{:storage_table => storage_table} = state) do
        :dets.delete(storage_table, key)
        {:reply, :ok, state}
    end

    def handle_info(:clear_storage, %{:timer => timer, :storage_table => storage_table} = state) do
        clear_storage(storage_table)
        start_timer(timer)
        {:noreply, state}
    end

    defp start_timer(timer) do
        Process.send_after(self(), :clear_storage, timer)
    end

    defp clear_storage(storage) do
        now = :os.system_time(:seconds)
        :dets.select_delete(storage, [{{:"_", :"_", :"$3"}, [{:<, :"$3", now}], [true]}])
    end

end