defmodule ExPomodoro do
  @moduledoc """
  Documentation for `ExPomodoro`.
  """

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: ExPomodoro.Supervisor
end
