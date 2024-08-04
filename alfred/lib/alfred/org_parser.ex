defmodule Alfred.OrgParser do
  @moduledoc false

  @spec parse(String.t()) :: [map()]
  def parse(path) do
    path
    |> Org.load_file()
    |> Map.get(:sections)
    |> Enum.filter(fn %{title: title} -> String.starts_with?(title, "DOING") end)
    |> hd()
    |> Map.get(:contents)
    |> hd()
    |> Map.get(:lines)
    |> Enum.map(&parse_todo_line/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_map/1)
  end

  defp parse_todo_line(line) do
    regex = ~r/^- \[(?<state>[ X]+)\] (?<line>[\w ,\.\!\?~\{\}]+)/

    if Regex.match?(regex, line) do
      Regex.named_captures(regex, line)
    end
  end

  defp to_map(raw) do
    line = raw |> Map.get("line") |> String.split(",", parts: 2) |> hd()
    %{text: line, done: raw["state"] == "X"}
  end
end
