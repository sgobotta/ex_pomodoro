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
    rounds: 4,
    current_round: 0
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
  @spec new(String.t(), pomodoro_opts()) ::
          t() | {:error, :invalid_rounds | :rounds_cant_be_zero}
  def new(id, opts \\ []) do
    with parsed_opts <- parse_opts(opts),
         :ok <- valid_rounds?(Keyword.fetch!(parsed_opts, :rounds)) do
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

  @doc """
  Given a #{__MODULE__} struct, returns a new struct with an increased round
  in an exercise activity.
  """
  @spec exercise(t()) :: t()
  def exercise(%__MODULE__{current_round: current_round} = pomodoro) do
    %__MODULE__{
      pomodoro
      | activity: :exercise,
        current_round: current_round + 1
    }
  end

  @doc """
  Given a #{__MODULE__} struct, returns a new struct in a break activity.
  """
  @spec break(t()) :: t()
  def break(%__MODULE__{} = pomodoro) do
    %__MODULE__{
      pomodoro
      | activity: :break
    }
  end

  @doc """
  Given a #{__MODULE__} struct and  options, returns a new one with it's fields
  updated.
  """
  @spec update(t(), pomodoro_opts()) ::
          t() | {:error, :invalid_rounds | :rounds_cant_be_zero}
  def update(%__MODULE__{} = pomodoro, opts) do
    with parsed_opts <- parse_opts(pomodoro, opts),
         :ok <- valid_rounds?(pomodoro, Keyword.fetch!(parsed_opts, :rounds)) do
      %__MODULE__{
        pomodoro
        | rounds: Keyword.fetch!(parsed_opts, :rounds)
      }
    end
  end

  defp valid_rounds?(0), do: {:error, :rounds_cant_be_zero}

  defp valid_rounds?(new_rounds) when new_rounds <= 20, do: :ok

  defp valid_rounds?(_new_rounds), do: {:error, :invalid_rounds}

  defp valid_rounds?(_pomodoro, 0), do: {:error, :rounds_cant_be_zero}

  defp valid_rounds?(%__MODULE__{rounds: rounds}, new_rounds)
       when new_rounds >= rounds and new_rounds <= 20,
       do: :ok

  defp valid_rounds?(_pomodoro, _new_rounds), do: {:error, :invalid_rounds}

  @spec parse_opts(pomodoro_opts()) :: pomodoro_opts()
  defp parse_opts(opts) do
    opts
    |> Keyword.put_new(:exercise_duration, default_exercise_duration())
    |> Keyword.put_new(:break_duration, default_break_duration())
    |> Keyword.put_new(:rounds, default_rounds())
  end

  defp parse_opts(%__MODULE__{rounds: rounds}, opts) do
    # Currently we only support updating the rounds.
    opts
    |> Keyword.put_new(:rounds, rounds)
  end
end
