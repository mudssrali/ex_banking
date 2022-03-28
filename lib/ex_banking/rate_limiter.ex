defmodule ExBanking.RateLimiter do
  @moduledoc """
  Handles user requests with auto sweeping ability
  """

  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec log_request( user :: String.t()) :: :ok | {:error, :too_many_requests_to_user}
  def log_request(user) do
    ets_table = get_ets_table()
    max_requests = Application.get_env(:ex_banking, :max_requests)

    case :ets.update_counter(ets_table, user, {2, 1}, {user, 0}) do
      count when count > max_requests -> {:error, :too_many_requests_to_user}
      _count -> :ok
    end
  end

  @impl true
  @spec init(any) :: {:ok, %{}}
  def init(_) do
    ets_table = get_ets_table()

    :ets.new(ets_table, [
      :set,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    schedule_sweep()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    Logger.debug("Sweeping requests")

    ets_table = get_ets_table()
    :ets.delete_all_objects(ets_table)

    schedule_sweep()

    {:noreply, state}
  end

  defp schedule_sweep do
    sweep_after = Application.get_env(:ex_banking, :sweep_rate)
    sweep_after = :timer.seconds(sweep_after)

    Process.send_after(self(), :sweep, sweep_after)
  end

  defp get_ets_table do
    Application.get_env(:ex_banking, :ets_table)
  end
end
