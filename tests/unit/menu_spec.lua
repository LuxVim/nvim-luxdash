local helpers = require('tests.helpers')
helpers.setup_plugin()

local menu = require('luxdash.utils.menu')

local function mapping(bufnr, lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, 'n')) do
    if map.lhs == lhs then
      return map
    end
  end
end

describe('dashboard menu mappings', function()
  local buffers
  local original_buf
  local dashboard
  local focused

  local function buffer(filetype)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].filetype = filetype
    table.insert(buffers, bufnr)
    return bufnr
  end

  before_each(function()
    buffers = {}
    original_buf = vim.api.nvim_get_current_buf()
    dashboard = buffer('luxdash')
    focused = buffer('NvimTree')
    vim.api.nvim_set_current_buf(focused)
  end)

  after_each(function()
    vim.api.nvim_set_current_buf(original_buf)
    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
    package.loaded['luxdash.menu.actions.test_string'] = nil
    vim.g.luxdash_test_string = nil
  end)

  it('binds every default menu action to the dashboard while the explorer has focus', function()
    local options = menu.options({ 'newfile', 'fzf', 'closelux' }, dashboard)

    assert.equals(3, #options)
    assert.equals(focused, vim.api.nvim_get_current_buf())
    for _, key in ipairs({ 'n', 'f', 'q' }) do
      assert.is_function(mapping(dashboard, key).callback)
      assert.is_nil(mapping(focused, key))
    end
  end)

  it('preserves existing explorer shortcuts during repeated redraws', function()
    local search = function() end
    vim.keymap.set('n', 'n', search, { buffer = focused })
    for _ = 1, 3 do
      menu.options({ 'newfile' }, dashboard)
    end
    assert.equals(search, mapping(focused, 'n').callback)
    assert.equals(1, #vim.api.nvim_buf_get_keymap(dashboard, 'n'))
  end)

  it('does not bind menu actions to an editing buffer during a background redraw', function()
    vim.bo[focused].filetype = 'lua'
    menu.options({ 'newfile', 'fzf', 'closelux' }, dashboard)
    assert.equals(0, #vim.api.nvim_buf_get_keymap(focused, 'n'))
    assert.is_not_nil(mapping(dashboard, 'n'))
  end)

  it('binds string commands to the target buffer and keeps them executable', function()
    package.loaded['luxdash.menu.actions.test_string'] = {
      command = function()
        return { keymap = 'x', command = 'let g:luxdash_test_string = 1' }
      end,
    }
    menu.options({ 'test_string' }, dashboard)
    assert.is_nil(mapping(focused, 'x'))
    mapping(dashboard, 'x').callback()
    assert.equals(1, vim.g.luxdash_test_string)
  end)

  it('can bind separate dashboards without changing focus', function()
    local second = buffer('luxdash')
    menu.options({ 'newfile' }, dashboard)
    menu.options({ 'closelux' }, second)
    assert.is_not_nil(mapping(dashboard, 'n'))
    assert.is_nil(mapping(dashboard, 'q'))
    assert.is_not_nil(mapping(second, 'q'))
    assert.is_nil(mapping(second, 'n'))
    assert.equals(focused, vim.api.nvim_get_current_buf())
    assert.equals(0, #vim.api.nvim_buf_get_keymap(focused, 'n'))
  end)

  it('renders without installing mappings when no target is supplied', function()
    assert.equals(1, #menu.options({ 'newfile' }))
    assert.is_nil(mapping(focused, 'n'))
  end)

  it('does not treat buffer zero as an explicit dashboard target', function()
    vim.api.nvim_set_current_buf(dashboard)
    assert.equals(1, #menu.options({ 'newfile' }, 0))
    assert.is_nil(mapping(dashboard, 'n'))
  end)

  it('renders without installing mappings when the target was deleted', function()
    vim.api.nvim_buf_delete(dashboard, { force = true })
    assert.equals(1, #menu.options({ 'newfile' }, dashboard))
    assert.is_nil(mapping(focused, 'n'))
  end)

  it('does not install mappings when the target is no longer a dashboard', function()
    vim.bo[dashboard].filetype = 'lua'
    assert.equals(1, #menu.options({ 'newfile' }, dashboard))
    assert.is_nil(mapping(dashboard, 'n'))
    assert.is_nil(mapping(focused, 'n'))
  end)
end)
