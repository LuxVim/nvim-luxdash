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
  
  local top_left_content = section_renderer.render_section(logo_section, layout_data.top.left.width, layout_data.top.left.height, {
    logo = config.logo,
    logo_color = config.logo_color,
    section_type = 'main',
    title_alignment = 'center',
    content_alignment = 'center',
    vertical_alignment = 'center',
    show_title = false,
    show_underline = false
  })
  
  local top_right_content = section_renderer.render_section(menu_section, layout_data.top.right.width, layout_data.top.right.height, {
    menu_items = menu_items,
    extras = extras,
    section_type = 'main',
    title_alignment = 'center',
    content_alignment = 'center',
    vertical_alignment = 'center',
    show_title = false,
    show_underline = false
  })
  
  local bottom_sections = config.bottom_sections or {'recent_files', 'git_status', 'empty'}
  local bottom_left_section = layout.load_section(bottom_sections[1] or 'empty')
  local bottom_center_section = layout.load_section(bottom_sections[2] or 'empty')
  local bottom_right_section = layout.load_section(bottom_sections[3] or 'empty')
  
  -- Convert section configs to new format and add section_type
  local bottom_left_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs[bottom_sections[1]] or {}, {
    section_type = 'sub',
    title_alignment = config.section_configs and config.section_configs[bottom_sections[1]] and config.section_configs[bottom_sections[1]].alignment and config.section_configs[bottom_sections[1]].alignment.title_horizontal or 'center',
    content_alignment = config.section_configs and config.section_configs[bottom_sections[1]] and config.section_configs[bottom_sections[1]].alignment and config.section_configs[bottom_sections[1]].alignment.content_horizontal or 'center',
    vertical_alignment = config.section_configs and config.section_configs[bottom_sections[1]] and config.section_configs[bottom_sections[1]].alignment and config.section_configs[bottom_sections[1]].alignment.vertical or 'center'
  })
  
  local bottom_center_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs[bottom_sections[2]] or {}, {
    section_type = 'sub',
    title_alignment = config.section_configs and config.section_configs[bottom_sections[2]] and config.section_configs[bottom_sections[2]].alignment and config.section_configs[bottom_sections[2]].alignment.title_horizontal or 'center',
    content_alignment = config.section_configs and config.section_configs[bottom_sections[2]] and config.section_configs[bottom_sections[2]].alignment and config.section_configs[bottom_sections[2]].alignment.content_horizontal or 'center',
    vertical_alignment = config.section_configs and config.section_configs[bottom_sections[2]] and config.section_configs[bottom_sections[2]].alignment and config.section_configs[bottom_sections[2]].alignment.vertical or 'center'
  })
  
  local bottom_right_config = vim.tbl_deep_extend('force', config.section_configs and config.section_configs[bottom_sections[3]] or {}, {
    section_type = 'sub',
    title_alignment = config.section_configs and config.section_configs[bottom_sections[3]] and config.section_configs[bottom_sections[3]].alignment and config.section_configs[bottom_sections[3]].alignment.title_horizontal or 'center',
    content_alignment = config.section_configs and config.section_configs[bottom_sections[3]] and config.section_configs[bottom_sections[3]].alignment and config.section_configs[bottom_sections[3]].alignment.content_horizontal or 'center',
    vertical_alignment = config.section_configs and config.section_configs[bottom_sections[3]] and config.section_configs[bottom_sections[3]].alignment and config.section_configs[bottom_sections[3]].alignment.vertical or 'center'
  })

  local bottom_left_content = section_renderer.render_section(bottom_left_section, layout_data.bottom.left.width, layout_data.bottom.left.height, bottom_left_config)
  local bottom_center_content = section_renderer.render_section(bottom_center_section, layout_data.bottom.center.width, layout_data.bottom.center.height, bottom_center_config)
  local bottom_right_content = section_renderer.render_section(bottom_right_section, layout_data.bottom.right.width, layout_data.bottom.right.height, bottom_right_config)
  
  dashboard = {}
  
  for i = 1, layout_data.top.height do
    local top_left_line = top_left_content[i] or string.rep(' ', layout_data.top.left.width)
    local top_right_line = top_right_content[i] or string.rep(' ', layout_data.top.right.width)
    
    local combined_line = line_utils.combine_line_parts({top_left_line, top_right_line})
    table.insert(dashboard, combined_line)
  end
  
  for i = 1, layout_data.bottom.height do
    local bottom_left_line = bottom_left_content[i] or string.rep(' ', layout_data.bottom.left.width)
    local bottom_center_line = bottom_center_content[i] or string.rep(' ', layout_data.bottom.center.width)
    local bottom_right_line = bottom_right_content[i] or string.rep(' ', layout_data.bottom.right.width)
    
    -- Check if this is an underline row (contains '─' characters)
    local is_underline_row = false
    if type(bottom_left_line) == 'table' and bottom_left_line[2] and string.find(bottom_left_line[2], '─') then
      is_underline_row = true
    elseif type(bottom_center_line) == 'table' and bottom_center_line[2] and string.find(bottom_center_line[2], '─') then
      is_underline_row = true
    elseif type(bottom_right_line) == 'table' and bottom_right_line[2] and string.find(bottom_right_line[2], '─') then
      is_underline_row = true
    end
    
    local combined_line
    if is_underline_row then
      -- Add vertical separators only on underline rows
      local separator = {'LuxDashSubSeparator', '│'}
      combined_line = line_utils.combine_line_parts({bottom_left_line, separator, bottom_center_line, separator, bottom_right_line})
    else
      -- No separators on regular content rows
      combined_line = line_utils.combine_line_parts({bottom_left_line, bottom_center_line, bottom_right_line})
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
    local line_text = type(line) == 'table' and line[1] or line
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
  
  line_utils.apply_highlights(all_highlights, lines)
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
