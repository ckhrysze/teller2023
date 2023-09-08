defmodule TellerAPI do
  use Tesla

  def client(headers) do
    middlware = [
      {Tesla.Middleware.BaseUrl, "https://orlando.teller.engineering"},
      {Tesla.Middleware.Headers,
       [
         {"user-agent", "Ta$h/1.0"},
         {"api-key", "Hello-Orlando!"},
         {"accept", "application/json"}
       ] ++ headers},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middlware)
  end

  def config(), do: client([]) |> get("/config")

  def signin(headers, username, password) do
    headers
    |> client()
    |> post("/signin", %{
      password: password,
      username: username
    })
  end

  def mfa_request(headers, device_id) do
    headers
    |> client()
    |> post("/signin/mfa/request", %{device_id: device_id})
  end

  def mfa_verify(headers) do
    headers
    |> client()
    |> post("/signin/mfa/verify", %{code: "001337"})
  end

  def payees(headers) do
    headers
    |> client()
    |> get("/payees")
  end

  def list_payments(headers) do
    headers
    |> client()
    |> get("/payments")
  end

  def pay(headers, id, address, amount) do
    headers
    |> client()
    |> IO.inspect()
    |> post(
      "/payments",
      %{
        amount: amount,
        idempotency_key: id,
        note: "",
        payee: address
      }
    )
  end

  def add_contact(headers, email) do
    headers
    |> client()
    |> post("/payees", %{name: "Samara Pollich", address: "samara.pollich@example.net"})
  end
end
