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
    "shortcuts/no-neck-pain.nvim",
    cmd = "NoNeckPain",
    keys = {
      { "<leader>uZ", "<cmd>NoNeckPain<cr>", desc = "Toggle centered width (No Neck Pain)" },
    },
    opts = {
      width = 120,
    },
  },
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
        omnisharp = { enabled = false }, -- Disable omnisharp to make way for Roslyn instead
        emmet_language_server = {
          filetypes = { "html", "css", "javascriptreact", "typescriptreact" },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
      ensure_installed = { "markdownlint", "markdown-toc", "roslyn" },
    },
  },
  -- Roslyn LSP (since Omnisharp had performance issues)
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {},
    init = function()
      vim.lsp.config("roslyn", {
        -- This didn't change much, but a higher setting might be necessary if it's rough on the CPU. flags = { debounce_text_changes = 300 }, -- Limit how agressively changes are sent (because csharp is heavy)
        settings = {
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "openFiles",
            dotnet_compiler_diagnostics_scope = "openFiles",
          },
        },
      })
    end,
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
