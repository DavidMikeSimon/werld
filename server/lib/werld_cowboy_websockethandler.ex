defmodule Werld.Cowboy.WebSocketHandler do
    @behaviour :cowboy_websocket_handler

    def init({:tcp, :http}, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_transport_name, req, _opts) do
        :erlang.start_timer(2000, self(), :send_message)
        {:ok, req, :undefined_state}
    end

    def websocket_handle({:binary, data}, req, state) do
        client_req = Werld.Proto.MessageToServer.decode(data)
        response = case client_req.msg do
            {:chunk_request, chunk_request} -> chunk_request_response(chunk_request)
        end
        response_enc = Werld.Proto.MessageToClient.encode(response)
        {:reply, {:binary, response_enc}, req, state}
    end

    def websocket_handle(_data, req, state) do
        {:ok, req, state}
    end

    def websocket_info({:timeout, _ref, :send_message}, req, state) do
        :erlang.start_timer(5000, self(), :send_message)
        msg = Werld.Proto.MessageToClient.new(msg: {:global_notice, "Stuff is really happening"})
        enc = Werld.Proto.MessageToClient.encode(msg)
        {:reply, {:binary, enc}, req, state}
    end

    def websocket_terminate(_reason, _req, _state) do
        :ok
    end

    defp chunk_request_response(chunk_request) do
        Werld.Proto.MessageToClient.new(msg: {
            :chunk,
            Werld.Proto.Chunk.new(
                pos: Werld.Proto.Coord.new(
                    x: hd(chunk_request.coords).x,
                    y: hd(chunk_request.coords).y
                ),
                ver: 50,
                block_runs: [
                    Werld.Proto.Chunk.BlockRun.new(
                        count: 20,
                        block_type: 0
                    ),
                    Werld.Proto.Chunk.BlockRun.new(
                        count: 50,
                        block_type: 1
                    ),
                    Werld.Proto.Chunk.BlockRun.new(
                        count: 186,
                        block_type: 0
                    ),
                ]
            )
        })
    end
end