defmodule LogserverWeb.RoomChannel do
  use LogserverWeb, :channel
  require Logger

  def join("room:lobby", _params, socket) do
    Logger.info("User joined room:lobby")
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    Logger.info("User attempting to join room:#{_private_room_id}")
    {:error, %{reason: "unauthorized"}}
  end

  # Handle incoming messages
  def handle_in("new_message", %{"body" => body}, socket) do
    Logger.debug("Received message: #{body}")
    broadcast!(socket, "new_message", %{body: body})
    {:reply, :ok, socket}
  end

  def handle_in(_message, _params, socket) do
    Logger.debug("Received unknown message: #{_message}")
    {:noreply, socket}
  end
end
