-- Reload all LuxDash modules (for development)
-- Run with: :luafile reload.lua or :source reload.lua

print('==========================================')
print('  LuxDash Module Reloader')
print('==========================================')

-- Close existing dashboard if open
local luxdash_bufs = {}
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == 'luxdash' then
    table.insert(luxdash_bufs, bufnr)
  end
end

for _, bufnr in ipairs(luxdash_bufs) do
  pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
end

-- Clear all luxdash modules from package.loaded
local count = 0
for module_name, _ in pairs(package.loaded) do
  if module_name:match('^luxdash') then
    package.loaded[module_name] = nil
    count = count + 1
  end
end

print(string.format('Unloaded %d LuxDash modules', count))

-- Reload the main module
local ok, err = pcall(require, 'luxdash')
if not ok then
  print('ERROR loading luxdash: ' .. tostring(err))
  return
end

print('LuxDash modules reloaded successfully!')
print('==========================================')
print('Opening dashboard...')
print('==========================================')

-- Auto-open dashboard
vim.schedule(function()
  vim.cmd('LuxDash')
end)
