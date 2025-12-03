return {
  "WilliamHsieh/overlook.nvim",
  opts = {},
  keys = {
    { "<leader>pd", function() require("overlook.api").peek_definition() end, desc = "Peek Definition" },
    { "<leader>pc", function() require("overlook.api").peek_cursor() end, desc = "Peek Cursor" },
    { "<leader>pr", function() require("overlook.api").restore_popup() end, desc = "Restore Popup" },
    { "<leader>px", function() require("overlook.api").close_all() end, desc = "Close All Popups" },
  },
}
