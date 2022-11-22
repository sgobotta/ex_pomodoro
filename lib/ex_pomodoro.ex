defmodule ExPomodoro do
  @moduledoc """
  Documentation for `ExPomodoro`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ExPomodoro.hello()
      :world

  """
  def hello do
    :world
  end

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: ExPomodoro.Supervisor
end
