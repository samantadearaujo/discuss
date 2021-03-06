defmodule Discuss.CommentChannel do
  @moduledoc """
    Channel to handle comments events using websockets
  """

  use Phoenix.Channel

  import Ecto.Query

  alias Discuss.Repo
  alias Discuss.Comment
  alias Discuss.Topic

  intercept ["new_comment"]

  def join("comment:all", _message, socket) do
    {:ok, socket}
  end

  def join("comment:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("load_comments", %{"topic_id" => topic_id}, socket) do
    %{user: current_user} = socket.assigns

    comments =
      Comment
      |> where(topic_id: ^topic_id)
      |> order_by(desc: :inserted_at)
      |> Repo.all
      |> Repo.preload(:user)

    comments_map = Enum.map comments, fn c ->
      comment_to_map(c, current_user)
    end

    push socket, "load_comments", %{comments: comments_map}
    {:noreply, socket}
  end

  def handle_in("new_comment", %{"content" => content} = payload, socket) do
    topic = Repo.get!(Topic, payload["topic_id"])
    %{user: current_user} = socket.assigns

    changeset =
      current_user
      |> Ecto.build_assoc(:comments, topic_id: topic.id)
      |> Comment.changeset(%{content: content})

    comment =
      changeset
      |> Repo.insert!
      |> Repo.preload(:user)

    broadcast! socket, "new_comment", comment_to_map(comment, current_user)
    {:noreply, socket}
  end

  def handle_in("remove_comment", %{"comment_id" => comment_id}, socket) do
    comment = Repo.get!(Comment, comment_id)

    if comment.user_id == socket.assigns.user.id do
      Repo.delete(comment)
    end

    push socket, "remove_comment", %{comment_id: comment_id}
    {:noreply, socket}
  end

  defp comment_to_map(comment, user) do
    %{
      id: comment.id,
      content: comment.content,
      inserted_at: Date.to_string(comment.inserted_at),
      user_email: comment.user.email,
      can_remove: comment.user_id == user.id
    }
  end

  def handle_out("new_comment", payload, socket) do
    push socket, "new_comment", payload
    {:noreply, socket}
  end
end
