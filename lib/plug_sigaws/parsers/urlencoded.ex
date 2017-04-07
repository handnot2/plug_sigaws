defmodule PlugSigaws.Parsers.URLENCODED do
  @moduledoc """
  Parses urlencoded request body.

  > Raw content is made available in `conn.assigns[:raw_body]`
  """

  @behaviour Plug.Parsers
  alias Plug.Conn
  alias Plug.Conn.Utils
  alias Plug.Conn.Query
  alias Plug.Parsers

  def parse(conn, "application", "x-www-form-urlencoded", _headers, opts) do
    case Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        Utils.validate_utf8!(body, Parsers.BadEncodingError, "urlencoded body")
        conn = conn |> Conn.assign(:raw_body, body)
        {:ok, Query.decode(body), conn}
      {:more, _data, conn} ->
        {:error, :too_large, conn}
      {:error, :timeout} ->
        raise Plug.TimeoutError
      {:error, _} ->
        raise Plug.BadRequestError
    end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
