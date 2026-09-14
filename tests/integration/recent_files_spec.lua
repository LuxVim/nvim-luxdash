local helpers = require('tests.helpers')
helpers.setup_plugin()

local recent = require('luxdash.sections.recent_files')
local context = require('luxdash.core.context')
local resizer = require('luxdash.core.resizer')
local autocmds = require('luxdash.events.autocmds')
local luxdash = require('luxdash')

describe('recent file targets', function()
  local root, cwd, oldfiles, config, original_buf, win, dashboard
  local buffers, windows

  before_each(function()
    cwd, oldfiles = vim.fn.getcwd(), vim.v.oldfiles
    config = luxdash.config
    win, original_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    root = vim.fn.tempname() .. ' project with spaces'
    vim.fn.mkdir(root .. '/nested', 'p')
    vim.fn.writefile({ 'parent' }, root .. '/alpha.lua')
    vim.fn.writefile({ 'nested' }, root .. '/nested/alpha.lua')
    vim.fn.chdir(root)
    dashboard = vim.api.nvim_create_buf(false, true)
    buffers, windows = { dashboard }, {}
    vim.bo[dashboard].filetype = 'luxdash'
    vim.api.nvim_win_set_buf(win, dashboard)
    vim.v.oldfiles = { root .. '/alpha.lua' }
    luxdash.config = vim.deepcopy(config)
    luxdash.config.logo = { 'Dashboard' }
    luxdash.config.layout_config.main_height_ratio = 0.1
    luxdash.config.sections.bottom = {
      { type = 'recent_files', config = { max_files = 8, show_title = false } },
    }
  end)

  after_each(function()
    pcall(vim.api.nvim_clear_autocmds, { group = 'LuxDash' })
    for _, id in ipairs(windows) do
      if vim.api.nvim_win_is_valid(id) then vim.api.nvim_win_close(id, true) end
    end
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_buf(win, original_buf)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf):sub(1, #root) == root then
        table.insert(buffers, buf)
      end
    end
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end
    luxdash.config, vim.v.oldfiles = config, oldfiles
    vim.fn.chdir(cwd)
    vim.fn.delete(root, 'rf')
  end)

  it('captures an absolute target before the working directory changes', function()
    recent.setup_file_keymap(1, 'alpha.lua', dashboard)
    vim.fn.chdir(root .. '/nested')
    vim.cmd('normal 1')
    assert.equals(root .. '/alpha.lua', vim.api.nvim_buf_get_name(0))
    assert.same({ 'parent' }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it('binds a background dashboard using its own window directory', function()
    vim.cmd('lcd ' .. vim.fn.fnameescape(root))
    vim.cmd('vnew')
    local other = vim.api.nvim_get_current_win()
    table.insert(windows, other)
    table.insert(buffers, vim.api.nvim_get_current_buf())
    vim.cmd('lcd ' .. vim.fn.fnameescape(root .. '/nested'))
    assert.equals(root, context.from_window(win, luxdash.config).cwd)
    resizer.resize_immediate()
    assert.equals(other, vim.api.nvim_get_current_win())
    assert.equals(0, #vim.api.nvim_buf_get_keymap(0, 'n'))
    assert.equals(1, #vim.api.nvim_buf_get_keymap(dashboard, 'n'))
    vim.api.nvim_set_current_win(win)
    vim.cmd('normal 1')
    assert.equals(root .. '/alpha.lua', vim.api.nvim_buf_get_name(0))
  end)

  it('refreshes content and removes stale numbers on a directory change', function()
    resizer.resize_immediate()
    assert.equals(1, #vim.api.nvim_buf_get_keymap(dashboard, 'n'))
    autocmds.setup()
    vim.fn.chdir(root .. '/nested')
    assert.is_true(vim.wait(500, function()
      return #vim.api.nvim_buf_get_keymap(dashboard, 'n') == 0
    end))
    local lines = table.concat(vim.api.nvim_buf_get_lines(dashboard, 0, -1, false), '\n')
    assert.is_truthy(lines:find('No recent files', 1, true))
  end)

  it('cleans another dashboard without changing the current buffer', function()
    recent.setup_file_keymap(1, root .. '/alpha.lua', dashboard)
    local other = vim.api.nvim_create_buf(false, true)
    table.insert(buffers, other)
    vim.api.nvim_win_set_buf(win, other)
    recent.clear_file_keymaps(dashboard)
    assert.equals(other, vim.api.nvim_get_current_buf())
    assert.equals(0, #vim.api.nvim_buf_get_keymap(dashboard, 'n'))
  end)

  it('records the owning window directory in its render context', function()
    local ctx = context.from_window(win, luxdash.config)
    assert.equals(root, ctx.cwd)
  end)
end)
