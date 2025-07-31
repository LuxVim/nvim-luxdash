local M = {}

local color_presets = {
    blue = '#569cd6', green = '#4ec9b0', red = '#f44747', yellow = '#dcdcaa',
    purple = '#c586c0', orange = '#ce9178', pink = '#f392b1', cyan = '#4dd0e1'
}

function M.create_full_row_highlight_line(highlight_group, text)
  return {
    {highlight_group, ''},
    {highlight_group, text},
    {highlight_group, ''}
  }
end

function M.apply_logo_color(logo, color_config)
  if not color_config then return logo end
  
  local colored_logo = {}
  
  if color_config.row_gradient and color_config.row_gradient.start and color_config.row_gradient.bottom then
    M.apply_row_gradient(logo, colored_logo, color_config.row_gradient)
  elseif color_config.gradient and color_config.gradient.top and color_config.gradient.bottom then
    M.apply_gradient(logo, colored_logo, color_config.gradient)
  elseif color_config.preset then
    M.apply_preset(logo, colored_logo, color_config.preset)
  else
    return logo
  end
  
  return colored_logo
end

function M.apply_row_gradient(logo, colored_logo, gradient_config)
  local start_color = gradient_config.start
  local end_color = gradient_config.bottom
  local logo_lines = #logo
  
  vim.api.nvim_set_hl(0, 'LuxDashLogo', {})
  
  for i, line in ipairs(logo) do
    local ratio = (i - 1) / math.max(1, logo_lines - 1)
    local hl_name = 'LuxDashLogoRowGradient' .. i
    local color = M.interpolate_color(start_color, end_color, ratio)
    
    vim.api.nvim_set_hl(0, hl_name, {fg = color})
    table.insert(colored_logo, M.create_full_row_highlight_line(hl_name, line))
  end
end

function M.apply_gradient(logo, colored_logo, gradient_config)
  local top_color = gradient_config.top
  local bottom_color = gradient_config.bottom
  local logo_lines = #logo
  
  for i, line in ipairs(logo) do
    local ratio = (i - 1) / math.max(1, logo_lines - 1)
    local hl_name = 'LuxDashLogoGradient' .. i
    local color = M.interpolate_color(top_color, bottom_color, ratio)
    
    vim.api.nvim_set_hl(0, hl_name, {fg = color})
    table.insert(colored_logo, M.create_full_row_highlight_line(hl_name, line))
  end
end

function M.apply_preset(logo, colored_logo, preset)
  local color = color_presets[preset] or preset
  vim.api.nvim_set_hl(0, 'LuxDashLogo', {fg = color})
  
  for _, line in ipairs(logo) do
    table.insert(colored_logo, M.create_full_row_highlight_line('LuxDashLogo', line))
  end
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

  return rgb_to_hex({
    r = rgb1.r + (rgb2.r - rgb1.r) * ratio,
    g = rgb1.g + (rgb2.g - rgb1.g) * ratio,
    b = rgb1.b + (rgb2.b - rgb1.b) * ratio
  })
end

return M
