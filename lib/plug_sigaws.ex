defmodule PlugSigaws do
  @moduledoc """
  Plug to authenticate HTTP requests that have been signed using AWS Signature V4.

  (Refer to this [Blog post](https://handnot2.github.io/blog/elixir/aws-signature-sigaws))

  ### Plug Pipeline Setup

  This plug relies on `sigaws` library to verify the signature. When the
  signature verification fails, further pipeline processing is halted.
  Upon successful signature verification, an "assign" (`:sigaws_ctxt`)
  is setup in the returned connection containing the verification context. 

  Edit your `router.ex` file and add this plug to the appropriate pipeline.

  ```elixir
  pipeline :api do
    plug :accepts, ["json"]
    plug PlugSigaws
  end
  ```

  You can use this plug to secure access to non-api resources as well using
  "presigned URLs".

  ### Content Parser Setup

  The signature verification process involves computing the hash digest of the
  request body in its raw form. Given the Plug restriction that the request body
  can be read only once, it is imperative that any content parsers used in
  the Plug pipeline make the raw content available for hash computation.

  Edit the `endpoint.ex` file and replace the `:json` and `:urlencoded` parsers
  with the corresponding `PlugSigaws` versions that make the raw content
  available for hash computation.

  ```elixir
  plug Plug.Parsers,
    parsers: [PlugSigaws.Parsers.JSON, PlugSigaws.Parsers.URLENCODED, :multipart],
    pass: ["*/*"],
    json_decoder: Poison
  ```

  > This plug checks for `conn.assigns[:raw_body]` in the connection. Any
  > content parser plug present before this plug that consumes the request body
  > should make the raw content available in the `:raw_body` assign. **Without this
  > the signature verification may fail.**
  >
  > If the raw body is not available as an assign, this plug will read the request
  > body by calling `Plug.Conn.read_body/2` and make it available in the assign
  > for subsequent consumption in the pipeline.

  ### Quickstart Verification Provider

  Verifying the signature involves making sure that the region/service used
  in the signature are valid for the server hosting the service. It also
  involves recomputing the signature from the request data and comparing
  against what is passed in.

  The `sigaws` package includes a "quickstart" provider that can be used to
  quickly try out signature verification. **You need three things to make
  use of this provider**:

  1.    Add the quick start provider to the project dependencies.

        ```elixir
        defp deps do
          {:sigaws_quickstart_provider, "~> 0.1"}
        end
        ```

  2.    Add this provider to your supervision tree. This is needed so that
        the credentials can be read from a file. 

        ```elixir
        use Application
        def start(_type, _args) do
          import Supervisor.Spec

          children = [
            worker(SigawsQuickStartProvider, [[name: :sigaws_provider]]),
            # ....
          ]

          # ....
          Supervisor.start_link(children, opts)
        end
        ```

  3.    Add the following to your `config.exs`:

        ```elixir
        config :plug_sigaws,
          provider: SigawsQuickStartProvider

        config :sigaws_quickstart_provider,
          regions: "us-east-1,alpha-quad,beta-quad,gamma-quad,delta-quad",
          services: "my-service,img-service",
          creds_file: "sigaws_quickstart.creds"
        ```

  The quickstart provider configuration parameters:

  -    `regions` -- Set this to a comma separated list of region names.
       For example, `us-east-1,gamma-quad,delta-quad`.
       A request signed with a region not in this list will fail.

  -    `services` -- Set this to a comma separated list of service names.
       Just as the was case with regions, a request
       signed with a service not in this list will fail.

  -    `creds_file` -- Path to the credentials file. The quickstart provider
       reads this file to get the list of valid access key IDs and their
       corresponding secrets. Each line in this file represents a valid
       credential with a colon separating the access key ID and the secret.

  Here are the defaults used when any of these environment variables is not set:

  | Parameter | Default |
  |:-------- |:------- |
  | `regions` | `us-east-1` |
  | `services` | `my-service` |
  | `creds_file` | `sigaws_quickstart.creds` in the current working directory|

  ### Build your own Verification Provider
  
  Most probably you want the access key ID/secrets stored in a database or some
  other external system.
  
  > Use `SigawsQuickStartProvider` (a separate Hex package) as a starting point
  > and build your own provider.
  
  Configure `plug_sigaws` to use your provider instead of the quickstart provider.
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  @doc """
  Performs AWS Signature verification using the request data in the connection.

  Upon success, verification information is made available in an assign called
  `:sigaws_ctxt`.

  Failure results in an HTTP `401` response.
  """
  def call(conn, _opts) do
    {conn, body} =
      if conn.assigns[:raw_body] != nil do
        {conn, conn.assigns[:raw_body]}
      else
        {:ok, body, conn} = conn |> read_body()
        {conn |> assign(:raw_body, body), body}
      end

    provider = Application.get_env(:plug_sigaws, :provider)
    unless provider do
      Logger.log(:error, "ERROR: plug_sigaws provider config not set")
    end

    verification_opts = [
      provider: provider,
      method: conn.method,
      headers: conn.req_headers,
      params: conn.query_params,
      body: body
    ]

    verification_result = Sigaws.verify(conn.request_path, verification_opts)

    case verification_result do
      {:ok, %Sigaws.Ctxt{} = ctxt} ->
        assign(conn, :sigaws_ctxt, ctxt)
      {:error, error, info} when is_atom(error) ->
        msg = "#{Atom.to_string(error)}: #{inspect info}"
        conn |> resp(401, msg) |> halt()
      {:error, msg} -> conn |> resp(401, msg) |> halt()
    end
  rescue
    error ->
      conn
      |> resp(401, "Authorization Failed: #{inspect error}")
      |> halt()
  end
end
