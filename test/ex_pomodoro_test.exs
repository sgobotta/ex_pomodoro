defmodule ExPomodoroTest do
  @moduledoc false

  use ExUnit.Case
  doctest ExPomodoro, only: []

  alias ExPomodoro.Pomodoro

  describe "#{ExPomodoro}.child_spec/1" do
    test "returns an #{ExPomodoro.Supervisor} spec" do
      %{
        id: ExPomodoro.Supervisor,
        start: {ExPomodoro.Supervisor, :start_link, [[]]},
        type: :supervisor
      } = do_child_spec([])
    end
  end

  describe "#{ExPomodoro}.start/2" do
    setup [:setup_pomodoro_server]

    test "starts a new #{ExPomodoro.PomodoroServer} child" do
      id = "some id"

      {:ok,
       %Pomodoro{
         id: ^id,
         activity: :exercise,
         exercise_duration: 1_500_000,
         break_duration: 300_000,
         rounds: 4,
         current_round: 0,
         current_duration: 0
       }} = do_start(id, [])
    end

    test "returns the pomodoro details when the child already exists" do
      id = "some id"

      {:ok,
       %Pomodoro{
         id: ^id
       }} = do_start(id, [])

      {:error,
       {:already_started,
        %Pomodoro{
          id: ^id,
          activity: :exercise,
          exercise_duration: 1_500_000,
          break_duration: 300_000,
          rounds: 4,
          current_round: 0,
          current_duration: 0
        }}} = do_start(id, [])
    end
  end

  describe "#{ExPomodoro}.get/1" do
    setup [:setup_pomodoro_server]

    test "returns a struct when the pomodoro exists" do
      id = "some id"
      {:ok, %Pomodoro{id: ^id}} = do_start(id, [])
      {:ok, %Pomodoro{id: ^id}} = do_get(id)
    end

    test "returns not found when the pomodoro does not exist" do
      id = "some id"
      {:error, :not_found} = do_get(id)
    end
  end

  describe "#{ExPomodoro}.pause/1" do
    setup [:setup_pomodoro_server]

    test "returns a struct when the pomodoro exists" do
      id = "some id"
      {:ok, %Pomodoro{id: ^id}} = do_start(id, [])
      {:ok, %Pomodoro{id: ^id, activity: :idle}} = do_pause(id)
    end

    test "fails when the pomodoro does not exist" do
      id = "some id"
      {:error, :not_found} = do_pause(id)
    end
  end

  defp setup_pomodoro_server(%{} = _context) do
    pid = start_supervised!(do_child_spec([]))

    assert valid_pid?(pid)

    %{pid: pid}
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)

  defp do_child_spec(opts), do: ExPomodoro.child_spec(opts)

  defp do_start(id, opts), do: ExPomodoro.start(id, opts)

  defp do_get(id), do: ExPomodoro.get(id)

  defp do_pause(id), do: ExPomodoro.pause(id)
end
