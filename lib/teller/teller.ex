defmodule Teller.App do
  # TODO: figure out how to use config to generate
  @mypassword "qKECKB\\O"

  def login(params) do
    headers = [{"device-id", params["device_id"]}]

    {:ok, %{body: body} = response} = TellerAPI.signin(headers, params["username"], @mypassword)
    sms_device = Enum.find(body["data"]["devices"], fn device -> device["type"] == "SMS" end)

    headers = headers ++ [{"teller-is-hiring", "I know!"}]

    {:ok, response} =
      (headers ++ [{"r-token", Tesla.get_header(response, "r-token")}])
      |> TellerAPI.mfa_request(sms_device["id"])

    {:ok, response} =
      (headers ++ [{"r-token", Tesla.get_header(response, "r-token")}])
      |> TellerAPI.mfa_verify()

    # TODO: figure out how to extract balance from payload

    {:ok, response}
  end

  def list_payments(params) do
    response = params.response
    r_token = Tesla.get_header(response, "r-token")
    s_token = Tesla.get_header(response, "s-token")

    headers =
      [
        {"device-id", params.device_id},
        {"teller-is-hiring", "I know!"},
        {"r-token", r_token},
        {"s-token", s_token}
      ]

    {:ok, response} = TellerAPI.list_payments(headers)

    response
  end

  def pay(params, assigns) do
    response = assigns.response

    {:ok, response} =
      [
        {"device-id", assigns.device_id},
        {"teller-is-hiring", "I know!"},
        {"r-token", Tesla.get_header(response, "r-token")},
        {"s-token", Tesla.get_header(response, "s-token")}
      ]
      |> TellerAPI.payees()

    challenge = Tesla.get_header(response, "challenge")

    # TODO: check if payee already exists in address book

    [
      {"device-id", assigns.device_id},
      {"teller-is-hiring", "I know!"},
      {"r-token", Tesla.get_header(response, "r-token")},
      {"s-token", Tesla.get_header(response, "s-token")},
      {"challenge", challenge},
      {"challenge-answer", Teller.Challenge.answer(challenge)}
    ]
    |> TellerAPI.pay(
      UUID.uuid1(),
      params["payee"],
      params["amount"]
    )
  end
end
