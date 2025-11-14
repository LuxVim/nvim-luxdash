local M = {}

-- Namespace pool for reuse
local namespace_pool = {
  logo = nil,
  menu = nil,
  other = nil
}

-- Highlight group cache
local highlight_cache = {}

function M.get_namespace(type)
  type = type or 'other'
  
  if not namespace_pool[type] then
    namespace_pool[type] = vim.api.nvim_create_namespace('luxdash_' .. type)
  end
  
  return namespace_pool[type]
end

function M.clear_namespace(type)
  local ns = M.get_namespace(type)
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function M.clear_all_namespaces()
  for type, ns in pairs(namespace_pool) do
    if ns then
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    end
  end
end

function M.apply_highlight(line_idx, start_col, end_col, hl_group)
  if not hl_group or start_col >= end_col then
    return
  end
  
  local namespace_type = 'other'
  if hl_group:match('^LuxDashLogo') then
    namespace_type = 'logo'
  elseif hl_group:match('^LuxDashMenu') then
    namespace_type = 'menu'
  end
  
  local ns = M.get_namespace(namespace_type)
  vim.api.nvim_buf_add_highlight(0, ns, hl_group, line_idx, start_col, end_col)
end

---Batch apply highlights to buffer (grouped by namespace for performance)
---@param bufnr number Buffer number
---@param highlights table Array of highlight specifications
---@param lines table Array of line text
function M.batch_apply_highlights(bufnr, highlights, lines)
  if not vim.api.nvim_buf_is_valid(bufnr) or not highlights or #highlights == 0 then
    return
  end

  -- Group highlights by namespace type for better performance
  local grouped_highlights = {
    logo = {},
    menu = {},
    other = {}
  }

  for _, hl in ipairs(highlights) do
    if hl.hl_group and hl.line_num and hl.start_col and hl.end_col then
      local line_idx = hl.line_num - 1

      if line_idx >= 0 and line_idx < #lines then
        local namespace_type = 'other'
        if hl.hl_group:match('^LuxDashLogo') then
          namespace_type = 'logo'
        elseif hl.hl_group:match('^LuxDashMenu') then
          namespace_type = 'menu'
        end

        table.insert(grouped_highlights[namespace_type], {
          line_idx = line_idx,
          start_col = math.max(0, hl.start_col),
          end_col = math.max(hl.start_col, hl.end_col),
          hl_group = hl.hl_group,
          line_text = lines[line_idx + 1] or ''
        })
      end
    end
  end

  -- Get the window displaying this buffer (for width calculations)
  local winid = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      winid = win
      break
    end
  end

  local winwidth = winid and vim.api.nvim_win_get_width(winid) or 80

  -- Apply highlights by group
  for namespace_type, group_highlights in pairs(grouped_highlights) do
    if #group_highlights > 0 then
      local ns = M.get_namespace(namespace_type)

      for _, hl in ipairs(group_highlights) do
        local start_col = hl.start_col
        local end_col = hl.end_col

        -- Clamp highlight positions to line byte length
        -- nvim_buf_add_highlight uses byte positions, not display width
        local line_byte_len = #hl.line_text
        start_col = math.min(start_col, line_byte_len)
        end_col = math.min(end_col, line_byte_len)

        if start_col < end_col then
          vim.api.nvim_buf_add_highlight(bufnr, ns, hl.hl_group, hl.line_idx, start_col, end_col)
        end
      end
    end
  end
end

function M.create_highlight_group(name, opts)
  if highlight_cache[name] then
    return name
  end
  
  vim.api.nvim_set_hl(0, name, opts)
  highlight_cache[name] = true
  return name
end

function M.clear_highlight_cache()
  highlight_cache = {}
end

-- Cleanup on buffer deletion
vim.api.nvim_create_autocmd('BufDelete', {
  callback = function()
    local bufnr = tonumber(vim.fn.expand('<abuf>'))
    if bufnr and vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
      -- Clear namespaces for this buffer
      for _, ns in pairs(namespace_pool) do
        if ns then
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
      end
    end
  end
})

return M