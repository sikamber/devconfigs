-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- Make spacespace look in cwd
--
local function run_to_buf(ft)
  -- Close previous buffer if present
  local bufnr = vim.fn.bufnr(vim.fn.expand("~/nvim.out"))
  if bufnr ~= -1 then
    vim.cmd("bwipeout! " .. bufnr)
  end
  vim.cmd("enew")
  vim.cmd("file ~/nvim.out")
  vim.cmd("r !uv run python main.py")
  if ft then
    vim.cmd("setlocal ft=" .. ft)
  end
  vim.cmd("setlocal foldmethod=indent")
  vim.cmd("w!")
  vim.b.snacks_indent = false
end

vim.keymap.set("n", "<leader>rr", function()
  run_to_buf(nil)
end, { desc = "Run to buffer" })
vim.keymap.set("n", "<leader>rj", function()
  run_to_buf("json")
end, { desc = "Run to buffer (json)" })
vim.keymap.set("n", "<leader>rp", function()
  run_to_buf("python")
end, { desc = "Run to buffer (python)" })
vim.keymap.set("n", "<leader>rl", function()
  run_to_buf("log")
end, { desc = "Run to buffer (log)" })
vim.keymap.set("n", "<leader>r", "<nop>", { desc = "+run" })
