-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins

-- Vault heading navigation: a note named "<something> MOC.md" marks the
-- directory it lives in as a "content area" root for the narrow heading picker.
local function is_moc(name)
  return name:match("MOC%.md$") ~= nil
end

local function nearest_moc()
  return vim.fs.find(is_moc, { upward = true, path = vim.fn.expand("%:p:h"), type = "file", limit = 1 })[1]
end

local function vault_root()
  return vim.fs.root(0, ".git") or vim.fn.expand("%:p:h")
end

local function heading_picker(dirs, hidden)
  Snacks.picker.grep({
    dirs = dirs,
    glob = "*.md",
    search = "^#{1,6}\\s",
    hidden = hidden,
    live = false,
  })
end

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
      {
        "<leader>hh",
        function()
          heading_picker({ vim.fn.expand("%:p") })
        end,
        desc = "Headings (current file)",
      },
      {
        "<leader>hH",
        function()
          local moc = nearest_moc()
          heading_picker({ moc and vim.fs.dirname(moc) or vault_root() })
        end,
        desc = "Headings (current area)",
      },
      {
        "<leader>hv",
        function()
          heading_picker({ vault_root() }, false)
        end,
        desc = "Headings (vault)",
      },
      {
        "<leader>hV",
        function()
          heading_picker({ vault_root() }, true)
        end,
        desc = "Headings (vault, incl. hidden)",
      },
      {
        "<leader>hc",
        function()
          local moc = nearest_moc()
          if moc then
            vim.cmd.edit(vim.fn.fnameescape(moc))
          else
            vim.notify("No MOC found above this file", vim.log.levels.WARN)
          end
        end,
        desc = "Open area MOC",
      },
    },
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
  -- Label the heading-picker prefix in the which-key popup
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>h", group = "headings" },
      },
    },
  },
}
