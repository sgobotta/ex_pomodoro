defmodule ExPomodoro do
  @moduledoc """
  Documentation for `ExPomodoro`.
  """

  alias ExPomodoro.{
    Pomodoro,
    PomodoroServer,
    PomodoroSupervisor
  }

  @type success_response :: {:ok, Pomodoro.t()}
  @type started_response :: {:ok, {:started, pid()}}
  @type already_started_response :: {:noop, {:already_started, Pomodoro.t()}}
  @type already_finished_response :: {:ok, {:already_finished, Pomodoro.t()}}
  @type resumed_response :: {:ok, {:resumed, Pomodoro.t()}}
  @type not_found_response :: {:error, :not_found}

  @doc """
  Returns the `#{ExPomodoro}` child spec. It is intended for appliations to
  add an `#{ExPomodoro}` child spec to their application trees to have an
  `#{ExPomodoro.Supervisor}` started before interacting with the rest of the
  `#{ExPomodoro}` commands.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options \\ []), to: ExPomodoro.Supervisor

  @doc """
  This is the main function to start a pomodoro.

  Given an `id` and an optional keyword of options returns a successful response
  if a Pomodoro has been started or resumed. Every successful responses returns
  the current `#{Pomodoro}` struct.

  ### Options

  * `exercise_duration`: The duration in minutes of the exercise duration, `non_negative_integer()`.
  * `break_duration`: The duration in minutes of the break duration, `non_negative_integer()`.
  * `rounds`: The number of rounds until a long break, `non_negative_integer()`.

  ### Examples:

      # Start a pomodoro with default options.
      iex> ExPomodoro.start("some id")
      {:ok, %ExPomodoro.Pomodoro{
        id: "some id",
        activity: :exercise,
        exercise_duration: 1_500_000,
        break_duration: 300_000,
        rounds: 4
      }}

      # Start a pomodoro with some options.
      iex> ExPomodoro.start("some id", [
      ...>  exercise_duration: 150_000,
      ...>  break_duration: 25_000,
      ...>  rounds: 8
      ...> ])
      {:ok, %ExPomodoro.Pomodoro{
        id: "some id",
        activity: :exercise,
        exercise_duration: 150_000,
        break_duration: 25_000,
        rounds: 8
      }}

      # Start a pomodoro that is already running.
      iex> ExPomodoro.start("some_id")
      {:ok, {:already_started, %Pomodoro{id: "some id"}}}

      # Start a pomodoro that already finished.
      iex> ExPomodoro.start("some_id")
      {:ok, {:already_finished, %Pomodoro{id: "some id"}}}

      # Start a pomodoro that was paused or finished a break.
      iex> ExPomodoro.start("some_id")
      {:ok, {:resumed, %Pomodoro{id: "some id"}}}

  """
  @spec start(Pomodoro.id(), Pomodoro.opts()) ::
          success_response()
          | already_started_response()
          | already_finished_response()
          | resumed_response()
  def start(id, opts \\ []) do
    with {:ok, {:started, pid}} <- start_child(id, opts),
         {:ok, {^pid, %Pomodoro{} = pomodoro}} <- get_by_id(id) do
      {:ok, pomodoro}
    end
  end

  @doc """
  Generally this function is used to check whether a Pomodoro exists or not.

  Given an `id`, if a Pomodoro exists, a `#{Pomodoro}` struct is returned,
  othwerise returns an error tuple.

  ### Examples:

      # Return a pomodoro.
      iex> ExPomodoro.get("some id")
      {:ok, %ExPomodoro.Pomodoro{id: "some id"}}

      # Get a pomodoro that does not exist.
      iex> ExPomodoro.get("some other id")
      {:error, :not_found}

  """
  @spec get(Pomodoro.id()) :: success_response() | not_found_response()
  def get(id) do
    with {:ok, {_pid, %Pomodoro{} = pomodoro}} <- get_by_id(id) do
      {:ok, pomodoro}
    end
  end

  @doc """
  The Pomodoro timer can be paused using this function. While this function
  will cause a pomodoro to pause, it can still finish by timeout, defined in the
  `#{ExPomodoro.PomodoroServer}` implementation.

  Given an `id`, returns a `#{Pomodoro}` struct or an error tuple if the
  pomodoro does not exist.

  ### Examples:

      # Pause a pomodoro and returns the remaining timeleft to complete the
      # current activity.
      iex> ExPomodoro.pause("some id")
      {:ok, %Pomodoro{id: "some id", activity: :idle, current_duration: timeleft}}

      # Pause a pomodoro that does not exist.
      iex> ExPomodoro.pause("some id")
      {:error, :not_found}

  """
  @spec pause(Pomodoro.id()) :: success_response() | not_found_response()
  def pause(id) do
    with {:ok, {pid, %Pomodoro{}}} <- get_by_id(id),
         {:ok, %{id: ^id, pomodoro: %Pomodoro{} = pomodoro}} <-
           PomodoroServer.pause(pid) do
      {:ok, pomodoro}
    end
  end

  @spec get_by_id(Pomodoro.id()) ::
          {:ok, {pid(), Pomodoro.t()}} | not_found_response()
  defp get_by_id(id) do
    with {pid, %Pomodoro{id: ^id}} <- PomodoroSupervisor.get_child(id),
         %Pomodoro{} = pomodoro <- PomodoroServer.get_state(pid) do
      {:ok, {pid, pomodoro}}
    else
      nil ->
        {:error, :not_found}
    end
  end

  @spec start_child(Pomodoro.id(), Pomodoro.opts()) ::
          started_response()
          | already_started_response()
          | already_finished_response()
          | resumed_response()
  defp start_child(id, opts) do
    case get_by_id(id) do
      {:ok, {pid, %Pomodoro{activity: :idle}}} ->
        {:ok, %Pomodoro{} = pomodoro} = PomodoroServer.resume(pid)
        {:ok, {:resumed, pomodoro}}

      {:ok, {_pid, %Pomodoro{activity: :finished} = pomodoro}} ->
        {:ok, {:already_finished, pomodoro}}

      {:ok, {_pid, %Pomodoro{activity: activity} = pomodoro}}
      when activity in [:exercise, :work] ->
        {:noop, {:already_started, pomodoro}}

      {:error, :not_found} ->
        {:ok, pid} =
          PomodoroSupervisor.start_child(
            PomodoroSupervisor,
            Keyword.merge([id: id], opts)
          )

        {:ok, {:started, pid}}
    end
  end
end
