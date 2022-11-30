defmodule ExPomodoro.PomodoroTest do
  @moduledoc false

  use ExUnit.Case

  alias ExPomodoro.Fixtures.PomodoroFixtures
  alias ExPomodoro.Pomodoro

  describe "#{Pomodoro}.new/2" do
    test "returns a #{Pomodoro} struct" do
      %{
        id: id,
        break_duration: break_duration,
        exercise_duration: exercise_duration,
        rounds: rounds
      } = PomodoroFixtures.valid_attrs()

      %Pomodoro{
        id: ^id,
        activity: :exercise,
        break_duration: ^break_duration,
        exercise_duration: ^exercise_duration,
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

      expected_break_duration = Pomodoro.default_break_duration()
      expected_exercise_duration = Pomodoro.default_exercise_duration()
      expected_rounds = Pomodoro.default_rounds()

      %Pomodoro{
        id: ^id,
        activity: :exercise,
        break_duration: ^expected_break_duration,
        exercise_duration: ^expected_exercise_duration,
        rounds: ^expected_rounds
      } = do_new(id)
    end

    test "returns error when rounds value is zero" do
      %{
        id: id,
        rounds: rounds
      } = PomodoroFixtures.valid_attrs(%{rounds: 0})

      {:error, :rounds_cant_be_zero} = do_new(id, rounds: rounds)
    end

    test "returns error when rounds value is too high" do
      %{
        id: id,
        rounds: rounds
      } = PomodoroFixtures.valid_attrs(%{rounds: 21})

      {:error, :invalid_rounds} = do_new(id, rounds: rounds)
    end
  end

  describe "#{Pomodoro}.exercise/1" do
    setup do
      %{pomodoro: PomodoroFixtures.new()}
    end

    test "returns a #{Pomodoro} struct that represents an exercise process",
         %{pomodoro: %Pomodoro{current_round: current_round} = pomodoro} do
      %Pomodoro{activity: :exercise, current_round: ^current_round} =
        Pomodoro.exercise(pomodoro)
    end
  end

  describe "#{Pomodoro}.break/1" do
    setup do
      %{pomodoro: PomodoroFixtures.new()}
    end

    test "returns a #{Pomodoro} struct that represents a break process", %{
      pomodoro: %Pomodoro{current_round: current_round} = pomodoro
    } do
      %Pomodoro{current_round: ^current_round, activity: :break} =
        Pomodoro.break(pomodoro)
    end
  end

  describe "#{Pomodoro}.idle/1" do
    setup do
      %{pomodoro: PomodoroFixtures.new()}
    end

    test "returns a #{Pomodoro} struct that represents an idle state", %{
      pomodoro: %Pomodoro{current_round: current_round} = pomodoro
    } do
      %Pomodoro{current_round: ^current_round, activity: :idle} =
        Pomodoro.idle(pomodoro)
    end
  end

  describe "#{Pomodoro}.update/2" do
    setup do
      %{pomodoro: PomodoroFixtures.new()}
    end

    test "returns a #{Pomodoro} struct with it's rounds fields updated", %{
      pomodoro: %Pomodoro{} = pomodoro
    } do
      new_rounds = 9

      %Pomodoro{rounds: ^new_rounds} = do_update(pomodoro, rounds: new_rounds)
    end

    test "returns error when the new rounds value is lower than the current one",
         %{
           pomodoro: %Pomodoro{} = pomodoro
         } do
      %Pomodoro{} = %Pomodoro{pomodoro | current_round: 4}
      {:error, :invalid_rounds} = do_update(pomodoro, rounds: 3)
    end

    test "returns error when the new rounds value is zero", %{
      pomodoro: %Pomodoro{} = pomodoro
    } do
      {:error, :rounds_cant_be_zero} = do_update(pomodoro, rounds: 0)
    end

    test "returns error when the new rounds value is too high", %{
      pomodoro: %Pomodoro{} = pomodoro
    } do
      {:error, :invalid_rounds} = do_update(pomodoro, rounds: 21)
    end
  end

  defp do_new(id), do: Pomodoro.new(id)
  defp do_new(id, opts), do: Pomodoro.new(id, opts)

  defp do_update(%Pomodoro{} = pomodoro, opts),
    do: Pomodoro.update(pomodoro, opts)
end
