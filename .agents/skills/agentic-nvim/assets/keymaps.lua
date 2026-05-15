return {
  {
    "<leader>aa",
    function() require("agentic").toggle() end,
    mode = { "n", "v", "i" },
    desc = "Agentic: toggle",
  },
  {
    "<leader>ao",
    function() require("agentic").open() end,
    mode = "n",
    desc = "Agentic: open",
  },
  {
    "<leader>ac",
    function() require("agentic").add_selection_or_file_to_context() end,
    mode = { "n", "v" },
    desc = "Agentic: add selection/current file",
  },
  {
    "<leader>ad",
    function() require("agentic").add_current_line_diagnostics() end,
    mode = "n",
    desc = "Agentic: add current-line diagnostics",
  },
  {
    "<leader>aD",
    function() require("agentic").add_buffer_diagnostics() end,
    mode = "n",
    desc = "Agentic: add buffer diagnostics",
  },
  {
    "<leader>ar",
    function() require("agentic").restore_session() end,
    mode = "n",
    desc = "Agentic: restore session",
  },
  {
    "<leader>as",
    function() require("agentic").switch_provider() end,
    mode = "n",
    desc = "Agentic: switch provider",
  },
}
