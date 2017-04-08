defmodule KVstoreTest do
    use ExUnit.Case

        setup_all do
            storage = Application.get_env(:kv, :storage, :kv_storage)
            :dets.delete_all_objects(storage)
            {:ok, %{:storage => storage}}
        end

        test "Create", state do
            result1 = Storage.create({:key1, 1, 5})
            expected1 = :ok
            [{_, result2, _}] = :dets.lookup(state[:storage], :key1) 
            expected2 = 1

            assert expected1 == result1
            assert expected2 == result2
        end

        test "Read", state do
            :dets.insert_new(state[:storage], {:key2, 2, 5})
            result = Storage.read(:key2)
            expected = 2

            assert expected == result
        end

        test "Update", state do
            :dets.insert_new(state[:storage], {:key4, 4, 5})
            result1 = Storage.update({:key4, 5})
            expected1 = :ok
            [{_, result2, _}] = :dets.lookup(state[:storage], :key4) 
            expected2 = 5

            assert expected1 == result1
            assert expected2 == result2
        end

        test "Delete", state do
            :dets.insert_new(state[:storage], {:key3, 3, 5})
            result1 = Storage.delete(:key3)
            expected1 = :ok
            result2 = :dets.lookup(state[:storage], :key3)
            expected2 = []

            assert expected1 == result1
            assert expected2 == result2
        end

        test "TTL", state do
            :ok = Storage.create({:key5, 5, 5})
            result1 = Storage.read(:key5) 
            expected1 = 5
            :timer.sleep(6000)
            result2 = Storage.read(:key5) 
            expected2 = :none

            assert expected1 == result1
            assert expected2 == result2
        end

end