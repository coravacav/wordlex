defmodule Wordle.Game do
  defstruct word: "", guesses: []

  @doc """
  iex> game = %Wordle.Game {word: "testc"}
  iex> game |> Wordle.Game.calculate_guess("taco")
  {:error, "Bad guess, needs to be 5 chars"}
  iex> game |> Wordle.Game.calculate_guess("ttcce")
  {:ok, [:match, :elsewhere, :elsewhere, :miss, :elsewhere]}
  """
  def calculate_guess(%__MODULE__{} = game, <<guess::binary-size(5)>>) do
    {unmatched_seen_chars, results} =
      Enum.zip(String.to_charlist(game.word), String.to_charlist(guess))
      |> Enum.reduce({%{}, []}, fn t, {unmatched_seen_chars, results} ->
        case t do
          {letter, letter} ->
            {Map.update(unmatched_seen_chars, letter, 0, &(&1 - 1)), results ++ [:match]}

          {letter, guess} ->
            {Map.update(unmatched_seen_chars, letter, 1, &(1 + &1)), results ++ [guess]}
        end
      end)

    {_, results} =
      Enum.reduce(results, {unmatched_seen_chars, []}, fn guess,
                                                          {unmatched_seen_chars, results} ->
        case {guess, unmatched_seen_chars} do
          {:match, _} ->
            {unmatched_seen_chars, results ++ [:match]}

          {_, %{^guess => value}} when value > 0 ->
            {
              Map.update(unmatched_seen_chars, guess, 0, &(&1 - 1)),
              results ++ [:elsewhere]
            }

          _ ->
            {unmatched_seen_chars, results ++ [:miss]}
        end
      end)

    {:ok, results}
  end

  def calculate_guess(_, _) do
    {:error, "Bad guess, needs to be 5 chars"}
  end

  def completed?(%__MODULE__{guesses: [[:match, :match, :match, :match, :match] | _]}),
    do: true

  def completed?(_), do: false
end
