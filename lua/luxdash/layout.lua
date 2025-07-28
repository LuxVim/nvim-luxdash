local M = {}

function M.calculate_layout(winheight, winwidth)
  local main_height = math.floor(winheight * 0.8)
  local bottom_height = winheight - main_height
  
  -- Main section now encompasses the full width for the logo
  local main_width = winwidth
  
  -- Account for 4 spaces total (2 spacers × 2 spaces each) between sections
  local spacer_width = 4
  local available_width = winwidth - spacer_width
  local bottom_section_width = math.floor(available_width / 3)
  local bottom_left_width = bottom_section_width
  local bottom_center_width = bottom_section_width
  local bottom_right_width = available_width - bottom_left_width - bottom_center_width
  
  return {
    main = {
      height = main_height,
      width = main_width
    },
    bottom = {
      height = bottom_height,
      left = { width = bottom_left_width, height = bottom_height },
      center = { width = bottom_center_width, height = bottom_height },
      right = { width = bottom_right_width, height = bottom_height }
    }
  }
end

function M.load_section(section_name)
  local ok, section_module = pcall(require, 'luxdash.sections.' .. section_name)
  if ok and section_module and type(section_module.render) == 'function' then
    return section_module
  end
  return nil
end

return M