defmodule TellerWeb.Router do
  use TellerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TellerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TellerWeb do
    pipe_through :browser

    live "/", TashAppLive, :index
    live "/amount", TashAppLive, :amount
    live "/pay", TashAppLive, :pay
    live "/activity", TashAppLive, :activity
  end
end
