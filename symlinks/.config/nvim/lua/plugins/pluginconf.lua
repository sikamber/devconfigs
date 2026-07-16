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
          auto_show_delay_ms = 300,
        },
        ghost_text = {
          enabled = false,
        },
      },
      keymap = { preset = "default" },
      sources = {
        providers = {
          buffer = { score_offset = -10 },
        },
      },
    },
  },
  -- Make Pyright check the whole workspace
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                diagnosticMode = "workspace",
              },
            },
          },
        },
        emmet_language_server = {
          filetypes = { "html", "css", "javascriptreact", "typescriptreact" },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "markdownlint", "markdown-toc" } },
  },
  -- Switch markdownlinter from standard markdownlint-cli2 to markdownlint (easier to configure)
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
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  -- Set picker to use cwd, rather than root, on space-space
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (Root Dir)" },
    },
    -- disable flashing when seeking
    {
      "folke/flash.nvim",
      opts = {
        modes = {
          char = {
            highlight = { backdrop = false },
          },
        },
      },
    },
  },
}
