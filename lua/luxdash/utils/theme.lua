---Theme color extraction utilities
---Provides functions to extract and derive colors from the current Neovim theme
local M = {}

---Convert RGB table to hex color string
---@param rgb table RGB values {r, g, b}
---@return string hex Hex color string (#RRGGBB)
local function rgb_to_hex(rgb)
  return string.format('#%02x%02x%02x',
    math.floor(rgb.r + 0.5),
    math.floor(rgb.g + 0.5),
    math.floor(rgb.b + 0.5))
end

---Convert hex color to RGB table
---@param hex string Hex color (#RRGGBB or RRGGBB)
---@return table rgb RGB values {r, g, b}
local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16)
  }
end

---Get the foreground color from a highlight group
---@param group string Highlight group name
---@return string|nil hex Hex color or nil if not found
local function get_hl_fg(group)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  if hl.fg then
    return string.format('#%06x', hl.fg)
  end
  return nil
end

---Get the background color from a highlight group
---@param group string Highlight group name
---@return string|nil hex Hex color or nil if not found
local function get_hl_bg(group)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  if hl.bg then
    return string.format('#%06x', hl.bg)
  end
  return nil
end

---Adjust color brightness
---@param hex string Hex color
---@param factor number Brightness factor (> 1 to brighten, < 1 to darken)
---@return string hex Adjusted hex color
local function adjust_brightness(hex, factor)
  local rgb = hex_to_rgb(hex)
  return rgb_to_hex({
    r = math.min(255, rgb.r * factor),
    g = math.min(255, rgb.g * factor),
    b = math.min(255, rgb.b * factor)
  })
end

---Adjust color saturation
---@param hex string Hex color
---@param factor number Saturation factor (> 1 to saturate, < 1 to desaturate)
---@return string hex Adjusted hex color
local function adjust_saturation(hex, factor)
  local rgb = hex_to_rgb(hex)

  -- Convert to HSL, adjust saturation, convert back
  local r, g, b = rgb.r / 255, rgb.g / 255, rgb.b / 255
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local l = (max + min) / 2

  if max == min then
    -- Achromatic (gray)
    return hex
  end

  local d = max - min
  local s = l > 0.5 and d / (2 - max - min) or d / (max + min)

  -- Adjust saturation
  s = math.min(1, s * factor)

  -- Convert back to RGB
  local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end

  local h
  if max == r then
    h = (g - b) / d + (g < b and 6 or 0)
  elseif max == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  h = h / 6

  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q

  r = hue2rgb(p, q, h + 1/3)
  g = hue2rgb(p, q, h)
  b = hue2rgb(p, q, h - 1/3)

  return rgb_to_hex({ r = r * 255, g = g * 255, b = b * 255 })
end

---Extract gradient colors from the current theme
---Uses String (typically orange) for start and Function (typically purple) for bottom
---to match the classic LuxDash orange-to-purple gradient style
---@return table gradient {start = hex, bottom = hex}
function M.get_theme_gradient()
  -- Primary choice: String (orange) → Function (purple)
  -- This is the most common pairing that matches the original gradient
  local start_color = get_hl_fg('String')
  local bottom_color = get_hl_fg('Function')

  -- Enhance colors if found
  if start_color and start_color ~= '#000000' and start_color ~= '#ffffff' then
    start_color = adjust_saturation(start_color, 1.2)
    start_color = adjust_brightness(start_color, 1.1)
  else
    -- Fallback to classic LuxDash orange
    start_color = '#ff7801'
  end

  if bottom_color and bottom_color ~= '#000000' and bottom_color ~= '#ffffff' then
    bottom_color = adjust_saturation(bottom_color, 1.2)
    bottom_color = adjust_brightness(bottom_color, 1.1)
  else
    -- Fallback to classic LuxDash purple
    bottom_color = '#db2dee'
  end

  return {
    start = start_color,
    bottom = bottom_color
  }
end

---Check if a color is too dark or too light
---@param hex string Hex color
---@return boolean is_extreme True if color is too dark or too light
function M.is_extreme_color(hex)
  local rgb = hex_to_rgb(hex)
  local brightness = (rgb.r + rgb.g + rgb.b) / 3
  return brightness < 30 or brightness > 225
end

return M
