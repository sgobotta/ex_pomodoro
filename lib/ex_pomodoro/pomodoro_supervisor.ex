defmodule ExPomodoro.PomodoroSupervisor do
  @moduledoc """
  Specific implementation for the Pomodoro Supervisor
  """
  use DynamicSupervisor

  alias ExPomodoro.PomodoroServer

  require Logger

  @doc """
  Given a keyword of args, initialises the dynamic Pomodoro Supervisor.
  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_arg) do
    name = Keyword.get(init_arg, :name, __MODULE__)
    init_arg = Keyword.delete(init_arg, :name)
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Given a reference and some arguments starts a `#{PomodoroServer}` child and
  returns it's pid.
  """
  @spec start_child(module(), keyword()) :: {:ok, pid()}
  def start_child(supervisor, args) do
    id = Keyword.fetch!(args, :id)

    on_start = fn state ->
      {:ok, _registry_pid} = Registry.register(Registry.Pomodoro, id, state)

      :ok
    end

    args =
      args
      |> Keyword.put(:on_start, on_start)
      |> Keyword.put(:callback_module, fetch_from_config!(:callback_module))

    DynamicSupervisor.start_child(supervisor, {PomodoroServer, args})
  end

  @doc """
  Given a cart id, returns `nil` or a tuple where the first component is a
  `#{PomodoroServer}` pid and the second component the cart server state.
  """
  @spec get_child(String.t()) :: {pid(), ExPomodoro.Pomodoro.t()} | nil
  def get_child(child_id) do
    case Registry.lookup(Registry.Pomodoro, child_id) do
      [] ->
        nil

      [{_pid, _state} = child] ->
        child
    end
  end

  @doc """
  Given a reference and a child pid, terminates a `#{PomodoroServer}` process.
  """
  @spec terminate_child(module(), pid()) :: :ok | {:error, :not_found}
  def terminate_child(supervisor, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @spec fetch_from_config!(atom()) :: any()
  defp fetch_from_config!(key), do: Application.fetch_env!(:ex_pomodoro, key)
end
