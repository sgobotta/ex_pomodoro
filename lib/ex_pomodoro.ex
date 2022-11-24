defmodule ExPomodoro do
  @moduledoc """
  Documentation for `ExPomodoro`.
  """

  alias ExPomodoro.PomodoroSupervisor

  @doc """
  Returns the #{ExPomodoro} child spec. It is intended for appliations to
  add an #{ExPomodoro} child spec to their application trees to have an
  #{ExPomodoro.Supervisor} started before interacting with the rest of the
  #{ExPomodoro} commands.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: ExPomodoro.Supervisor

  def start(id, opts) do
    with nil <- PomodoroSupervisor.get_child(PomodoroSupervisor, id),
      {:ok, pid} <- PomodoroSupervisor.start_child(
        PomodoroSupervisor,
        Keyword.merge([id: id], opts)
      ) do
       {:ok, pid}
    end
  end
end
