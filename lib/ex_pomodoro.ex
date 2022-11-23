defmodule ExPomodoro do
  @moduledoc """
  Documentation for `ExPomodoro`.
  """

  @doc """
  Returns the #{ExPomodoro} child spec. It is intended for appliations to
  add an #{ExPomodoro} child spec to their application trees to have an
  #{ExPomodoro.Supervisor} started before interacting with the rest of the
  #{ExPomodoro} commands.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: ExPomodoro.Supervisor
end
