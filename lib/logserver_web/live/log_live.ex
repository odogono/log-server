defmodule LogserverWeb.LogLive do
  use LogserverWeb, :live_view
  require Logger
  alias Logserver.Repo
  alias Logserver.Logging.Message

  @impl true
  def mount(%{"room_id" => room_id} = _params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Logserver.PubSub, "log:messages:#{room_id}")
    end

    messages =
      Message.ordered_messages(room_id)
      |> Repo.all()
      |> Enum.map(fn msg ->
        {msg.timestamp, message_tuple(msg.type, msg.content)}
      end)

    {:ok, assign(socket, messages: messages, room_id: room_id)}
  end

  def mount(_params, _session, socket) do
    # Default to "lobby" if no room_id is provided
    mount(%{"room_id" => "lobby"}, _session, socket)
  end

  @impl true
  def handle_info({:new_message, {timestamp, message}}, socket) do
    messages = [{timestamp, message} | socket.assigns.messages]
    {:noreply, assign(socket, messages: messages)}
  end

  @impl true
  def handle_event("delete_message", %{"timestamp" => timestamp}, socket) do
    timestamp = NaiveDateTime.from_iso8601!(timestamp)

    Message.delete_message(timestamp, socket.assigns.room_id)
    |> Repo.delete_all()

    messages =
      Enum.reject(socket.assigns.messages, fn {msg_timestamp, _} ->
        NaiveDateTime.compare(msg_timestamp, timestamp) == :eq
      end)

    {:noreply, assign(socket, messages: messages)}
  end

  @impl true
  def handle_event("copy_message", %{"type" => type, "content" => content}, socket) do
    text =
      case type do
        "svg_path" ->
          path = Jason.decode!(content)["path"]
          metadata = Jason.decode!(content)["metadata"]

          """
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="#{metadata["width"] || 300}"
            height="#{metadata["height"] || 300}"
            viewBox="#{metadata["viewBox"] || "0 0 100 100"}"
          >
            <path
              d="#{path}"
              fill="none"
              stroke="black"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
          """

        "json" ->
          content

        "text" ->
          content

        "status" ->
          content

        "image" ->
          data = Jason.decode!(content)["data"]
          data
      end

    {:noreply, push_event(socket, "copy_to_clipboard", %{text: text})}
  end

  defp message_tuple("json", content), do: {:json, content}
  defp message_tuple("text", content), do: {:text, content}
  defp message_tuple("status", content), do: {:status, content}

  defp message_tuple("image", content) do
    parsed = Jason.decode!(content)
    {:image, parsed["data"], parsed["metadata"]}
  end

  defp message_tuple("svg_path", content) do
    parsed = Jason.decode!(content)
    {:svg_path, parsed["path"], parsed["metadata"]}
  end

  defp get_message_type(message) do
    case message do
      {:json, _} -> "json"
      {:text, _} -> "text"
      {:status, _} -> "status"
      {:image, _, _} -> "image"
      {:svg_path, _, _} -> "svg_path"
    end
  end

  defp get_message_content(message) do
    case message do
      {:json, content} -> content
      {:text, content} -> content
      {:status, content} -> content
      {:image, data, metadata} -> Jason.encode!(%{data: data, metadata: metadata})
      {:svg_path, path, metadata} -> Jason.encode!(%{path: path, metadata: metadata})
    end
  end

  defp format_size(size) when is_integer(size) do
    cond do
      size > 1_000_000 -> "#{Float.round(size / 1_000_000, 2)} MB"
      size > 1_000 -> "#{Float.round(size / 1_000, 2)} KB"
      true -> "#{size} bytes"
    end
  end

  defp format_size(_), do: "Unknown size"
end
