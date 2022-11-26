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
          :pomodoro => Pomodoro.t()
        }

  @doc """
  Given a keyword of arguments, starts a #{GenServer} process linked to the
  current process.

  ### Args:

  * `id`: *(required)* string to identify a pomodoro struct.
  * `exercise`: *(optional)* an mount of time in minutes to set the time to
  spend on tasks.
  * `break`: *(optional)* an mount of time in minutes to set breaks duration.
  * `rounds`: *(optional)* the amount of rounds until the pomodoro stops.

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
      pomodoro: Pomodoro.new(id, opts)
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
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call(:pause, _from, %{pomodoro: %Pomodoro{} = pomodoro} = state) do
    %Pomodoro{} = pomodoro = Pomodoro.idle(pomodoro)

    state = %{state | pomodoro: pomodoro}

    {:reply, {:ok, state}, state}
  end
end
