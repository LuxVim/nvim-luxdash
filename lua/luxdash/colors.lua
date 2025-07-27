local M = {}

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

return M