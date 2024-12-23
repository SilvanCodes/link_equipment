defmodule LinkEquipmentWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use LinkEquipmentWeb, :controller
      use LinkEquipmentWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Phoenix.Controller
      import Phoenix.LiveView.Router

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: LinkEquipmentWeb.Layouts]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LinkEquipmentWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # application components
      import LinkEquipmentWeb.Components

      # Core UI components and translation
      import LinkEquipmentWeb.CoreComponents

      # Layouting components
      import Phexel

      # HTML escaping functionality
      import Phoenix.HTML

      # helpful stuff for sockets
      import Util.Phoenix

      # helpful stuff for ok/error
      import Util.Result, only: [ok: 1, error: 1]

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # helpful stuff for any()/nil
      alias Util.Option

      # helpful stuff for ok/error
      alias Util.Result

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: LinkEquipmentWeb.Endpoint,
        router: LinkEquipmentWeb.Router,
        statics: LinkEquipmentWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
