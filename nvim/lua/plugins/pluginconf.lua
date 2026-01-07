-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          auto_show_delay_ms = 400,
        },
        ghost_text = {
          enabled = false,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "markdownlint", "markdown-toc" } },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint" },
      },
      linters = {
        markdownlint = {
          args = { "--stdin", "--disable", "MD013", "MD041", "--" },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    ---@diagnostic disable-next-line: unused-local
    opts = function(_, opts)
      -- Credit for this section goes to exsesx
      -- https://github.com/LazyVim/LazyVim/discussions/4232#discussioncomment-11191278
      local snacks = require("snacks")
      -- Check whether Copilot is installed
      if pcall(require, "copilot") then
        --- Workaround to keep track of state
        vim.g.snacks_copilot_enabled = true
        snacks
          .toggle({
            name = "Toggle (Copilot Completion)",
            color = {
              enabled = "azure",
              disabled = "orange",
            },
            get = function()
              return vim.g.snacks_copilot_enabled
            end,
            set = function(state)
              if state then
                vim.g.snacks_copilot_enabled = true
                require("copilot.command").enable()
              else
                vim.g.snacks_copilot_enabled = false
                require("copilot.command").disable()
              end
            end,
          })
          :map("<leader>at")
      end
    end,
  },
}
