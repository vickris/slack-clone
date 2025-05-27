defmodule SlackCloneWeb.UploadController do
  use SlackCloneWeb, :controller

  def show(conn, params) do
    IO.inspect(params, label: "UploadController params")
    %{"path" => path} = params
    file_path = Path.join(["priv/static/uploads", path])

    if File.exists?(file_path) do
      conn
      |> put_resp_header("content-disposition", "inline")
      |> send_file(200, file_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end
end
