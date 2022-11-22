defmodule ExPomodoro.Supervisor do
  @moduledoc """
  Main Supervisor module for the ExPomodoro `child_spec`.
  """

  use Supervisor

  alias ExPomodoro.PomodoroSupervisor

  @doc """
  Starts a GenServer process linked to the current process.
  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      PomodoroSupervisor
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end