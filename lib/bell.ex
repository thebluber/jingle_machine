defmodule Bell.Api do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Bell.Web, [])
    ]

    opts = [strategy: :one_for_one, name: Bell.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Bell.Web do
  use Plug.Router
  require Logger
  require System

  plug Plug.Logger
  plug :match
  plug :dispatch

  @files elem(File.ls("./sounds"), 1)

  def init(options) do
    options
  end

  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http Bell.Web, []
  end

  get "sounds/:id" do
    spawn fn -> System.cmd "mplayer", ["./sounds/#{Enum.at(@files, String.to_integer(id))}"] end
    conn
    |> send_resp(200, "ok")
  end

  get "sounds/" do
    page_content = EEx.eval_file("templates/sounds.eex", [files: @files])
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, page_content)
  end

  match _ do
    conn
    |> send_resp(404, "Nothing here")
    |> halt
  end
end
