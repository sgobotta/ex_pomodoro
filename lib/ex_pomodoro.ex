defmodule ExPomodoro do
  @moduledoc """
  Documentation for `ExPomodoro`.
  """

  alias ExPomodoro.{
    Pomodoro,
    PomodoroSupervisor
  }

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

  """
  @spec start(String.t(), Pomodoro.pomodoro_opts()) ::
          {:ok, Pomodoro.t()} | {:error, {:already_started, Pomodoro.t()}}
  def start(id, opts) do
    with {:ok, _pid} <- start_child(id, opts) do
      {:ok, %Pomodoro{}} = get_by_id(id)
    end
  end

  defp get_by_id(id) do
    case PomodoroSupervisor.get_child(PomodoroSupervisor, id) do
      {_pid, %{id: ^id, pomodoro: %Pomodoro{} = pomodoro}} ->
        {:ok, pomodoro}

      nil ->
        {:error, :not_found}
    end
  end

  defp start_child(id, opts) do
    case get_by_id(id) do
      {:ok, %Pomodoro{} = pomodoro} ->
        {:noop, {:already_started, pomodoro}}

      {:error, :not_found} ->
        PomodoroSupervisor.start_child(
          PomodoroSupervisor,
          Keyword.merge([id: id], opts)
        )
    end
  end
end
