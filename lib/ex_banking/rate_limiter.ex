defmodule ExBanking.RateLimiter do
  @moduledoc """
  Handles user requests with auto sweeping ability
  """

  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def log_request(uid) do
    GenServer.call(__MODULE__, {:log_request, uid})
  end

  @impl true
  @spec init(any) :: {:ok, %{requests: %{}}}
  def init(_) do
    schedule_sweep()
    {:ok, %{requests: %{}}}
  end

  @impl true
  def handle_info(:sweep, state) do
    Logger.debug("Sweeping requests")
    schedule_sweep()
    {:noreply, %{state | requests: %{}}}
  end

  @impl true
  def handle_call({:log_request, uid}, _from, state) do
    max_requests = Application.get_env(:ex_banking, :max_requests)

    case state.requests[uid] do
      count when is_nil(count) or count < max_requests ->
        {:reply, :ok, put_in(state, [:requests, uid], (count || 0) + 1)}

      count when count >= max_requests ->
        {:reply, {:error, :too_many_requests_to_user}, state}
    end
  end

  defp schedule_sweep do
    sweep_after = Application.get_env(:ex_banking, :sweep_rate)
    sweep_after = :timer.seconds(sweep_after)

    Process.send_after(self(), :sweep, sweep_after)
  end
end
