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

function M.batch_apply_highlights(highlights, lines)
  if not highlights or #highlights == 0 then
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
  
  -- Apply highlights by group
  for namespace_type, group_highlights in pairs(grouped_highlights) do
    if #group_highlights > 0 then
      local ns = M.get_namespace(namespace_type)
      
      for _, hl in ipairs(group_highlights) do
        local start_col = hl.start_col
        local end_col = hl.end_col
        
        -- Special handling for logo highlights
        if namespace_type == 'logo' then
          -- Logo highlights should span full window width for braille characters
          local winwidth = vim.api.nvim_win_get_width(0)
          end_col = winwidth
          
          -- Ensure the line text actually has content to highlight
          local line_byte_width = vim.fn.strwidth(hl.line_text)
          if line_byte_width < winwidth then
            -- Line needs padding to match highlight width - this should have been handled
            -- by the line processing, but ensure consistency
            end_col = math.max(end_col, line_byte_width)
          end
        else
          -- Regular highlights bounded by line length
          local line_length = vim.fn.strwidth(hl.line_text)
          start_col = math.min(start_col, line_length)
          end_col = math.min(end_col, line_length)
        end
        
        if start_col < end_col then
          vim.api.nvim_buf_add_highlight(0, ns, hl.hl_group, hl.line_idx, start_col, end_col)
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