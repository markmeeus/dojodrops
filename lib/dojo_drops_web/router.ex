defmodule DojoDropsWeb.Router do
  use DojoDropsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DojoDropsWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/:drop_id", DropController, :home
    get "/:drop_id/*resource_name", DropController, :resource
  end

  # Other scopes may use custom stacks.
  # scope "/api", DojoDropsWeb do
  #   pipe_through :api
  # end
end
