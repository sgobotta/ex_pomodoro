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
  @type already_started_response :: {:error, {:already_started, Pomodoro.t()}}
  @type not_found_response :: {:error, :not_found}

  @doc """
  Returns the `#{ExPomodoro}` child spec. It is intended for appliations to
  add an `#{ExPomodoro}` child spec to their application trees to have an
  `#{ExPomodoro.Supervisor}` started before interacting with the rest of the
  `#{ExPomodoro}` commands.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: ExPomodoro.Supervisor

  @doc """
  This is the main function to start a pomodoro.

  Given an `id` and a keyword of options returns a successful response if a
  Pomodoro has been started or a failed response if a Pomodoro with that `id`
  has been found. Either the successful or the failed repsonse returns the
  current `#{Pomodoro}` struct.

  ### Options

  * `exercise_duration`: The duration in minutes of the exercise duration, `non_negative_integer()`.
  * `break_duration`: The duration in minutes of the break duration, `non_negative_integer()`.
  * `rounds`: The number of rounds until a long break, `non_negative_integer()`.

  ### Examples:

      iex> ExPomodoro.start("some id", [])
      {:ok, %ExPomodoro.Pomodoro{id: "some id", activity: :exercise}}

      iex> ExPomodoro.start("some_id", [])
      {:error, {:already_started, %Pomodoro{id: "some id"}}}

  """
  @spec start(Pomodoro.id(), Pomodoro.opts()) ::
          success_response() | already_started_response()
  def start(id, opts) do
    with {:ok, pid} <- start_child(id, opts),
         {:ok, {^pid, %Pomodoro{} = pomodoro}} <- get_by_id(id) do
      {:ok, pomodoro}
    end
  end

  @doc """
  Generally this function is used to check whether a Pomodoro exists or not.

  Given an `id`, if a Pomodoro exists, a `#{Pomodoro}` struct is returned,
  othwerise returns an error tuple.

  ### Examples:

      iex> ExPomodoro.get("some id")
      {:ok, %ExPomodoro.Pomodoro{id: "some id"}}

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

      iex> ExPomodoro.pause("some id")
      {:ok, %Pomodoro{id: "some id", activity: :idle}}

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
    case PomodoroSupervisor.get_child(id) do
      {pid, %Pomodoro{id: ^id} = pomodoro} ->
        {:ok, {pid, pomodoro}}

      nil ->
        {:error, :not_found}
    end
  end

  @spec start_child(Pomodoro.id(), Pomodoro.opts()) ::
          {:ok, pid()} | {:error, {:already_started, Pomodoro.t()}}
  defp start_child(id, opts) do
    case get_by_id(id) do
      {:ok, {_pid, %Pomodoro{} = pomodoro}} ->
        {:error, {:already_started, pomodoro}}

      {:error, :not_found} ->
        PomodoroSupervisor.start_child(
          PomodoroSupervisor,
          Keyword.merge([id: id], opts)
        )
    end
  end
end
