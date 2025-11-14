local M = {}
local cache = require('luxdash.core.cache')
local highlight_pool = require('luxdash.core.highlight_pool')
local text_utils = require('luxdash.utils.text')

local color_presets = {
    blue = '#569cd6', green = '#4ec9b0', red = '#f44747', yellow = '#dcdcaa',
    purple = '#c586c0', orange = '#ce9178', pink = '#f392b1', cyan = '#4dd0e1'
}

-- Cache for computed colors and highlight groups
local color_cache = {}
local highlight_group_cache = {}

function M.create_full_row_highlight_line(highlight_group, text)
  return {
    {highlight_group, ''},
    {highlight_group, text},
    {highlight_group, ''}
  }
end

function M.get_cached_color(color1, color2, ratio)
  local cache_key = color1 .. '_' .. color2 .. '_' .. tostring(ratio)
  if color_cache[cache_key] then
    return color_cache[cache_key]
  end
  
  local color = M.interpolate_color(color1, color2, ratio)
  color_cache[cache_key] = color
  return color
end

function M.get_cached_highlight_group(base_name, index, color)
  local hl_name = base_name .. index
  if not highlight_group_cache[hl_name] then
    highlight_pool.create_highlight_group(hl_name, {fg = color})
    highlight_group_cache[hl_name] = true
  end
  return hl_name
end

function M.clear_color_cache()
  color_cache = {}
  highlight_group_cache = {}
end

function M.apply_logo_color(logo, color_config, window_width)
  if not color_config then return logo end

  -- Handle auto_theme option
  local effective_config = color_config
  local cache_config = color_config  -- Config used for cache key

  if color_config.auto_theme then
    local theme = require('luxdash.utils.theme')
    local theme_gradient = theme.get_theme_gradient()

    -- Use theme colors for the gradient
    effective_config = {
      row_gradient = {
        start = theme_gradient.start,
        bottom = theme_gradient.bottom
      }
    }

    -- Use the actual theme colors for cache key (not just auto_theme=true)
    -- This ensures cache is invalidated when theme changes
    cache_config = effective_config
  end

  -- Create cache key for logo processing
  local logo_hash = cache.hash_table(logo)
  local color_hash = cache.hash_table(cache_config)

  -- Check cache first
  local cached_logo = cache.get_logo(logo_hash, color_hash, window_width)
  if cached_logo then
    return cached_logo
  end

  local colored_logo = {}

  if effective_config.row_gradient and effective_config.row_gradient.start and effective_config.row_gradient.bottom then
    M.apply_row_gradient(logo, colored_logo, effective_config.row_gradient)
  elseif effective_config.gradient and effective_config.gradient.top and effective_config.gradient.bottom then
    M.apply_gradient(logo, colored_logo, effective_config.gradient)
  elseif effective_config.preset then
    M.apply_preset(logo, colored_logo, effective_config.preset)
  else
    return logo
  end

  -- Cache the result
  cache.set_logo(colored_logo, logo_hash, color_hash, window_width)
  return colored_logo
end

function M.apply_row_gradient(logo, colored_logo, gradient_config)
  local start_color = gradient_config.start
  local end_color = gradient_config.bottom
  local logo_lines = #logo
  
  highlight_pool.create_highlight_group('LuxDashLogo', {})
  
  for i, line in ipairs(logo) do
    local ratio = (i - 1) / math.max(1, logo_lines - 1)
    local color = M.get_cached_color(start_color, end_color, ratio)
    local hl_name = M.get_cached_highlight_group('LuxDashLogoRowGradient', i, color)
    
    table.insert(colored_logo, M.create_full_row_highlight_line(hl_name, line))
  end
end

function M.apply_gradient(logo, colored_logo, gradient_config)
  local top_color = gradient_config.top
  local bottom_color = gradient_config.bottom
  local logo_lines = #logo
  
  for i, line in ipairs(logo) do
    local ratio = (i - 1) / math.max(1, logo_lines - 1)
    local color = M.get_cached_color(top_color, bottom_color, ratio)
    local hl_name = M.get_cached_highlight_group('LuxDashLogoGradient', i, color)
    
    table.insert(colored_logo, M.create_full_row_highlight_line(hl_name, line))
  end
end

function M.apply_preset(logo, colored_logo, preset)
  local color = color_presets[preset] or preset
  highlight_pool.create_highlight_group('LuxDashLogo', {fg = color})
  
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
