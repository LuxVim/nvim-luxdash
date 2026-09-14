require('tests.helpers').setup_plugin()

describe('dashboard file finder', function()
  it('uses the fzf.vim command, including a lazy command stub', function()
    local called = false
    vim.api.nvim_create_user_command('Files', function() called = true end, {})
    require('luxdash.menu.actions.fzf').command().command()
    vim.api.nvim_del_user_command('Files')
    assert.is_true(called)
  end)
  it('reports an unavailable finder without opening a directory', function()
    local original, notice = vim.notify, nil
    local buf = vim.api.nvim_get_current_buf()
    vim.notify = function(message) notice = message end
    require('luxdash.menu.actions.fzf').command().command()
    vim.notify = original
    assert.is_truthy(notice:find('No file finder available', 1, true))
    assert.equals(buf, vim.api.nvim_get_current_buf())
  end)
end)
