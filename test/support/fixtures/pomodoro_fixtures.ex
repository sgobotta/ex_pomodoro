defmodule ExPomodoro.Fixtures.PomodoroFixtures do
  alias ExPomodoro.Pomodoro

  @moduledoc """
  This module defines test helpers for creating #{ExPomodoro.Pomodoro} structs.
  """

  @valid_attrs %{
    id: "some id",
    activity: :exercise,
    break_duration: :timer.minutes(5),
    exercise_duration: :timer.minutes(25),
    rounds: 4
  }
  @update_attrs %{
    id: "some id",
    activity: :break,
    break_duration: :timer.minutes(10),
    exercise_duration: :timer.minutes(40),
    rounds: 3
  }
  @invalid_attrs %{
    id: nil,
    activity: nil,
    break_duration: nil,
    exercise_duration: nil,
    rounds: nil
  }

  @spec valid_attrs(map()) :: map()
  def valid_attrs(attrs \\ %{}), do: attrs |> Enum.into(@valid_attrs)
  @spec update_attrs(map()) :: map()
  def update_attrs(attrs \\ %{}), do: attrs |> Enum.into(@update_attrs)
  @spec invalid_attrs(map()) :: map()
  def invalid_attrs(attrs \\ %{}), do: attrs |> Enum.into(@invalid_attrs)

  @doc """
  Given a map of attributes, creates a new #{Pomodoro} struct.
  """
  @spec new(map()) :: Pomodoro.t()
  def new(attrs \\ %{}) do
    attrs = Enum.into(attrs, valid_attrs(attrs))

    opts =
      attrs
      |> Enum.into([])
      |> Keyword.delete(:id)

    Pomodoro.new(attrs.id, opts)
  end
end
