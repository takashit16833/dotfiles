-- OSC 133 の Input/Output 領域から、直前のコマンドと実行結果を取得する。
local M = {}

function M.last_command_and_output(pane)
  local zones = pane:get_semantic_zones()

  -- 最後の Output の直前にある Input を使う。
  -- 現在入力中のコマンドは含めず、完了した直前のコマンドを対象とする。
  for i = #zones, 2, -1 do
    if zones[i].semantic_type == "Output" and zones[i - 1].semantic_type == "Input" then
      local command = pane:get_text_from_semantic_zone(zones[i - 1]):gsub("\n+$", "")
      if command == "" then
        return nil
      end

      local output = pane:get_text_from_semantic_zone(zones[i]):gsub("\n+$", "")
      if output == "" then
        return command
      end
      return command .. "\n" .. output
    end
  end
end

function M.copy(wezterm, window, pane)
  if window:get_selection_text_for_pane(pane) ~= "" then
    window:perform_action(wezterm.action.CopyTo "Clipboard", pane)
    window:perform_action(wezterm.action.ClearSelection, pane)
    return
  end

  -- Emacs や lazygit などは従来どおり Cmd+C を受け取る。
  local process = pane:get_foreground_process_name()
  local name = process and process:match("([^/\\]+)$")
  if name == "zsh" or name == "-zsh" then
    if not pane:is_alt_screen_active() then
      local ok, text = pcall(M.last_command_and_output, pane)
      if ok and text and text ~= "" then
        window:copy_to_clipboard(text, "Clipboard")
        return
      end
      if not ok then
        wezterm.log_warn("Smart copy failed: " .. tostring(text))
      end
    end
  end

  -- 未選択時は KKP の Cmd+C をそのまま送る（既存動作）。
  window:perform_action(wezterm.action.SendString "\x1b[99;9u", pane)
end

return M
