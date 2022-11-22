defmodule ExPomodoro.Pomodoro do
  @moduledoc """
  This module is repsonsible for defining the domain model for the Pomodoro
  technique.
  """

  @exercise_duration 25
  @break_duration 5
  @rounds 4

  @enforce_keys [:id]
  defstruct [
    :id,
    activity: :exercise,
    exercise_duration: @exercise_duration,
    break_duration: @break_duration,
    rounds: 4
  ]

  @type t :: %__MODULE__{}
  @type pomodoro_activity :: :exercise | :break
  @type pomodoro_opts :: [
          exercise_duration: non_neg_integer(),
          break_duration: non_neg_integer(),
          rounds: non_neg_integer()
        ]

  @doc """
  Given an id and a keyword of options, returns a new #{__MODULE__} struct.
  The options can redefine the following fields, otherwise the default values
  will be used:
  * `exercise_duration`: the amount of time intended to spend on task
  completion, in minutes (default: `25`).
  * `break_duration`: the amount of time the break lasts, in minutes (default:
  `5`).
  * `rounds`: the number of rounds until the pomodoro finishes (default: `4`).

  """
  @spec new(String.t(), pomodoro_opts()) :: t()
  def new(id, opts \\ []) do
    parsed_opts = parse_opts(opts)

    %__MODULE__{
      id: id,
      activity: :exercise,
      exercise_duration:
        :timer.minutes(Keyword.fetch!(parsed_opts, :exercise_duration)),
      break_duration:
        :timer.minutes(Keyword.fetch!(parsed_opts, :break_duration)),
      rounds: Keyword.fetch!(parsed_opts, :rounds)
    }
  end

  @doc """
  The default duration of the exercise.
  """
  @spec default_exercise_duration() :: non_neg_integer()
  def default_exercise_duration, do: @exercise_duration

  @doc """
  The default duration of breaks.
  """
  @spec default_break_duration() :: non_neg_integer()
  def default_break_duration, do: @break_duration

  @doc """
  The default rounds number.
  """
  @spec default_rounds() :: non_neg_integer()
  def default_rounds, do: @rounds

  @spec parse_opts(pomodoro_opts()) :: pomodoro_opts()
  defp parse_opts(opts) do
    opts
    |> Keyword.put_new(:exercise_duration, default_exercise_duration())
    |> Keyword.put_new(:break_duration, default_break_duration())
    |> Keyword.put_new(:rounds, default_rounds())
  end
end
