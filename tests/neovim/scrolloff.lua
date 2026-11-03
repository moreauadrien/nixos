-- Run from the repository root: nvim --headless -u NONE -l tests/neovim/scrolloff.lua
dofile 'modules/features/neovim/config/lua/options.lua'

local lines = {}
for i = 1, 200 do
  lines[i] = tostring(i)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

local function assert_centered()
  vim.cmd 'redraw'
  local middle = math.ceil(vim.api.nvim_win_get_height(0) / 2)
  assert(math.abs(vim.fn.winline() - middle) <= 1, 'Cursor must stay vertically centered')
end

vim.cmd 'normal! 100G'
vim.api.nvim_exec_autocmds('CursorMoved', {})
assert_centered()
for _, motion in ipairs { 'j', 'k', '10j', '20k' } do
  vim.cmd('normal! ' .. motion)
  vim.api.nvim_exec_autocmds('CursorMoved', {})
  assert_centered()
end
vim.cmd 'split'
vim.api.nvim_exec_autocmds('WinResized', {})
assert_centered()
-- Headless Lua does not run the interactive event loop between commands.
for _, event in ipairs { 'CursorMoved', 'CursorMovedI', 'BufWinEnter', 'WinResized' } do
  vim.cmd 'normal! Gzb'
  vim.api.nvim_exec_autocmds(event, {})
  assert_centered()
end

-- Short files remain bounded by the first line: no padding is possible above it.
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' })
vim.cmd 'normal! G'
vim.api.nvim_exec_autocmds('CursorMoved', {})
vim.cmd 'redraw'
assert(vim.fn.winline() <= 3, 'Short files must respect the start-of-file limit')
assert(vim.api.nvim_buf_line_count(0) == 3, 'Centering must not add real blank lines')

-- Leave auxiliary buffers alone.
vim.bo.buftype = 'nofile'
vim.cmd 'normal! zb'
vim.cmd 'redraw'
local before = vim.fn.winsaveview()
vim.api.nvim_exec_autocmds('CursorMoved', {})
vim.cmd 'redraw'
assert(vim.deep_equal(before, vim.fn.winsaveview()), 'Auxiliary buffers must not be recentered')
print('PASS: centered cursor during movement, resize and EOF, including short files')
