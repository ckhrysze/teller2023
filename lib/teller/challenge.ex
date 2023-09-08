defmodule Teller.Challenge do
  def answer(challenge) do
    pt1 = dow()

    pt2 =
      challenge
      |> String.slice(13..-1)
      |> s_encode()

    p3 =
      challenge
      |> String.slice(0..12)
      |> v_encode()

    p4 = unix_time()

    [pt1, pt2, p3, p4] |> Enum.join()
  end

  def dow do
    day = Date.utc_today() |> Date.day_of_week()
    "0#{day}"
  end

  def s_encode(s) do
    String.codepoints(s)
    |> Enum.map(fn c ->
      case c do
        "0" -> "6"
        "1" -> "4"
        "2" -> "0"
        "3" -> "2"
        "4" -> "7"
        "5" -> "8"
        "6" -> "5"
        "7" -> "9"
        "8" -> "3"
        "9" -> "1"
        "A" -> "N"
        "B" -> "L"
        "C" -> "V"
        "D" -> "D"
        "E" -> "S"
        "F" -> "J"
        "G" -> "A"
        "H" -> "O"
        "I" -> "M"
        "J" -> "U"
        "K" -> "E"
        "L" -> "B"
        "M" -> "G"
        "N" -> "X"
        "O" -> "R"
        "P" -> "C"
        "Q" -> "T"
        "R" -> "Q"
        "S" -> "F"
        "T" -> "W"
        "U" -> "Z"
        "V" -> "P"
        "W" -> "K"
        "X" -> "I"
        "Y" -> "H"
        "Z" -> "Y"
      end
    end)
    |> Enum.join()
  end

  def v_encode(v) do
    {_, reversed} =
      String.to_charlist(v)
      |> Enum.reduce({0, []}, &v_reducer/2)

    reversed |> Enum.reverse() |> List.to_string()
  end

  def v_reducer(c, {alpha_counter, acc}) when alpha_counter > 3 do
    v_reducer(c, {0, acc})
  end

  def v_reducer(c, {alpha_counter, acc}) do
    offsets = [1, 4, 0, 12]

    case c do
      i when i in 48..57 ->
        {alpha_counter, [i | acc]}

      i ->
        offset = offsets |> Enum.at(alpha_counter)
        n = i + offset

        case n do
          n when n > 90 -> {alpha_counter + 1, [n - 26 | acc]}
          n -> {alpha_counter + 1, [n | acc]}
        end
    end
  end

  def unix_time do
    DateTime.utc_now() |> DateTime.to_unix(:second) |> Integer.to_string()
  end
end
