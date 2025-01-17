defmodule ThundermoonWeb.ChatLive.Index do
  use ThundermoonWeb, :live_view

  import Canada.Can

  alias Phoenix.PubSub

  alias Thundermoon.Accounts
  alias Thundermoon.ChatMessages

  alias ThundermoonWeb.Presence

  alias ThundermoonWeb.ChatLive.Message

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user(session["current_user_id"])
    if connected?(socket), do: subscribe(user)
    messages = ChatMessages.list()
    users = get_users(Presence.list("chat"))
    {:ok, assign(socket, current_user: user, version: 0, messages: messages, users: users)}
  end

  def handle_event("clear", _value, socket) do
    if socket.assigns.current_user |> can?(:delete, ChatMessages) do
      ChatMessages.clear()
      PubSub.broadcast(ThundermoonWeb.PubSub, "chat", :clear)
    end

    {:noreply, socket}
  end

  # this is triggered by the live_view event phx-submit
  @impl true
  def handle_event("send", %{"message" => %{"text" => text}}, socket) do
    user = socket.assigns.current_user
    message = %{user: user.username, text: text, user_id: user.id}
    ChatMessages.add(message)
    PubSub.broadcast(ThundermoonWeb.PubSub, "chat", {:send, message})
    {:noreply, assign(socket, %{version: System.unique_integer()})}
  end

  # this is triggered by the pubsub broadcast event
  @impl true
  def handle_info({:send, message}, socket) do
    messages = [message | socket.assigns.messages]
    {:noreply, assign(socket, %{messages: messages})}
  end

  @impl true
  def handle_info(:clear, socket) do
    {:noreply, assign(socket, %{messages: []})}
  end

  # this is triggered if someone leaves or joins the chat
  @impl true
  def handle_info(
        %{
          event: "presence_diff",
          topic: "chat",
          payload: _payload
        },
        socket
      ) do
    users = get_users(Presence.list("chat"))

    {:noreply, assign(socket, %{users: users})}
  end

  defp subscribe(user) do
    PubSub.subscribe(ThundermoonWeb.PubSub, "chat")
    Presence.track(self(), "chat", user.id, %{user: user})
  end

  defp get_users(list) do
    list
    |> Map.values()
    |> Enum.map(&Map.get(&1, :metas))
    |> Enum.map(&List.first(&1))
    |> Enum.map(&Map.get(&1, :user))
  end
end
