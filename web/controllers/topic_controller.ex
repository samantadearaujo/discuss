defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic
  alias Discuss.Plugs.RequireAuth

  plug RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:edit, :update, :delete]

  def index(conn, _params) do
    topics = Repo.all(Topic)
    render conn, "index.html", topics: topics
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"topic" => topic}) do
    changeset =
      conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic created successfully")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  def show(conn, %{"id" => id}) do
    topic = Repo.get(Topic, id)
    render conn, "show.html", topic: topic
  end

  def edit(conn, %{"id" => id}) do
    topic = Repo.get(Topic, id)
    changeset = Topic.changeset(topic)

    render conn, "edit.html", topic: topic, changeset: changeset
  end

  def update(conn, %{"id" => id, "topic" => params}) do
    topic = Repo.get(Topic, id)
    changeset = Topic.changeset(topic, params)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic ##{id} updated successfully")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "edit.html", topic: topic, changeset: changeset
    end
  end

  def delete(conn, %{"id" => id}) do
    case Topic |> Repo.get!(id) |> Repo.delete do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic ##{id} destroyed successfully")
        |> redirect(to: topic_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "An error occurred. Try again")
        |> redirect(to: topic_path(conn, :index))
    end
  end

  defp check_topic_owner(%{params: %{"id" => id}} = conn, _params) do
    if conn.assigns.user.id == Repo.get(Topic, id).user_id do
      conn
    else
      conn
      |> put_flash(:error, "Good idea, but try it in another app")
      |> redirect(to: topic_path(conn, :index))
      |> halt
    end
  end
end
