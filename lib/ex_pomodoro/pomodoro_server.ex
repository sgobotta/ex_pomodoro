defmodule ExPomodoro.PomodoroServer do
  @moduledoc """
  The Pomodoro Server implementation
  """
  use GenServer, restart: :transient

  alias ExPomodoro.Pomodoro

  require Logger

  @type init_args :: [
          id: String.t(),
          exercise: non_neg_integer(),
          break: non_neg_integer(),
          rounds: non_neg_integer()
        ]

  @type state :: %{
          :id => binary(),
          :pomodoro => Pomodoro.t(),
          :timeout => non_neg_integer(),
          :timeout_ref => reference() | nil
        }

  @timeout :timer.minutes(90)

  @doc """
  Given a keyword of arguments, starts a #{GenServer} process linked to the
  current process.

  ### Args:

  * `id`: *(required)* unique string to identify a pomodoro struct.
  * `exercise`: *(optional)* an integer that represents the duration of the time
  spent on exercise in milliseconds.
  * `break`: *(optional)* an integer that represents the break duration in
  milliseconds.
  * `rounds`: *(optional)* an integer that represents the amount of rounds until
  the pomodoro stops.
  * `timeout`: *(optional)* milliseconds until the server is terminated by
  inactiviy.

  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @doc """
  Given a pid, returns the current state.
  """
  @spec get_state(pid()) :: state()
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  @doc """
  Given a pid, pauses a pomodoro and returns the current state.
  """
  @spec pause(pid()) :: {:ok, state()}
  def pause(pid) do
    GenServer.call(pid, :pause)
  end

  @doc """
  Given a keyword of args returns a new map that represents the #{__MODULE__}
  state.
  """
  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    id = Keyword.fetch!(opts, :id)
    opts = Keyword.delete(opts, :id)

    %{
      id: id,
      pomodoro: Pomodoro.new(id, opts),
      timeout: Keyword.get(opts, :timeout, @timeout),
      timeout_ref: nil
    }
  end

  @impl GenServer
  def init(init_args) do
    :ok =
      Logger.info(
        "#{__MODULE__} :: Started process with pid=#{inspect(self())}, args=#{inspect(init_args)}"
      )

    {:ok, initial_state(init_args), {:continue, init_args}}
  end

  @impl GenServer
  def handle_continue(_init_args, state) do
    {:noreply, schedule_timeout(state)}
  end

  @impl GenServer
  def handle_call(
        :get_state,
        _from,
        %{pomodoro: %Pomodoro{} = pomodoro} = state
      ) do
    {:reply, pomodoro, state}
  end

  @impl GenServer
  def handle_call(:pause, _from, %{pomodoro: %Pomodoro{} = pomodoro} = state) do
    %Pomodoro{} = pomodoro = Pomodoro.idle(pomodoro)

    state = %{state | pomodoro: pomodoro}

    {:reply, {:ok, pomodoro}, state}
  end

  @impl GenServer
  def handle_info(:kill, state) do
    :ok =
      Logger.info(
        "#{__MODULE__} :: Terminating process with pid=#{inspect(self())}"
      )

    true = Process.exit(self(), :normal)

    {:noreply, state}
  end

  defp schedule_timeout(%{timeout: timeout, timeout_ref: nil} = state),
    do: %{state | timeout_ref: Process.send_after(self(), :kill, timeout)}

  defp schedule_timeout(%{timeout: timeout, timeout_ref: timeout_ref} = state) do
    _timeleft = Process.cancel_timer(timeout_ref)

    %{state | timeout_ref: Process.send_after(self(), :kill, timeout)}
  end
end
