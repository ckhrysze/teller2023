defmodule TellerWeb.TashAppLive do
  @moduledoc """
  Handles all views within the Ta$h app. This would ideally be
  broken up into multiple modules, but for the sake of speed and
  state management has not yet been done.
  """

  use TellerWeb, :live_view

  def mount(_params, _, socket) do
    {:ok,
     socket
     |> assign(
       :credentials,
       to_form(%{
         "device_id" => nil,
         "username" => nil,
         "password" => nil
       })
     )}
  end

  def handle_params(_params, uri, socket) do
    uri
    |> String.split("/")
    |> Enum.reverse()
    |> hd()
    |> case do
      "activity" -> {:noreply, socket |> assign_activity()}
      "pay" -> {:noreply, socket |> assign_pay()}
      "amount" -> {:noreply, socket |> assign_amount()}
      _ -> {:noreply, socket}
    end
  end

  def assign_pay(socket) do
    socket
    |> assign(
      :payment,
      to_form(%{
        "amount" => nil,
        "payee" => nil,
        "note" => ""
      })
    )
  end

  def assign_activity(socket) do
    response =
      socket.assigns
      |> Teller.App.list_payments()

    payments = response.body

    socket |> assign(:payments, payments) |> assign(:response, response)
  end

  def assign_amount(socket) do
    socket
    |> assign(:amount, "0")
  end

  def handle_event("submit_credentials", params, socket) do
    {:ok, response} = Teller.App.login(params)

    {:noreply,
     socket
     |> assign(:response, response)
     |> assign(:device_id, params["device_id"])
     |> push_patch(to: "/amount")}
  end

  def handle_event("update_amount", params, socket) do
    amount =
      params
      |> Map.get("amount")
      |> case do
        nil -> socket.assigns.amount
        "-1" -> String.slice(socket.assigns.amount, 0..-2)
        value -> socket.assigns.amount <> value
      end
      |> String.trim_leading("0")

    {:noreply, socket |> assign(:amount, amount)}
  end

  def handle_event("submit_amount", params, socket) do
    IO.inspect(params)
    {:noreply, socket |> push_patch(to: "/pay")}
  end

  def handle_event("submit_pay", params, socket) do
    {:ok, response} = Teller.App.pay(params, socket.assigns)

    {:noreply,
     socket
     |> assign(:amount, "0")
     |> assign(:response, response)
     |> push_patch(to: "/amount")}
  end

  def handle_event("txn_activity", _, socket) do
    {:noreply, socket |> push_patch(to: "/activity")}
  end

  def handle_event("logout", _, socket) do
    {:noreply, socket |> assign(:user, nil) |> push_patch(to: "/")}
  end

  def handle_event("leave_activity", _, socket) do
    {:noreply, socket |> push_patch(to: "/amount")}
  end

  def handle_event("leave_pay", _, socket) do
    {:noreply, socket |> push_patch(to: "/amount")}
  end

  attr :amount, :integer, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def numpad_btn(assigns) do
    ~H"""
    <div class="h-20 w-24 text-white text-2xl text-center" phx-click="update_amount" phx-value-amount={@amount}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def render(%{live_action: :activity} = assigns) do
    ~H"""
    <div class="p-4 bg-emerald-700 w-full h-screen flex flex-col items-center gap-4">
      <div class="w-full px-2 mt-4 flex flex-row justify-between items-center">
          <button type="button" phx-click="leave_activity" class="px-3 py-2 bg-gray-200 bg-opacity-40 hover:bg-opacity-60 rounded-full font-semibold text-sm text-center align-middle transition-colors">
            Back
          </button>
      </div>
      <table class="w-full">
        <tr>
          <th>Payee</th>
          <th>Amount</th>
          <th>Note</th>
        </tr>
        <tr :for={payment <- @payments}>
          <td><%= payment["payee"] %></td>
          <td><%= payment["amount"] %>¢</td>
          <td><%= payment["note"] %></td>
        </tr>
      </table>
    </div>
    """
  end

  def render(%{live_action: :pay} = assigns) do
    ~H"""
    <.form for={@payment} phx-submit="submit_pay">
      <div class="p-4 w-full h-screen flex flex-col items-center gap-4">
        <div class="w-full flex">
          <button type="button" phx-click="leave_pay"
            class="h-8 w-8 bg-gray-200 bg-opacity-40 hover:bg-opacity-80 active:bg-opacity-100 rounded-full font-bold text-xl text-center align-middle transition-colors">
            <.icon name="hero-x-mark-solid" class="h-5 w-5" />
          </button>
          <div class="flex-1 text-center"><%= @amount %>¢</div>
          <.button>Pay</.button>
        </div>

        <div class="w-full">
          <.input field={@payment[:amount]} value={@amount} type="hidden" />
          <.input field={@payment[:payee]} placeholder="Payee email" type="email" />
          <.input field={@payment[:note]} placeholder="note" />
        </div>
      </div>
    </.form>
    """
  end

  def render(%{live_action: :amount} = assigns) do
    ~H"""
    <form phx-submit="submit_amount">
      <div class="p-4 bg-emerald-700 w-full h-screen flex flex-col items-center gap-4">

        <div class="w-full px-2 mt-4 flex flex-row justify-between items-center">
          <button type="button" phx-click="logout" class="px-3 py-2 bg-gray-200 bg-opacity-40 hover:bg-opacity-60 rounded-full font-semibold text-sm text-center align-middle transition-colors">
            Log out
          </button>
          <button type="button" phx-click="txn_activity" class="px-3 py-2 bg-gray-200 bg-opacity-40 hover:bg-opacity-60 rounded-full font-semibold text-sm text-center align-middle transition-colors">
            Activity
          </button>
        </div>

        <div class="w-full text-center">
          <h1 class="font-semibold text-3xl text-white mt-16"><%= @amount %>¢</h1>
        </div>

        <div class="flex-1">&nbsp;</div>

        <div class="w-full grid grid-cols-3">
          <.numpad_btn amount={1}>1</.numpad_btn>
          <.numpad_btn amount={2}>2</.numpad_btn>
          <.numpad_btn amount={3}>3</.numpad_btn>
          <.numpad_btn amount={4}>4</.numpad_btn>
          <.numpad_btn amount={5}>5</.numpad_btn>
          <.numpad_btn amount={6}>6</.numpad_btn>
          <.numpad_btn amount={7}>7</.numpad_btn>
          <.numpad_btn amount={8}>8</.numpad_btn>
          <.numpad_btn amount={9}>9</.numpad_btn>
          <.numpad_btn>.</.numpad_btn>
          <.numpad_btn amount={0}>0</.numpad_btn>
          <.numpad_btn amount={-1}><.icon name="hero-chevron-left" /></.numpad_btn>
        </div>

        <div class="w-full">
          <.button class="w-full">Pay</.button>
        </div>

      </div>
    </form>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.form for={@credentials} phx-submit="submit_credentials">
      <div class="h-full w-full flex flex-col items-center gap-4">
        <div class="w-full flex">
          <div class="flex-1">&nbsp;</div>
            <button type="button" title="I am literally useless.. unless 😳"
              class="h-8 w-8 bg-gray-200 bg-opacity-40 hover:bg-opacity-80 active:bg-opacity-100 rounded-full font-bold text-xl text-center align-middle transition-colors">
              ?
            </button>
          </div>

          <div class="w-full text-center">
            <h1 class="font-semibold text-2xl">Enter your credentials</h1>
          </div>

          <div class="w-full">
            <.input field={@credentials[:device_id]} placeholder="Device ID" value="KQ4ZXMLLVCJ5ZM7Z" />
            <.input field={@credentials[:username]} placeholder="Username" value="red_daisy" />
            <.input field={@credentials[:password]} placeholder="Password" type="password" />
          </div>

          <div class="w-full">
            <.button class="w-full">Sign In</.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
