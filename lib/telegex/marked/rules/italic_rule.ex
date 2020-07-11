defmodule Telegex.Marked.ItalicRule do
  @moduledoc false
  # Matching and parsing of italic nodes.

  use Telegex.Marked.Rule

  @mark "_"
  @ntype :italic

  @impl true
  def match(state) do
    %{line: %{src: src, len: len}, pos: pos} = state

    if String.at(src, pos) != unquote(@mark) do
      {:nomatch, state}
    else
      chars = String.graphemes(String.slice(src, pos + 1, len))

      equals_mark_fun = fn {char, index} ->
        if char == @mark do
          Enum.at(chars, index + 1) != @mark
        else
          false
        end
      end

      {_, index} =
        chars
        |> Enum.with_index()
        |> Enum.filter(equals_mark_fun)
        |> Enum.find(fn {_, index} ->
          # 跳过 underline 的标记符
          # 如果前一个也是 @mark 但前第二个不是，则不匹配（有且仅有两个 @mark 相连）
          [before_2, before_1] = Enum.slice(chars, (index - 2)..(index - 1))
          !(before_1 == @mark && before_2 != @mark)
        end)

      end_index = index |> calculate_end_index(pos)

      if end_index do
        state = %{state | pos: end_index}

        state =
          State.push_node(state, %Node{
            type: @ntype,
            children: children_text(src, pos, end_index)
          })

        {:match, state}
      else
        {:nomatch, state}
      end
    end
  end
end
