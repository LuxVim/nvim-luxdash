local M             = {}
local buffer        = require('luxdash.buffer')
local menu          = require('luxdash.menu')
local layout        = require('luxdash.layout')
local section_renderer = require('luxdash.section_renderer')
local colors        = require('luxdash.colors')
local line_utils    = require('luxdash.line_utils')
local dashboard     = {}


function M.open()
  local float = require('luxdash.float')
  if float.is_open() then
    float.close()
    return
  end
  
  buffer.create()
  M.build()
  M.draw()
end

function M.build()
  local config = require('luxdash').config
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.api.nvim_win_get_width(0)
  
  local is_float_buffer = vim.api.nvim_buf_get_option(0, 'filetype') == 'luxdash'
  
  -- Apply buffer padding
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }
  local content_width = winwidth - padding.left - padding.right
  local content_height = winheight - padding.top - padding.bottom
  
  local layout_data = layout.calculate_layout(content_height, content_width)
  
  local menu_items = menu.options(config.options or {})
  local extras = config.extras or {}
  
  local logo_section = layout.load_section('logo')
  local menu_section = layout.load_section('menu')
  
    local main_content = section_renderer.render_section(logo_section, layout_data.main.width, layout_data.main.height, {
        logo                = config.logo,
        logo_color          = config.logo_color,
        section_type        = 'main',
        title_alignment     = 'center',
        content_alignment   = 'center',
        vertical_alignment  = 'center',
        show_title          = false,
        show_underline      = false
  })
  
  local bottom_sections         = config.bottom_sections or {'menu', 'recent_files', 'git_status'}
  local bottom_left_section     = bottom_sections[1] == 'menu' and menu_section or layout.load_section(bottom_sections[1] or 'empty')
  local bottom_center_section   = bottom_sections[2] == 'menu' and menu_section or layout.load_section(bottom_sections[2] or 'empty')
  local bottom_right_section    = layout.load_section(bottom_sections[3] or 'empty')
  
  -- Convert section configs to new format and add section_type
  local bottom_left_config
  if bottom_sections[1] == 'menu' then
    bottom_left_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs.menu or {}, {
      menu_items = menu_items,
      extras = extras,
      section_type = 'sub',
      title = 'Actions',
      show_title = true,
      show_underline = true,
      title_alignment = config.section_configs and config.section_configs.menu and config.section_configs.menu.alignment and config.section_configs.menu.alignment.title_horizontal or 'center',
      content_alignment = config.section_configs and config.section_configs.menu and config.section_configs.menu.alignment and config.section_configs.menu.alignment.content_horizontal or 'center',
      vertical_alignment = config.section_configs and config.section_configs.menu and config.section_configs.menu.alignment and config.section_configs.menu.alignment.vertical or 'top'
    })
  else
    local section_titles = {
      recent_files = 'Recent Files',
      git_status = 'Git Status',
      actions = 'Actions'
    }
    bottom_left_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs[bottom_sections[1]] or {}, {
      section_type = 'sub',
      title = section_titles[bottom_sections[1]] or bottom_sections[1]:gsub('_', ' '):gsub('%w+', function(w) return w:sub(1,1):upper()..w:sub(2) end),
      show_title = true,
      show_underline = true,
      title_alignment = config.section_configs and config.section_configs[bottom_sections[1]] and config.section_configs[bottom_sections[1]].alignment and config.section_configs[bottom_sections[1]].alignment.title_horizontal or 'center',
      content_alignment = config.section_configs and config.section_configs[bottom_sections[1]] and config.section_configs[bottom_sections[1]].alignment and config.section_configs[bottom_sections[1]].alignment.content_horizontal or 'center',
      vertical_alignment = config.section_configs and config.section_configs[bottom_sections[1]] and config.section_configs[bottom_sections[1]].alignment and config.section_configs[bottom_sections[1]].alignment.vertical or 'top'
    })
  end
  
  local bottom_center_config
  if bottom_sections[2] == 'menu' then
    bottom_center_config = {
      menu_items = menu_items,
      extras = extras,
      section_type = 'sub',
      title = 'Actions',
      show_title = true,
      show_underline = true,
      title_alignment = 'center',
      content_alignment = 'center',
      vertical_alignment = 'top'
    }
  else
    local section_titles = {
      recent_files = 'Recent Files',
      git_status = 'Git Status',
      actions = 'Actions'
    }
    bottom_center_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs[bottom_sections[2]] or {}, {
      section_type = 'sub',
      title = section_titles[bottom_sections[2]] or bottom_sections[2]:gsub('_', ' '):gsub('%w+', function(w) return w:sub(1,1):upper()..w:sub(2) end),
      show_title = true,
      show_underline = true,
      title_alignment = config.section_configs and config.section_configs[bottom_sections[2]] and config.section_configs[bottom_sections[2]].alignment and config.section_configs[bottom_sections[2]].alignment.title_horizontal or 'center',
      content_alignment = config.section_configs and config.section_configs[bottom_sections[2]] and config.section_configs[bottom_sections[2]].alignment and config.section_configs[bottom_sections[2]].alignment.content_horizontal or 'center',
      vertical_alignment = config.section_configs and config.section_configs[bottom_sections[2]] and config.section_configs[bottom_sections[2]].alignment and config.section_configs[bottom_sections[2]].alignment.vertical or 'top'
    })
  end
  
  local section_titles = {
    recent_files = 'Recent Files',
    git_status = 'Git Status',
    actions = 'Actions'
  }
  local bottom_right_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs[bottom_sections[3]] or {}, {
    section_type = 'sub',
    title = section_titles[bottom_sections[3]] or bottom_sections[3]:gsub('_', ' '):gsub('%w+', function(w) return w:sub(1,1):upper()..w:sub(2) end),
    show_title = true,
    show_underline = true,
    title_alignment = config.section_configs and config.section_configs[bottom_sections[3]] and config.section_configs[bottom_sections[3]].alignment and config.section_configs[bottom_sections[3]].alignment.title_horizontal or 'center',
    content_alignment = config.section_configs and config.section_configs[bottom_sections[3]] and config.section_configs[bottom_sections[3]].alignment and config.section_configs[bottom_sections[3]].alignment.content_horizontal or 'center',
    vertical_alignment = config.section_configs and config.section_configs[bottom_sections[3]] and config.section_configs[bottom_sections[3]].alignment and config.section_configs[bottom_sections[3]].alignment.vertical or 'top'
  })

  local bottom_left_content = section_renderer.render_section(bottom_left_section, layout_data.bottom.left.width, layout_data.bottom.left.height, bottom_left_config)
  local bottom_center_content = section_renderer.render_section(bottom_center_section, layout_data.bottom.center.width, layout_data.bottom.center.height, bottom_center_config)
  local bottom_right_content = section_renderer.render_section(bottom_right_section, layout_data.bottom.right.width, layout_data.bottom.right.height, bottom_right_config)
  
  dashboard = {}
  
  -- Add main section (logo) lines
  for i = 1, layout_data.main.height do
    local main_line = main_content[i] or string.rep(' ', layout_data.main.width)
    table.insert(dashboard, main_line)
  end
  
  -- Helper function to ensure exact width
  local function ensure_exact_width(line, target_width)
    -- For complex format lines, use line_utils to properly handle width
    if type(line) == 'table' and #line > 0 and type(line[1]) == 'table' then
      -- Complex format: {{highlight, text}, {highlight, text}, ...}
      local combined = line_utils.combine_line_parts({line})
      local text = type(combined) == 'table' and combined[1] or combined
      local text_width = vim.fn.strwidth(text)
      
      if text_width < target_width then
        -- Add padding by appending spaces to the combined text
        local padding = string.rep(' ', target_width - text_width)
        -- Return the original complex format with padding appended
        local padded_line = {}
        for _, part in ipairs(line) do
          table.insert(padded_line, part)
        end
        if target_width > text_width then
          table.insert(padded_line, {'Normal', padding})
        end
        return padded_line
      elseif text_width > target_width then
        -- Truncate by removing characters from the end
        return line -- For now, let section renderer handle truncation
      end
      return line
    elseif type(line) == 'table' and line[2] then
      -- Simple format: {highlight, text}
      local text = tostring(line[2])
      local text_width = vim.fn.strwidth(text)
      if text_width < target_width then
        return {line[1], text .. string.rep(' ', target_width - text_width)}
      elseif text_width > target_width then
        return {line[1], vim.fn.strpart(text, 0, target_width)}
      end
      return line
    else
      -- Plain text
      local text = tostring(line)
      local text_width = vim.fn.strwidth(text)
      if text_width < target_width then
        return text .. string.rep(' ', target_width - text_width)
      elseif text_width > target_width then
        return vim.fn.strpart(text, 0, target_width)
      end
      return text
    end
  end

  for i = 1, layout_data.bottom.height do
    local bottom_left_line = bottom_left_content[i] or string.rep(' ', layout_data.bottom.left.width)
    local bottom_center_line = bottom_center_content[i] or string.rep(' ', layout_data.bottom.center.width)
    local bottom_right_line = bottom_right_content[i] or string.rep(' ', layout_data.bottom.right.width)
    
    -- Ensure each section is exactly its allocated width
    bottom_left_line = ensure_exact_width(bottom_left_line, layout_data.bottom.left.width)
    bottom_center_line = ensure_exact_width(bottom_center_line, layout_data.bottom.center.width)
    bottom_right_line = ensure_exact_width(bottom_right_line, layout_data.bottom.right.width)
    
    -- Check if this is an underline row (contains '─' characters)
    local function contains_underline(line)
      if type(line) == 'table' then
        if line[2] and type(line[2]) == 'string' then
          -- Simple format: {highlight, text}
          return string.find(line[2], '─') ~= nil
        elseif #line > 0 and type(line[1]) == 'table' then
          -- Complex format: {{highlight, text}, {highlight, text}, ...}
          for _, part in ipairs(line) do
            if type(part) == 'table' and part[2] and type(part[2]) == 'string' and string.find(part[2], '─') then
              return true
            end
          end
        end
      elseif type(line) == 'string' then
        return string.find(line, '─') ~= nil
      end
      return false
    end
    
    local is_underline_row = contains_underline(bottom_left_line) or 
                            contains_underline(bottom_center_line) or 
                            contains_underline(bottom_right_line)
    
    local combined_line
    if is_underline_row then
      -- Add vertical separators only on underline rows
      local separator = {'LuxDashSubSeparator', '│'}
      combined_line = line_utils.combine_line_parts({bottom_left_line, separator, bottom_center_line, separator, bottom_right_line})
    else
      -- Add spacing between sections on regular content rows
      local spacer = string.rep(' ', 2)  -- 2 spaces between sections
      combined_line = line_utils.combine_line_parts({bottom_left_line, spacer, bottom_center_line, spacer, bottom_right_line})
    end
    
    table.insert(dashboard, combined_line)
  end
end

function M.clear()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end

function M.draw()
  vim.bo.modifiable = true
  M.clear()
  M.print()
  vim.api.nvim_win_set_cursor(0, {1, 0})
  vim.bo.modifiable = false
end

function M.print()
  local config = require('luxdash').config
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.api.nvim_win_get_width(0)
  
  -- Apply buffer padding
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }
  local content_width = winwidth - padding.left - padding.right
  local content_height = winheight - padding.top - padding.bottom
  
  local table_width = 0
  for _, line in ipairs(dashboard) do
    local line_text
    if type(line) == 'table' then
      -- Handle different table formats
      if #line > 0 and type(line[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        -- Extract text from all parts
        local combined_text = ''
        for _, part in ipairs(line) do
          if type(part) == 'table' and #part >= 2 then
            combined_text = combined_text .. tostring(part[2] or '')
          end
        end
        line_text = combined_text
      elseif line[2] then
        -- Simple format: {highlight, text}
        line_text = tostring(line[2])
      else
        -- Fallback
        line_text = tostring(line[1] or '')
      end
    else
      line_text = tostring(line)
    end
    table_width = math.max(table_width, vim.fn.strwidth(line_text))
  end
  local pad_left = padding.left + math.floor((content_width - table_width) / 2)
  local pad_top = padding.top + math.max(0, math.floor((content_height - #dashboard) / 2))
  
  local lines = {}
  local all_highlights = {}
  
  for _ = 1, pad_top do
    table.insert(lines, '')
  end
  
  for _, line in ipairs(dashboard) do
    local padded_text, line_highlights = line_utils.process_line_for_rendering(line, pad_left)
    table.insert(lines, padded_text)
    
    for _, hl in ipairs(line_highlights) do
      table.insert(all_highlights, {
        line_num = #lines,
        start_col = hl.start_col,
        end_col = hl.end_col,
        hl_group = hl.hl_group
      })
    end
  end
  
  vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
  
  -- Clear all existing highlights first
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
  
  -- Create separate namespaces for different highlight types
  local logo_ns = vim.api.nvim_create_namespace('luxdash_logo')
  local menu_ns = vim.api.nvim_create_namespace('luxdash_menu')
  local other_ns = vim.api.nvim_create_namespace('luxdash_other')
  
  for _, hl in ipairs(all_highlights) do
    local line_idx = hl.line_num - 1
    if line_idx >= 0 and line_idx < #lines then
      local line_text = lines[line_idx + 1] or ''
      local line_length = vim.fn.strwidth(line_text)
      -- Don't constrain logo highlights to line length - they should span their intended width
      local start_col, end_col
      if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
        start_col = math.max(0, hl.start_col)
        end_col = math.max(start_col, hl.end_col)
      else
        start_col = math.max(0, math.min(hl.start_col, line_length))
        end_col = math.max(start_col, math.min(hl.end_col, line_length))
      end
      
      if start_col < end_col then
        local namespace
        if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
          namespace = logo_ns
        elseif hl.hl_group and hl.hl_group:match('^LuxDashMenu') then
          namespace = menu_ns
        else
          namespace = other_ns
        end
        
        vim.api.nvim_buf_add_highlight(0, namespace, hl.hl_group, line_idx, start_col, end_col)
      end
    end
  end
end

function M.resize()
  for _, winnr in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winnr) then
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
        local current_win = vim.api.nvim_get_current_win()
        local ok, _ = pcall(function()
          vim.api.nvim_set_current_win(winnr)
          M.build()
          M.draw()
          vim.api.nvim_set_current_win(current_win)
        end)
        if not ok then
          -- If resize fails, restore current window
          if vim.api.nvim_win_is_valid(current_win) then
            vim.api.nvim_set_current_win(current_win)
          end
        end
      end
    end
  end
end


return M
