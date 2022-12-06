defmodule ExPomodoro.Supervisor do
  @moduledoc """
  Main Supervisor module for the ExPomodoro `child_spec`.
  """

  use Supervisor

  alias ExPomodoro.PomodoroSupervisor

  @type config_error :: String.t()
  @type init_arg :: [callback_module: module()]

  @missing_callback_module_error "Key `:callback_module` was not found. Did you forget to configure the callback_module in your config?"

  @doc """
  Starts a GenServer process linked to the current process.
  """
  @spec start_link(init_arg()) :: {:ok, pid()}
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    children = [
      {Registry, keys: :unique, name: Registry.Pomodoro},
      {PomodoroSupervisor, configure_args!(init_arg)}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
  Error message raised when the callback module is missing in the configuration.
  """
  @spec missing_callback_module_error :: config_error()
  def missing_callback_module_error, do: @missing_callback_module_error

  @spec configure_args!(init_arg()) :: init_arg()
  defp configure_args!(init_arg) do
    init_arg
    |> check_callback_module!()
  end

  @spec check_callback_module!(init_arg()) :: init_arg()
  defp check_callback_module!(init_args) do
    case Application.get_env(:ex_pomodoro, :callback_module) do
      nil ->
        raise ArgumentError, missing_callback_module_error()

      callback_module ->
        Keyword.put(init_args, :callback_module, callback_module)
    end
  end
end
