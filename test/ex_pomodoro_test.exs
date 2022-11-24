defmodule ExPomodoroTest do
  @moduledoc false

  use ExUnit.Case
  doctest ExPomodoro

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
    setup do
      pid = start_supervised!(do_child_spec([]))

      assert valid_pid?(pid)

      %{pid: pid}
    end

    test "starts a new #{ExPomodoro.PomodoroServer} child" do
      {:ok, child_pid} = ExPomodoro.start("some id", [])

      assert valid_pid?(child_pid)
    end

    test "returns the pomodoro details when the child already exists" do
      {:ok, child_pid} = ExPomodoro.start("some id", [])

      {^child_pid,
       %{
         id: "some id",
         pomodoro: %ExPomodoro.Pomodoro{
           id: "some id",
           activity: :exercise,
           exercise_duration: 1_500_000,
           break_duration: 300_000,
           rounds: 4,
           current_round: 0
         }
       }} = ExPomodoro.start("some id", [])

       assert valid_pid?(child_pid)
    end
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)

  defp do_child_spec(opts), do: ExPomodoro.child_spec(opts)
end
