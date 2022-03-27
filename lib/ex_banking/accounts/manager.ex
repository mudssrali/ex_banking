defmodule ExBanking.Accounts.Manager do
  @moduledoc """
  Provides functionality to manage user account
  """

  use GenServer
  require Logger

  alias ExBanking.Accounts.User

  @timeout :infinity
  @default_account %User{currencies: %{}}

  @impl true
  @spec init({user :: String.t()}) ::
          {:ok, {user :: String.t(), %User{}}, timeout :: :infinity}
  def init({user}) do
    Logger.debug("loading account for #{user}")

    # We don't have persistent storage yet from where
    # we can load user state, so empty state will serve
    # the purpose.
    account = %User{name: user}
    account = Map.merge(account, @default_account)

    Logger.debug("loaded account for #{user}")

    {:ok, {user, account}, @timeout}
  end

  @spec start_link({user :: String.t()}) :: :ignore | {:error, any} | {:ok, pid}
  def start_link({user}) do
    Logger.debug("initting account for #{user}")
    GenServer.start_link(__MODULE__, {user}, name: via(user))
  end

  @doc false
  @spec init_user_account(user :: String.t()) :: any
  def init_user_account(user) do
    account = %User{name: user}
    account = Map.merge(account, @default_account)
    store_changes(user, account)
  end

  @doc false
  @spec get_user_account(user :: String.t()) :: %User{}
  def get_user_account(user) do
    GenServer.call(via(user), {:get_user})
  end

  @doc false
  def store_changes(user, changes) do
    GenServer.call(via(user), {:store_changes, changes}, 30000)
  end

  @impl true
  def handle_call({:get_user}, _from, {_user, account} = state) do
    {:reply, account, state, @timeout}
  end

  @impl true
  def handle_call({:store_changes, changes}, _from, {user, _account} = _state) do
    {:reply, changes, {user, changes}, @timeout}
  end

  defp via(user) do
    {:via, Registry, {ExBanking.AccountsRegistry, user}}
  end
end
