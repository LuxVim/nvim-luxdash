local M = {}
local cache = require('luxdash.core.cache')

function M.calculate_layout(winheight, winwidth, layout_config)
  layout_config = layout_config or {}
  
  -- Create cache key for layout
  local config_hash = cache.hash_table(layout_config)
  
  -- Check cache first
  local cached_layout = cache.get_layout(winwidth, winheight, config_hash)
  if cached_layout then
    return cached_layout
  end
  
  local main_height_ratio = layout_config.main_height_ratio or 0.8
  local section_spacing = layout_config.section_spacing or 4
  local bottom_sections_equal_width = layout_config.bottom_sections_equal_width ~= false
  
  local main_height = math.floor(winheight * main_height_ratio)
  local bottom_height = winheight - main_height
  
  -- Main section now encompasses the full width for the logo
  local main_width = winwidth
  
  -- Calculate bottom section widths
  local available_width = winwidth - section_spacing
  local bottom_section_width = math.floor(available_width / 3)
  local bottom_left_width = bottom_section_width
  local bottom_center_width = bottom_section_width
  local bottom_right_width = available_width - bottom_left_width - bottom_center_width
  
  local layout_data = {
    main = {
      height = main_height,
      width = main_width
    },
    bottom = {
      height = bottom_height,
      width = winwidth, -- Total width for single section scenarios
      left = { width = bottom_left_width, height = bottom_height },
      center = { width = bottom_center_width, height = bottom_height },
      right = { width = bottom_right_width, height = bottom_height }
    }
  }
  
  -- Cache the result
  return cache.set_layout(layout_data, winwidth, winheight, config_hash)
end

function M.load_section(section_name)
  local ok, section_module = pcall(require, 'luxdash.sections.' .. section_name)
  if ok and section_module and type(section_module.render) == 'function' then
    return section_module
  end
  return nil
end

return M