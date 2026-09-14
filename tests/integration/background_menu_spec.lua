local helpers = require('tests.helpers')
helpers.setup_plugin()

describe('background dashboard rendering', function()
  it('keeps native search working in the focused explorer across resizes', function()
    local luxdash = require('luxdash')
    local original_config = luxdash.config
    local original_win = vim.api.nvim_get_current_win()
    local original_buf = vim.api.nvim_get_current_buf()
    local dashboard = vim.api.nvim_create_buf(false, true)
    local explorer = vim.api.nvim_create_buf(false, true)
    local explorer_win

    local ok, err = pcall(function()
      luxdash.config = vim.deepcopy(original_config)
      luxdash.config.logo = { 'Test dashboard' }
      luxdash.config.sections.bottom = {
        { type = 'menu', config = { menu_items = { 'newfile', 'fzf', 'closelux' } } },
      }
      vim.bo[dashboard].filetype = 'luxdash'
      vim.api.nvim_win_set_buf(original_win, dashboard)
      vim.cmd('vsplit')
      explorer_win = vim.api.nvim_get_current_win()
      vim.bo[explorer].filetype = 'NvimTree'
      vim.api.nvim_win_set_buf(explorer_win, explorer)
      vim.api.nvim_buf_set_lines(explorer, 0, -1, false, { 'lua-one', 'other', 'lua-two' })
      vim.api.nvim_win_set_cursor(explorer_win, { 1, 0 })
      vim.fn.setreg('/', 'lua')
      vim.v.searchforward = 1

      for _ = 1, 2 do
        require('luxdash.core.resizer').resize_immediate()
      end

      assert.equals(explorer_win, vim.api.nvim_get_current_win())
      assert.equals(explorer, vim.api.nvim_get_current_buf())
      assert.equals(0, #vim.api.nvim_buf_get_keymap(explorer, 'n'))
      assert.equals(3, #vim.api.nvim_buf_get_keymap(dashboard, 'n'))
      vim.cmd('normal n')
      assert.equals(explorer, vim.api.nvim_get_current_buf())
      assert.same({ 3, 0 }, vim.api.nvim_win_get_cursor(explorer_win))
      vim.cmd('normal N')
      assert.same({ 1, 0 }, vim.api.nvim_win_get_cursor(explorer_win))

      vim.api.nvim_set_current_win(original_win)
      vim.cmd('normal n')
      assert.is_not.equals(dashboard, vim.api.nvim_get_current_buf())
    end)

    luxdash.config = original_config
    if explorer_win and vim.api.nvim_win_is_valid(explorer_win) then
      vim.api.nvim_win_close(explorer_win, true)
    end
    vim.api.nvim_set_current_win(original_win)
    vim.api.nvim_win_set_buf(original_win, original_buf)
    for _, bufnr in ipairs({ dashboard, explorer }) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
    assert.is_true(ok, err)
  end)
end)
