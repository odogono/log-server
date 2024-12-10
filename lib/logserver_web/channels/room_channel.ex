defmodule LogserverWeb.RoomChannel do
  use LogserverWeb, :channel
  require Logger
  alias Logserver.Repo
  alias Logserver.Logging.Message

  def join("room:lobby", _params, socket) do
    Logger.info("User joined room:lobby")
    broadcast_log({:status, "User joined room:lobby"})
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    Logger.info("User attempting to join room:#{_private_room_id}")
    {:error, %{reason: "unauthorized"}}
  end

  # Handle incoming messages
  def handle_in(
        "new_message",
        %{"body" => %{"type" => "image", "data" => data} = image_data},
        socket
      ) do
    Logger.debug("Received image message")
    metadata = Map.take(image_data, ["width", "height", "size", "type", "filename"])
    broadcast_log({:image, data, metadata})
    broadcast!(socket, "new_message", %{body: image_data})
    {:reply, :ok, socket}
  end

  def handle_in(
        "new_message",
        %{"body" => %{"type" => "svg_path", "path" => path} = svg_data},
        socket
      ) do
    Logger.debug("Received SVG path message")
    metadata = Map.take(svg_data, ["width", "height", "viewBox"])
    broadcast_log({:svg_path, path, metadata})
    broadcast!(socket, "new_message", %{body: svg_data})
    {:reply, :ok, socket}
  end

  def handle_in("new_message", %{"body" => body} = payload, socket) when is_map(body) do
    Logger.debug("Received JSON message: #{inspect(body)}")
    formatted_json = Jason.encode!(body, pretty: true)
    broadcast_log({:json, formatted_json})
    broadcast!(socket, "new_message", payload)
    {:reply, :ok, socket}
  end

  def handle_in("new_message", %{"body" => body}, socket) do
    Logger.debug("Received message: #{body}")
    broadcast_log({:text, body})
    broadcast!(socket, "new_message", %{body: body})
    {:reply, :ok, socket}
  end

  def handle_in(_message, _params, socket) do
    Logger.debug("Received unknown message: #{_message}")
    broadcast_log({:text, "Received unknown message: #{_message}"})
    {:noreply, socket}
  end

  defp broadcast_log(message) do
    timestamp = NaiveDateTime.local_now()

    # Save to database
    {type, content} =
      case message do
        {:json, json} ->
          {"json", json}

        {:text, text} ->
          {"text", text}

        {:status, status} ->
          {"status", status}

        {:image, data, metadata} ->
          {"image", Jason.encode!(%{data: data, metadata: metadata})}

        {:svg_path, path, metadata} ->
          {"svg_path", Jason.encode!(%{path: path, metadata: metadata})}
      end

    %Message{}
    |> Message.changeset(%{
      type: type,
      content: content,
      timestamp: timestamp
    })
    |> Repo.insert()

    Phoenix.PubSub.broadcast(
      Logserver.PubSub,
      "log:messages",
      {:new_message, {timestamp, message}}
    )
  end
end
