defmodule ExPomodoro.PomodoroServer do
  @moduledoc """
  The Pomodoro Server implementation
  """
  use GenServer, restart: :transient

  alias ExPomodoro.Pomodoro

  require Logger

  @type init_args :: [
          id: Pomodoro.id(),
          exercise: non_neg_integer(),
          break: non_neg_integer(),
          rounds: non_neg_integer()
        ]

  @type state :: %{
          :activity_ref => reference() | nil,
          :id => Pomodoro.id(),
          :pomodoro => Pomodoro.t(),
          :previous_activity => Pomodoro.activity() | nil,
          :previous_activity_timeleft => non_neg_integer() | nil,
          :timeout => non_neg_integer(),
          :timeout_ref => reference() | nil
        }

  @timeout :timer.minutes(90)

  # ----------------------------------------------------------------------------
  # GenServer interface
  #

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
  Given a pid, pauses a pomodoro and returns the current pomodoro state.
  """
  @spec pause(pid()) :: {:ok, state()}
  def pause(pid) do
    GenServer.call(pid, :pause)
  end

  @doc """
  Given a pid, resumes a pomodoro and returns the current pomodoro state.
  """
  @spec resume(pid()) :: {:ok, state()}
  def resume(pid) do
    GenServer.call(pid, :resume)
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
      activity_ref: nil,
      id: id,
      pomodoro: Pomodoro.new(id, opts),
      previous_activity: nil,
      previous_activity_timeleft: nil,
      timeout: Keyword.get(opts, :timeout, @timeout),
      timeout_ref: nil
    }
  end

  # ----------------------------------------------------------------------------
  # GenServer implementation
  #

  @impl GenServer
  def init(init_args) do
    :ok =
      Logger.debug(
        "#{__MODULE__} :: Started process with pid=#{inspect(self())}, args=#{inspect(init_args)}"
      )

    {:ok, initial_state(init_args), {:continue, init_args}}
  end

  @impl GenServer
  def handle_continue(_init_args, state) do
    {:noreply, schedule_timers(state)}
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
  def handle_call(:pause, _from, state) do
    state =
      state
      |> pause_pomodoro()
      |> schedule_timers()

    {:reply, {:ok, state.pomodoro}, state}
  end

  @impl GenServer
  def handle_call(:resume, _from, state) do
    state =
      state
      |> resume_pomodoro()
      |> schedule_timers()

    {:reply, {:ok, state.pomodoro}, state}
  end

  @impl GenServer
  def handle_info(
        :on_activity_change,
        %{pomodoro: %Pomodoro{activity: :exercise} = pomodoro} = state
      ) do
    :ok =
      Logger.debug(
        "#{__MODULE__} :: Activity change activity=break pid=#{inspect(self())}"
      )

    state = %{state | pomodoro: Pomodoro.break(pomodoro)}

    {:noreply, schedule_timers(state)}
  end

  @impl GenServer
  def handle_info(
        :on_activity_change,
        %{pomodoro: %Pomodoro{activity: :break} = pomodoro} = state
      ) do
    :ok =
      Logger.debug(
        "#{__MODULE__} :: Activity change activity=idle pid=#{inspect(self())}"
      )

    state = %{state | pomodoro: Pomodoro.idle(pomodoro)}

    {:noreply, schedule_timers(state)}
  end

  @impl GenServer
  def handle_info(:kill, state) do
    :ok =
      Logger.debug(
        "#{__MODULE__} :: Terminating process with pid=#{inspect(self())}"
      )

    true = Process.exit(self(), :normal)

    {:noreply, state}
  end

  # ----------------------------------------------------------------------------
  # State helpers
  #

  defp pause_pomodoro(
         %{
           activity_ref: activity_ref,
           pomodoro: %Pomodoro{activity: activity} = pomodoro
         } = state
       )
       when is_reference(activity_ref) do
    timeleft = Process.cancel_timer(activity_ref)

    %Pomodoro{} = pomodoro = Pomodoro.idle(pomodoro)

    pomodoro = %Pomodoro{pomodoro | current_duration: timeleft}

    %{
      state
      | activity_ref: nil,
        pomodoro: pomodoro,
        previous_activity: activity
    }
  end

  defp resume_pomodoro(
         %{
           activity_ref: nil,
           pomodoro: %Pomodoro{} = pomodoro,
           previous_activity: previous_activity
         } = state
       ) do
    %Pomodoro{} =
      pomodoro =
      case previous_activity do
        :exercise ->
          Pomodoro.exercise(pomodoro)

        :break ->
          Pomodoro.break(pomodoro)
      end

    %{state | pomodoro: pomodoro, previous_activity: nil}
  end

  # ----------------------------------------------------------------------------
  # Schedule helpers
  #

  defp schedule_timers(state) do
    state
    |> schedule_timeout()
    |> schedule_pomodoro()
  end

  defp schedule_pomodoro(
         %{
           activity_ref: nil,
           pomodoro: %Pomodoro{activity: :exercise} = pomodoro,
           previous_activity_timeleft: previous_activity_timeleft
         } = state
       )
       when is_integer(previous_activity_timeleft) do
    %Pomodoro{current_duration: current_duration} = pomodoro

    %{
      state
      | activity_ref: send_activity_change(current_duration)
    }
  end

  defp schedule_pomodoro(
         %{
           pomodoro: %Pomodoro{activity: :exercise} = pomodoro,
           activity_ref: nil
         } = state
       ) do
    %Pomodoro{exercise_duration: exercise_duration} = pomodoro

    %{
      state
      | activity_ref: send_activity_change(exercise_duration)
    }
  end

  defp schedule_pomodoro(
         %{
           pomodoro: %Pomodoro{activity: :exercise} = pomodoro,
           activity_ref: activity_ref
         } = state
       )
       when is_reference(activity_ref) do
    _timeleft = Process.cancel_timer(activity_ref)

    %Pomodoro{exercise_duration: exercise_duration} = pomodoro

    %{
      state
      | activity_ref: send_activity_change(exercise_duration)
    }
  end

  defp schedule_pomodoro(
         %{
           activity_ref: nil,
           pomodoro: %Pomodoro{activity: :break} = pomodoro,
           previous_activity_timeleft: previous_activity_timeleft
         } = state
       )
       when is_integer(previous_activity_timeleft) do
    %Pomodoro{break_duration: break_duration} = pomodoro

    %{
      state
      | activity_ref: send_activity_change(break_duration)
    }
  end

  defp schedule_pomodoro(
         %{pomodoro: %Pomodoro{activity: :break} = p, activity_ref: nil} = state
       ) do
    %Pomodoro{break_duration: break_duration} = p

    %{
      state
      | activity_ref: send_activity_change(break_duration)
    }
  end

  defp schedule_pomodoro(
         %{
           pomodoro: %Pomodoro{activity: :break} = pomodoro,
           activity_ref: activity_ref
         } = state
       )
       when is_reference(activity_ref) do
    _timeleft = Process.cancel_timer(activity_ref)

    %Pomodoro{break_duration: break_duration} = pomodoro

    %{
      state
      | activity_ref: send_activity_change(break_duration)
    }
  end

  # Pomodoro was paused, the activity_ref was assigned to nil
  defp schedule_pomodoro(
         %{
           pomodoro: %Pomodoro{
             activity: :idle,
             current_duration: current_duration
           },
           activity_ref: nil
         } = state
       ) do
    %{
      state
      | activity_ref: nil,
        previous_activity_timeleft: current_duration
    }
  end

  # Pomodoro finished a break, activity_ref corresponds to the break timer
  defp schedule_pomodoro(
         %{pomodoro: %Pomodoro{activity: :idle}, activity_ref: activity_ref} =
           state
       )
       when is_reference(activity_ref) do
    %{
      state
      | activity_ref: nil
    }
  end

  defp schedule_timeout(%{timeout: timeout, timeout_ref: nil} = state),
    do: %{state | timeout_ref: send_kill(timeout)}

  defp schedule_timeout(%{timeout: timeout, timeout_ref: timeout_ref} = state)
       when is_reference(timeout_ref) do
    _timeleft = Process.cancel_timer(timeout_ref)

    %{state | timeout_ref: send_kill(timeout)}
  end

  # ----------------------------------------------------------------------------
  # Send message helpers
  #

  defp send_kill(time), do: Process.send_after(self(), :kill, time)

  defp send_activity_change(time),
    do: Process.send_after(self(), :on_activity_change, time)
end
