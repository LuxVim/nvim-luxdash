--- Configuration validation module for nvim-luxdash
--- Validates user configuration to catch errors early and provide helpful feedback
local M = {}

local constants = require('luxdash.constants')

--- Validate the entire configuration object
--- @param config table User configuration to validate
--- @return boolean success True if valid, false otherwise
--- @return string|nil error Error message if validation failed
function M.validate(config)
  if type(config) ~= 'table' then
    return false, 'Configuration must be a table'
  end

  -- Validate float configuration
  if config.float then
    local ok, err = M.validate_float(config.float)
    if not ok then
      return false, 'float: ' .. err
    end
  end

  -- Validate layout configuration
  if config.layout_config then
    local ok, err = M.validate_layout_config(config.layout_config)
    if not ok then
      return false, 'layout_config: ' .. err
    end
  end

  -- Validate padding
  if config.padding then
    local ok, err = M.validate_padding(config.padding)
    if not ok then
      return false, 'padding: ' .. err
    end
  end

  -- Validate logo
  if config.logo then
    local ok, err = M.validate_logo(config.logo)
    if not ok then
      return false, 'logo: ' .. err
    end
  end

  -- Validate logo color
  if config.logo_color then
    local ok, err = M.validate_logo_color(config.logo_color)
    if not ok then
      return false, 'logo_color: ' .. err
    end
  end

  -- Validate sections
  if config.sections then
    local ok, err = M.validate_sections(config.sections)
    if not ok then
      return false, 'sections: ' .. err
    end
  end

  return true, nil
end

--- Validate float window configuration
--- @param float table Float window config
--- @return boolean success
--- @return string|nil error
function M.validate_float(float)
  if type(float) ~= 'table' then
    return false, 'must be a table'
  end

  -- Validate width
  if float.width ~= nil then
    if type(float.width) ~= 'number' then
      return false, 'width must be a number'
    end
    if float.width <= 0 then
      return false, 'width must be positive'
    end
    if float.width > 1 and float.width > 1000 then
      return false, 'width is unreasonably large (max 1000 for absolute values)'
    end
  end

  -- Validate height
  if float.height ~= nil then
    if type(float.height) ~= 'number' then
      return false, 'height must be a number'
    end
    if float.height <= 0 then
      return false, 'height must be positive'
    end
    if float.height > 1 and float.height > 1000 then
      return false, 'height is unreasonably large (max 1000 for absolute values)'
    end
  end

  -- Validate border
  if float.border ~= nil then
    local valid_borders = {
      'none', 'single', 'double', 'rounded', 'solid', 'shadow'
    }
    if type(float.border) == 'string' then
      local valid = false
      for _, border in ipairs(valid_borders) do
        if float.border == border then
          valid = true
          break
        end
      end
      if not valid then
        return false, string.format(
          'border must be one of: %s',
          table.concat(valid_borders, ', ')
        )
      end
    elseif type(float.border) ~= 'table' then
      return false, 'border must be a string or table'
    end
  end

  -- Validate title_pos
  if float.title_pos ~= nil then
    local valid_positions = { 'left', 'center', 'right' }
    local valid = false
    for _, pos in ipairs(valid_positions) do
      if float.title_pos == pos then
        valid = true
        break
      end
    end
    if not valid then
      return false, string.format(
        'title_pos must be one of: %s',
        table.concat(valid_positions, ', ')
      )
    end
  end

  return true, nil
end

--- Validate layout configuration
--- @param layout_config table Layout config
--- @return boolean success
--- @return string|nil error
function M.validate_layout_config(layout_config)
  if type(layout_config) ~= 'table' then
    return false, 'must be a table'
  end

  -- Validate main_height_ratio
  if layout_config.main_height_ratio ~= nil then
    if type(layout_config.main_height_ratio) ~= 'number' then
      return false, 'main_height_ratio must be a number'
    end
    if layout_config.main_height_ratio < 0 or layout_config.main_height_ratio > 1 then
      return false, 'main_height_ratio must be between 0 and 1'
    end
  end

  -- Validate section_spacing
  if layout_config.section_spacing ~= nil then
    if type(layout_config.section_spacing) ~= 'number' then
      return false, 'section_spacing must be a number'
    end
    if layout_config.section_spacing < 0 then
      return false, 'section_spacing must be non-negative'
    end
  end

  -- Validate bottom_sections_equal_width
  if layout_config.bottom_sections_equal_width ~= nil then
    if type(layout_config.bottom_sections_equal_width) ~= 'boolean' then
      return false, 'bottom_sections_equal_width must be a boolean'
    end
  end

  return true, nil
end

--- Validate padding configuration
--- @param padding table Padding config
--- @return boolean success
--- @return string|nil error
function M.validate_padding(padding)
  if type(padding) ~= 'table' then
    return false, 'must be a table'
  end

  local sides = { 'left', 'right', 'top', 'bottom' }
  for _, side in ipairs(sides) do
    if padding[side] ~= nil then
      if type(padding[side]) ~= 'number' then
        return false, string.format('%s must be a number', side)
      end
      if padding[side] < 0 then
        return false, string.format('%s must be non-negative', side)
      end
    end
  end

  return true, nil
end

--- Validate logo configuration
--- @param logo table|string Logo config
--- @return boolean success
--- @return string|nil error
function M.validate_logo(logo)
  if type(logo) == 'string' then
    -- Single string logo is valid
    return true, nil
  end

  if type(logo) ~= 'table' then
    return false, 'must be a string or table (array of strings)'
  end

  -- Check if it's an array of strings
  for i, line in ipairs(logo) do
    if type(line) ~= 'string' then
      return false, string.format('line %d must be a string', i)
    end
  end

  return true, nil
end

--- Validate logo color configuration
--- @param logo_color table Logo color config
--- @return boolean success
--- @return string|nil error
function M.validate_logo_color(logo_color)
  if type(logo_color) ~= 'table' then
    return false, 'must be a table'
  end

  -- Check for preset
  if logo_color.preset then
    local valid_presets = vim.tbl_keys(constants.COLOR_PRESETS)
    local valid = false
    for _, preset in ipairs(valid_presets) do
      if logo_color.preset == preset then
        valid = true
        break
      end
    end
    if not valid then
      return false, string.format(
        'preset must be one of: %s',
        table.concat(valid_presets, ', ')
      )
    end
  end

  -- Check for row_gradient
  if logo_color.row_gradient then
    if type(logo_color.row_gradient) ~= 'table' then
      return false, 'row_gradient must be a table'
    end

    if not logo_color.row_gradient.start then
      return false, 'row_gradient.start is required'
    end
    if not logo_color.row_gradient.bottom then
      return false, 'row_gradient.bottom is required'
    end

    -- Validate hex color format
    local function is_hex_color(color)
      return type(color) == 'string' and color:match('^#%x%x%x%x%x%x$') ~= nil
    end

    if not is_hex_color(logo_color.row_gradient.start) then
      return false, 'row_gradient.start must be a hex color (e.g., #ff7801)'
    end
    if not is_hex_color(logo_color.row_gradient.bottom) then
      return false, 'row_gradient.bottom must be a hex color (e.g., #db2dee)'
    end
  end

  return true, nil
end

--- Validate sections configuration
--- @param sections table Sections config
--- @return boolean success
--- @return string|nil error
function M.validate_sections(sections)
  if type(sections) ~= 'table' then
    return false, 'must be a table'
  end

  -- Validate main section
  if sections.main then
    local ok, err = M.validate_section(sections.main, 'main')
    if not ok then
      return false, 'main: ' .. err
    end
  end

  -- Validate bottom sections
  if sections.bottom then
    if type(sections.bottom) ~= 'table' then
      return false, 'bottom must be a table (array of sections)'
    end

    for i, section in ipairs(sections.bottom) do
      local ok, err = M.validate_section(section, 'bottom[' .. i .. ']')
      if not ok then
        return false, err
      end
    end
  end

  return true, nil
end

--- Validate a single section configuration
--- @param section table Section config
--- @param name string Section name for error messages
--- @return boolean success
--- @return string|nil error
function M.validate_section(section, name)
  if type(section) ~= 'table' then
    return false, name .. ' must be a table'
  end

  -- Type is required
  if not section.type then
    return false, name .. ' must have a type field'
  end
  if type(section.type) ~= 'string' then
    return false, name .. '.type must be a string'
  end

  -- Validate known section types
  local valid_types = { 'logo', 'menu', 'recent_files', 'git_status', 'empty' }
  local valid = false
  for _, section_type in ipairs(valid_types) do
    if section.type == section_type then
      valid = true
      break
    end
  end
  if not valid then
    return false, string.format(
      '%s.type must be one of: %s',
      name,
      table.concat(valid_types, ', ')
    )
  end

  -- Validate config if present
  if section.config and type(section.config) ~= 'table' then
    return false, name .. '.config must be a table'
  end

  -- Validate alignment if present
  if section.config and section.config.alignment then
    local ok, err = M.validate_alignment(section.config.alignment)
    if not ok then
      return false, name .. '.config.alignment: ' .. err
    end
  end

  -- Validate padding if present
  if section.config and section.config.padding then
    local ok, err = M.validate_padding(section.config.padding)
    if not ok then
      return false, name .. '.config.padding: ' .. err
    end
  end

  return true, nil
end

--- Validate alignment configuration
--- @param alignment table Alignment config
--- @return boolean success
--- @return string|nil error
function M.validate_alignment(alignment)
  if type(alignment) ~= 'table' then
    return false, 'must be a table'
  end

  local valid_horizontal = { 'left', 'center', 'right' }
  local valid_vertical = { 'top', 'center', 'bottom' }

  if alignment.horizontal then
    local valid = false
    for _, align in ipairs(valid_horizontal) do
      if alignment.horizontal == align then
        valid = true
        break
      end
    end
    if not valid then
      return false, string.format(
        'horizontal must be one of: %s',
        table.concat(valid_horizontal, ', ')
      )
    end
  end

  if alignment.vertical then
    local valid = false
    for _, align in ipairs(valid_vertical) do
      if alignment.vertical == align then
        valid = true
        break
      end
    end
    if not valid then
      return false, string.format(
        'vertical must be one of: %s',
        table.concat(valid_vertical, ', ')
      )
    end
  end

  return true, nil
end

--- Validate and warn about configuration issues
--- This is a non-fatal validation that produces warnings instead of errors
--- @param config table Configuration to validate
function M.validate_and_warn(config)
  local ok, err = M.validate(config)

  if not ok then
    vim.notify(
      'LuxDash configuration validation failed: ' .. err,
      vim.log.levels.ERROR
    )
    vim.notify(
      'Check :help luxdash-config for configuration documentation',
      vim.log.levels.INFO
    )
  end

  return ok
end

return M
