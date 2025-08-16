local M = {}
local alignment = require('luxdash.rendering.alignment')

-- Utility function to calculate available height for section content
function M.calculate_available_height(height, config)
  local available_height = height
  if config.show_title ~= false then
    available_height = available_height - 1  -- title
    if config.show_underline ~= false then
      available_height = available_height - 1  -- underline
    end
    if config.title_spacing ~= false then
      available_height = available_height - 1  -- spacing
    end
  end
  return math.max(0, available_height)
end

-- Utility function to get underline character based on style
function M.get_underline_char(style)
  local underline_styles = {
    line = '─',
    double = '═', 
    dots = '·',
    dashes = '-',
    none = ''
  }
  return underline_styles[style] or underline_styles.line
end

-- Standardized section renderer that handles title, underline, and content with proper alignment
function M.render_section(section_module, width, height, config)
  config = config or {}
  
  -- Section type determines highlight groups
  local section_type = config.section_type or 'sub' -- 'main' or 'sub'
  
  -- Default alignment settings
  local title_alignment = config.title_alignment or 'center'
  local content_alignment = config.content_alignment or 'center'
  local vertical_alignment = config.vertical_alignment or 'center'
  
  -- Padding settings for subsections
  local padding = nil
  if section_type == 'sub' and config.padding then
    padding = config.padding
  end
  local title_hl = section_type == 'main' and 'LuxDashMainTitle' or 'LuxDashSubTitle'
  local separator_hl = section_type == 'main' and 'LuxDashMainSeparator' or 'LuxDashSubSeparator'
  
  -- Allow custom highlight groups with section-specific naming
  if config.title_highlight then
    title_hl = config.title_highlight
  elseif config.section_id then
    -- Try section-specific highlight group first
    local section_title_hl = 'LuxDash' .. config.section_id:gsub('^%l', string.upper) .. 'Title'
    local highlights = require('luxdash.rendering.highlights')
    if highlights.groups[section_title_hl] then
      title_hl = section_title_hl
    end
  end
  
  if config.separator_highlight then
    separator_hl = config.separator_highlight
  elseif config.section_id then
    -- Try section-specific separator highlight
    local section_sep_hl = 'LuxDash' .. config.section_id:gsub('^%l', string.upper) .. 'Separator'
    local highlights = require('luxdash.rendering.highlights')
    if highlights.groups[section_sep_hl] then
      separator_hl = section_sep_hl
    end
  end
  
  -- Get content from the section module
  local raw_content = {}
  if section_module and section_module.render then
    raw_content = section_module.render(width, height, config) or {}
  end
  
  -- Build structured content
  local content = {}
  
  -- Add title if configured
  if config.title and config.show_title ~= false then
    local title_line = alignment.align_text(config.title, width, title_alignment, padding)
    table.insert(content, {title_hl, title_line})
    
    -- Add underline if configured
    if config.show_underline ~= false then
      local underline_width = width
      local underline_char = M.get_underline_char(config.underline_style)
      local underline = string.rep(underline_char, underline_width)
      
      table.insert(content, {separator_hl, underline})
    end
    
    -- Add spacing after title/underline
    if config.title_spacing ~= false then
      table.insert(content, '')
    end
  end
  
  -- Process and add section content
  for _, line in ipairs(raw_content) do
    if type(line) == 'table' then
      if #line >= 2 and type(line[1]) == 'string' and type(line[2]) == 'string' then
        -- Simple format: {highlight, text}
        local text = line[2]
        local highlight_group = line[1]
        local aligned_text = alignment.align_text_with_highlight(text, width, content_alignment, padding, highlight_group)
        table.insert(content, {highlight_group, aligned_text})
      elseif #line > 0 and type(line[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        -- Apply padding by modifying the line structure
        if padding and (padding.left or 0) > 0 then
          -- Add left padding to the complex line
          local padded_line = {}
          -- Add padding as first part
          table.insert(padded_line, {'Normal', string.rep(' ', padding.left)})
          -- Add all original parts
          for _, part in ipairs(line) do
            table.insert(padded_line, part)
          end
          table.insert(content, padded_line)
        else
          table.insert(content, line)
        end
      else
        -- Unknown table format - convert to string
        local text = tostring(line)
        local aligned_text = alignment.align_text(text, width, content_alignment, padding)
        table.insert(content, aligned_text)
      end
    else
      -- Plain text line
      local text = tostring(line or '')
      local aligned_text = alignment.align_text(text, width, content_alignment, padding)
      table.insert(content, aligned_text)
    end
  end
  
  -- For main sections (logo), allow content to exceed allocated height
  -- For sub-sections, ensure content doesn't exceed allocated height by truncating if necessary
  if section_type ~= 'main' then
    local max_content_height = height
    if #content > max_content_height then
      local truncated_content = {}
      for i = 1, max_content_height do
        table.insert(truncated_content, content[i])
      end
      content = truncated_content
    end
  end
  
  -- Apply vertical alignment
  return alignment.apply_vertical_alignment(content, width, height, vertical_alignment, section_type)
end

return M