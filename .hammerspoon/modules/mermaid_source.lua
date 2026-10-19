-- Extract Mermaid code from plain text, Org source blocks, or Markdown fences.
local M = {}

local function trim(text)
  return text:match("^%s*(.-)%s*$")
end

local function blockType(line)
  local lower = line:lower()

  if lower:match("^%s*#%+begin_src%s+mermaid%s*$")
      or lower:match("^%s*#%+begin_src%s+mermaid%s+.+$") then
    return "org"
  end

  if lower:match("^%s*```%s*mermaid%s*$")
      or lower:match("^%s*```%s*mermaid%s+.+$") then
    return "markdown"
  end

  return nil
end

local function isEnd(line, kind)
  if kind == "org" then
    return line:lower():match("^%s*#%+end_src%s*$") ~= nil
  end
  return line:match("^%s*```%s*$") ~= nil
end

function M.normalize(text)
  if not text then
    return nil
  end

  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  local kind = nil
  local lines = {}

  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if kind then
      if isEnd(line, kind) then
        return trim(table.concat(lines, "\n"))
      end
      lines[#lines + 1] = line
    else
      kind = blockType(line)
    end
  end

  -- Do not pass an incomplete Org/Markdown wrapper to Mermaid CLI.
  if kind then
    return nil
  end

  return trim(text)
end

return M
