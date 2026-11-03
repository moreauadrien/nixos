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
assert_centered()
for _, motion in ipairs { 'j', 'k', '10j', '20k' } do
  vim.cmd('normal! ' .. motion)
  assert_centered()
end
vim.cmd 'split'
assert_centered()
print('PASS: centered cursor when moving and resizing windows')
