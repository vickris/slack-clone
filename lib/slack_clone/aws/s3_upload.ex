defmodule SlackClone.Aws.S3Upload do
  @moduledoc """
  Handles direct S3 uploads with pre-signed URLs
  """

  alias ExAws.S3

  def generate_presigned_url(filename, content_type) do
    bucket = Application.get_env(:slack_clone, :s3_bucket)
    key = "uploads/#{Ecto.UUID.generate()}/#{filename}"

    IO.inspect({bucket, key, content_type}, label: "S3 Upload Params")

    case S3.presigned_url(ExAws.Config.new(:s3), :put, bucket, key, content_type: content_type) do
      {:ok, url} ->
        {:ok, url, key}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def construct_public_url(key) do
    bucket = Application.get_env(:slack_clone, :s3_bucket)
    region = Application.get_env(:ex_aws, :region)
    "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
  end
end
