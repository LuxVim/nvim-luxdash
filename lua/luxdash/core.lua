local M             = {}
local buffer        = require('luxdash.buffer')
local menu          = require('luxdash.menu')
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
  buffer.create()
  M.build()
  M.draw()
end

function M.build()
  local config = require('luxdash').config
  local logo = M.apply_logo_color(config.logo or {}, config.logo_color)
  local menu_items = menu.options(config.options or {})
  local extras = config.extras or {}
  local layout = config.layout or 'horizontal'
  
  local right = {}
  for _, item in ipairs(menu_items) do
    table.insert(right, item)
  end
  for _, extra in ipairs(extras) do
    table.insert(right, extra)
  end
  
  dashboard = {}
  
  if layout == 'vertical' then
    for _, line in ipairs(logo) do
      table.insert(dashboard, line)
    end
    
    table.insert(dashboard, '')
    
    for _, line in ipairs(right) do
      table.insert(dashboard, line)
    end
  else
    local logo_lines = #logo
    local right_lines = #right
    
    if logo_lines > right_lines then
      local pad_total = logo_lines - right_lines
      local pad_top = math.floor(pad_total / 2)
      local pad_bot = pad_total - pad_top
      
      for _ = 1, pad_top do
        table.insert(right, 1, '')
      end
      for _ = 1, pad_bot do
        table.insert(right, '')
      end
    else
      for _ = logo_lines + 1, right_lines do
        table.insert(logo, '')
      end
    end
    
    local logo_width = 0
    for _, line in ipairs(logo) do
      local line_text = type(line) == 'table' and line[2] or line
      logo_width = math.max(logo_width, vim.fn.strwidth(line_text))
    end
    local pad = 4
    
    for i = 1, math.max(#logo, #right) do
      local logo_line = logo[i] or ''
      local logo_line_text = type(logo_line) == 'table' and logo_line[2] or logo_line
      local logo_hl_group = type(logo_line) == 'table' and logo_line[1] or nil
      local right_line = right[i] or ''
      local padding = string.rep(' ', math.max(0, logo_width - vim.fn.strwidth(logo_line_text)))
      local row = logo_line_text .. padding .. string.rep(' ', pad) .. right_line
      
      -- Preserve gradient highlight information if present
      if logo_hl_group then
        table.insert(dashboard, {logo_hl_group, row})
      else
        table.insert(dashboard, row)
      end
    end
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
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.api.nvim_win_get_width(0)
  local pad_top = math.max(0, math.floor((winheight - #dashboard) / 2))
  
  local table_width = 0
  for _, line in ipairs(dashboard) do
    local line_text = type(line) == 'table' and line[2] or line
    table_width = math.max(table_width, vim.fn.strwidth(line_text))
  end
  local pad_left = math.floor((winwidth - table_width) / 2)
  
  local lines = {}
  local highlights = {}
  
  for _ = 1, pad_top do
    table.insert(lines, '')
  end
  
  for _, line in ipairs(dashboard) do
    if type(line) == 'table' and line[1] and line[2] then
      local hl_group = line[1]
      local text = line[2]
      local padded_text = string.rep(' ', pad_left) .. text
      table.insert(lines, padded_text)
      table.insert(highlights, {
        line_num = #lines,
        start_col = pad_left,
        end_col = pad_left + vim.fn.strwidth(text),
        hl_group = hl_group
      })
    else
      local line_text = type(line) == 'table' and line[2] or line
      table.insert(lines, string.rep(' ', pad_left) .. line_text)
    end
  end
  
  vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
  
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(0, -1, hl.hl_group, hl.line_num - 1, hl.start_col, hl.end_col)
  end
end

function M.resize()
  for _, winnr in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
      local current_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_win(winnr)
      M.draw()
      vim.api.nvim_set_current_win(current_win)
    end
  end
end

return M
