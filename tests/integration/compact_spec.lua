require('tests.helpers').setup_plugin()

describe('compact dashboard', function()
  it('keeps visible actions and recent mappings in short and narrow windows', function()
    local config = vim.deepcopy(require('luxdash').config)
    config.name = 'LuxVim'
    config.logo = vim.fn['repeat']({ 'A very tall logo' }, 32)
    config.sections.bottom = {
      { type = 'menu', title = 'Actions', config = { menu_items = { 'newfile', 'fzf', 'closelux' } } },
      { type = 'recent_files', title = 'Recent Files', config = { max_files = 8 } },
    }
    local original, history = vim.api.nvim_get_current_buf(), vim.v.oldfiles
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = 'luxdash'
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    vim.fn.writefile({ 'return true' }, root .. '/界面.lua')
    vim.v.oldfiles = { root .. '/界面.lua' }
    local function render(width, height)
      local context = require('luxdash.core.context').create({ config = config, width = width, height = height, bufnr = buf, winid = vim.api.nvim_get_current_win(), cwd = root })
      require('luxdash.core.builder').build(context)
      require('luxdash.core.renderer').draw(context)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.is_true(#lines <= height, vim.inspect(lines))
      for _, line in ipairs(lines) do assert.is_true(vim.fn.strdisplaywidth(line) <= width, line) end
      return table.concat(lines, '\n')
    end
    for _, size in ipairs({ {80, 22}, {49, 22}, {40, 12} }) do
      local content = render(size[1], size[2])
      assert.is_truthy(content:find('Find Files', 1, true))
      assert.is_truthy(content:find('[1]', 1, true))
      assert.equals(1, vim.fn.maparg('1', 'n', false, true).buffer)
      assert.equals(1, vim.fn.maparg('f', 'n', false, true).buffer)
    end
    render(20, 5)
    assert.equals('', vim.fn.maparg('1', 'n'))
    assert.equals('', vim.fn.maparg('f', 'n'))
    render(80, 22)
    assert.equals(1, vim.fn.maparg('f', 'n', false, true).buffer)
    vim.v.oldfiles = history
    vim.api.nvim_set_current_buf(original)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.fn.delete(root, 'rf')
  end)
end)
