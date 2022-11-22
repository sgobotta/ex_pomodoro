defmodule ExPomodoro.PomodoroTest do
  @moduledoc false

  use ExUnit.Case

  alias ExPomodoro.Fixtures.PomodoroFixtures
  alias ExPomodoro.Pomodoro

  describe "Pomodoro.new/2" do
    setup do
      %{
        id: id
      } = PomodoroFixtures.valid_attrs()

      %Pomodoro{} = pomodoro = Pomodoro.new(id, [])

      %{pomodoro: pomodoro}
    end

    test "returns a #{Pomodoro} struct" do
      %{
        id: id,
        break_duration: break_duration,
        exercise_duration: exercise_duration,
        rounds: rounds
      } = PomodoroFixtures.valid_attrs()

      expected_break_duration = :timer.minutes(break_duration)
      expected_exercise_duration = :timer.minutes(exercise_duration)

      %Pomodoro{
        id: ^id,
        activity: :exercise,
        break_duration: ^expected_break_duration,
        exercise_duration: ^expected_exercise_duration,
        rounds: ^rounds
      } =
        do_new(id,
          exercise_duration: exercise_duration,
          break_duration: break_duration,
          rounds: rounds
        )
    end

    test "returns a #{Pomodoro} struct with default values" do
      %{
        id: id
      } = PomodoroFixtures.valid_attrs()

      expected_break_duration =
        :timer.minutes(Pomodoro.default_break_duration())

      expected_exercise_duration =
        :timer.minutes(Pomodoro.default_exercise_duration())

      expected_rounds = Pomodoro.default_rounds()

      %Pomodoro{
        id: ^id,
        activity: :exercise,
        break_duration: ^expected_break_duration,
        exercise_duration: ^expected_exercise_duration,
        rounds: ^expected_rounds
      } = do_new(id)
    end
  end

  defp do_new(id), do: Pomodoro.new(id)
  defp do_new(id, opts), do: Pomodoro.new(id, opts)
end
