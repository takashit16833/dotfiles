-- From the repository root: lua .hammerspoon/tests/mermaid_source_test.lua
local source = dofile(".hammerspoon/modules/mermaid_source.lua")

local function check(name, input, expected)
  local actual = source.normalize(input)
  assert(actual == expected, name .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local diagram = 'flowchart TD\n    A["思いつき"] --> B["Inbox"]\n\n    class A focus'

check("plain Mermaid", "  \n" .. diagram .. "\n\n", diagram)
check("Org block", "#+begin_src mermaid\n" .. diagram .. "\n#+end_src", diagram)
check("Org header and surrounding prose",
      "説明\n#+BEGIN_SRC Mermaid :results file\n" .. diagram .. "\n#+END_SRC\n後書き", diagram)
check("Org block with indented delimiters",
      "  #+begin_src mermaid\n" .. diagram .. "\n  #+end_src", diagram)
check("Markdown block", "```mermaid\n" .. diagram .. "\n```", diagram)
check("Markdown block with metadata and prose",
      "前書き\n```mermaid title=example\n" .. diagram .. "\n```\n後書き", diagram)
check("First of multiple Mermaid blocks",
      "#+begin_src mermaid\n" .. diagram .. "\n#+end_src\n"
        .. "#+begin_src mermaid\nflowchart LR\n  X --> Y\n#+end_src", diagram)
check("Normalize CRLF", "#+begin_src mermaid\r\nflowchart LR\r\n A-->B\r\n#+end_src",
      "flowchart LR\n A-->B")
check("Normalize CR", "```mermaid\rflowchart LR\r A-->B\r```", "flowchart LR\n A-->B")
check("Unclosed Org block", "#+begin_src mermaid\n" .. diagram, nil)
check("Unclosed Markdown block", "```mermaid\n" .. diagram, nil)
check("No text", nil, nil)
check("Whitespace only", " \n  ", "")
check("Do not mistake similarly named language", "flowchart TD\n  A-->B", "flowchart TD\n  A-->B")

print("Mermaid source tests: 14 passed")
