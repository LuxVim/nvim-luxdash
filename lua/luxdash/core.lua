local M             = {}
local buffer        = require('luxdash.buffer')
local menu          = require('luxdash.menu')
local sections      = require('luxdash.sections')
local section_renderer = require('luxdash.section_renderer')
local dashboard     = {}
local color_presets = {
  blue = '#569cd6',
  green = '#4ec9b0',
  red = '#f44747',
  yellow = '#dcdcaa',
  purple = '#c586c0',
  orange = '#ce9178',
  pink = '#f392b1',
  cyan = '#4dd0e1'
}

function M.apply_logo_color(logo, color_config)
  if not color_config then
    return logo
  end
  
  local colored_logo = {}
  
  if color_config.preset then
    local color = color_presets[color_config.preset] or color_config.preset
    for _, line in ipairs(logo) do
      if line == '' then
        table.insert(colored_logo, line)
      else
        table.insert(colored_logo, {'LuxDashLogo', line})
      end
    end
    
    vim.api.nvim_set_hl(0, 'LuxDashLogo', {fg = color})
    
  elseif color_config.gradient and color_config.gradient.top and color_config.gradient.bottom then
    local top_color = color_config.gradient.top
    local bottom_color = color_config.gradient.bottom
    local logo_lines = #logo
    
    for i, line in ipairs(logo) do
      if line == '' then
        table.insert(colored_logo, line)
      else
        local ratio = (i - 1) / math.max(1, logo_lines - 1)
        local hl_name = 'LuxDashLogoGradient' .. i
        
        local interpolated_color = M.interpolate_color(top_color, bottom_color, ratio)
        vim.api.nvim_set_hl(0, hl_name, {fg = interpolated_color})
        
        table.insert(colored_logo, {hl_name, line})
      end
    end
    
  else
    return logo
  end
  
  return colored_logo
end

function M.interpolate_color(color1, color2, ratio)
  local function hex_to_rgb(hex)
    hex = hex:gsub('#', '')
    return {
      r = tonumber(hex:sub(1, 2), 16),
      g = tonumber(hex:sub(3, 4), 16),
      b = tonumber(hex:sub(5, 6), 16)
    }
  end
  
  local function rgb_to_hex(rgb)
    return string.format('#%02x%02x%02x', 
      math.floor(rgb.r + 0.5), 
      math.floor(rgb.g + 0.5), 
      math.floor(rgb.b + 0.5))
  end
  
  local rgb1 = hex_to_rgb(color1)
  local rgb2 = hex_to_rgb(color2)
  
  local interpolated = {
    r = rgb1.r + (rgb2.r - rgb1.r) * ratio,
    g = rgb1.g + (rgb2.g - rgb1.g) * ratio,
    b = rgb1.b + (rgb2.b - rgb1.b) * ratio
  }
  
  return rgb_to_hex(interpolated)
end

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
  
  local layout = sections.calculate_layout(content_height, content_width)
  
  local menu_items = menu.options(config.options or {})
  local extras = config.extras or {}
  
  local logo_section = sections.load_section('logo')
  local menu_section = sections.load_section('menu')
  
  local top_left_content = section_renderer.render_section(logo_section, layout.top.left.width, layout.top.left.height, {
    logo = config.logo,
    logo_color = config.logo_color,
    section_type = 'main',
    title_alignment = 'center',
    content_alignment = 'center',
    vertical_alignment = 'center',
    show_title = false,
    show_underline = false
  })
  
  local top_right_content = section_renderer.render_section(menu_section, layout.top.right.width, layout.top.right.height, {
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
  local bottom_left_section = sections.load_section(bottom_sections[1] or 'empty')
  local bottom_center_section = sections.load_section(bottom_sections[2] or 'empty')
  local bottom_right_section = sections.load_section(bottom_sections[3] or 'empty')
  
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

  local bottom_left_content = section_renderer.render_section(bottom_left_section, layout.bottom.left.width, layout.bottom.left.height, bottom_left_config)
  local bottom_center_content = section_renderer.render_section(bottom_center_section, layout.bottom.center.width, layout.bottom.center.height, bottom_center_config)
  local bottom_right_content = section_renderer.render_section(bottom_right_section, layout.bottom.right.width, layout.bottom.right.height, bottom_right_config)
  
  dashboard = {}
  
  for i = 1, layout.top.height do
    local top_left_line = top_left_content[i] or string.rep(' ', layout.top.left.width)
    local top_right_line = top_right_content[i] or string.rep(' ', layout.top.right.width)
    
    local combined_line = M.combine_line_parts({top_left_line, top_right_line})
    table.insert(dashboard, combined_line)
  end
  
  for i = 1, layout.bottom.height do
    local bottom_left_line = bottom_left_content[i] or string.rep(' ', layout.bottom.left.width)
    local bottom_center_line = bottom_center_content[i] or string.rep(' ', layout.bottom.center.width)
    local bottom_right_line = bottom_right_content[i] or string.rep(' ', layout.bottom.right.width)
    
    local combined_line = M.combine_line_parts({bottom_left_line, bottom_center_line, bottom_right_line})
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
    if type(line) == 'table' then
      -- Check if it's a complex multi-highlight structure
      if #line > 0 and type(line[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        local combined = M.combine_line_parts({line})
        local text = combined[1] or combined
        local highlights = type(combined) == 'table' and combined[2] or {}
        local padded_text = string.rep(' ', pad_left) .. text
        table.insert(lines, padded_text)
        
        if type(highlights) == 'table' then
          for _, hl in ipairs(highlights) do
            if hl.hl_group and type(hl.hl_group) == 'string' then
              table.insert(all_highlights, {
                line_num = #lines,
                start_col = pad_left + hl.start_col,
                end_col = pad_left + hl.end_col,
                hl_group = hl.hl_group
              })
            end
          end
        end
      elseif line[2] then
        -- Detect format: {highlight, text} vs {text, highlights}
        local text, highlight_group
        if type(line[1]) == 'string' and type(line[2]) == 'string' then
          -- Format: {highlight, text}
          highlight_group = line[1]
          text = line[2]
        else
          -- Format: {text, highlights}
          text = line[1]
          local highlights = line[2]
        end
        
        local padded_text = string.rep(' ', pad_left) .. tostring(text)
        table.insert(lines, padded_text)
        
        if highlight_group and type(highlight_group) == 'string' then
          -- Simple highlight for the entire line
          table.insert(all_highlights, {
            line_num = #lines,
            start_col = pad_left,
            end_col = pad_left + vim.fn.strwidth(tostring(text)),
            hl_group = highlight_group
          })
        elseif type(line[2]) == 'table' then
          -- Complex highlights array
          for _, hl in ipairs(line[2]) do
            if hl.hl_group and type(hl.hl_group) == 'string' then
              table.insert(all_highlights, {
                line_num = #lines,
                start_col = pad_left + hl.start_col,
                end_col = pad_left + hl.end_col,
                hl_group = hl.hl_group
              })
            end
          end
        end
      else
        -- Fallback to string representation
        local line_text = tostring(line)
        table.insert(lines, string.rep(' ', pad_left) .. line_text)
      end
    else
      local line_text = tostring(line or '')
      table.insert(lines, string.rep(' ', pad_left) .. line_text)
    end
  end
  
  vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
  
  for _, hl in ipairs(all_highlights) do
    -- Validate highlight bounds
    local line_idx = hl.line_num - 1
    if line_idx >= 0 and line_idx < #lines then
      local line_text = lines[line_idx + 1] or ''
      local line_length = vim.fn.strwidth(line_text)
      local start_col = math.max(0, math.min(hl.start_col, line_length))
      local end_col = math.max(start_col, math.min(hl.end_col, line_length))
      
      if start_col < end_col then
        vim.api.nvim_buf_add_highlight(0, -1, hl.hl_group, line_idx, start_col, end_col)
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

function M.combine_line_parts(parts)
  local combined_text = ''
  local highlights = {}
  local col_offset = 0
  
  for _, part in ipairs(parts) do
    if type(part) == 'table' then
      if #part >= 2 and type(part[1]) == 'string' then
        -- Simple format: {highlight, text}
        local part_text = tostring(part[2] or '')
        local part_hl = part[1]
        
        combined_text = combined_text .. part_text
        
        if part_hl and type(part_hl) == 'string' then
          table.insert(highlights, {
            hl_group = part_hl,
            start_col = col_offset,
            end_col = col_offset + vim.fn.strwidth(part_text)
          })
        end
        
        col_offset = col_offset + vim.fn.strwidth(part_text)
      elseif #part > 0 and type(part[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        for _, subpart in ipairs(part) do
          if type(subpart) == 'table' and #subpart >= 2 then
            local subpart_text = tostring(subpart[2] or '')
            local subpart_hl = subpart[1]
            
            combined_text = combined_text .. subpart_text
            
            if subpart_hl and type(subpart_hl) == 'string' then
              table.insert(highlights, {
                hl_group = subpart_hl,
                start_col = col_offset,
                end_col = col_offset + vim.fn.strwidth(subpart_text)
              })
            end
            
            col_offset = col_offset + vim.fn.strwidth(subpart_text)
          end
        end
      end
    else
      -- Plain text
      local part_text = tostring(part)
      combined_text = combined_text .. part_text
      col_offset = col_offset + vim.fn.strwidth(part_text)
    end
  end
  
  if #highlights > 0 then
    return {combined_text, highlights}
  else
    return combined_text
  end
end

return M
