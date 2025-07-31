local M = {}
local dashboard_data = require('luxdash.core.dashboard')
local layout = require('luxdash.layout')
local section_renderer = require('luxdash.rendering.section_renderer')
local line_utils = require('luxdash.rendering.line_utils')

function M.build()
  local config = require('luxdash').config
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.api.nvim_win_get_width(0)
  
  -- Apply buffer padding
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }
  local content_width = winwidth - padding.left - padding.right
  local content_height = winheight - padding.top - padding.bottom
  
  local layout_data = layout.calculate_layout(content_height, content_width, config.layout_config)
  
  dashboard_data.clear_dashboard()
  
  -- Render main section
  M.render_main_section(config, layout_data)
  
  -- Render bottom sections dynamically
  M.render_bottom_sections(config, layout_data)
end

function M.render_main_section(config, layout_data)
  local main_section_config = config.sections.main
  local section_module = layout.load_section(main_section_config.type)
  
  if not section_module then
    -- Fallback to logo section
    section_module = layout.load_section('logo')
  end
  
  -- Prepare section config
  local render_config = vim.tbl_deep_extend('force', {
    logo = config.logo,
    logo_color = config.logo_color,
    section_type = 'main',
    title_alignment = 'center',
    content_alignment = 'center',
    vertical_alignment = 'center',
    show_title = false,
    show_underline = false
  }, main_section_config.config or {})
  
  local main_content = section_renderer.render_section(
    section_module, 
    layout_data.main.width, 
    layout_data.main.height, 
    render_config
  )
  
  -- Add main section lines - ensure we get all the content, not just the calculated height
  local actual_main_lines = #main_content
  local allocated_height = layout_data.main.height
  
  -- For logo sections, prioritize showing the complete logo over layout constraints
  local lines_to_add = math.max(actual_main_lines, allocated_height)
  
  -- If the main content (logo) is longer than allocated space, adjust the layout
  if actual_main_lines > allocated_height then
    -- Reduce bottom section height to accommodate the full logo
    layout_data.bottom.height = math.max(1, layout_data.bottom.height - (actual_main_lines - allocated_height))
    layout_data.main.height = actual_main_lines
  end
  
  for i = 1, lines_to_add do
    local main_line = main_content[i] or string.rep(' ', layout_data.main.width)
    dashboard_data.add_line(main_line)
  end
end

function M.render_bottom_sections(config, layout_data)
  local bottom_sections = config.sections.bottom or {}
  local sections_content = {}
  
  -- Render each bottom section
  for i, section_def in ipairs(bottom_sections) do
    local section_module = layout.load_section(section_def.type)
    
    if section_module then
      -- Calculate section width and get layout data
      local section_layout = M.get_section_layout(i, #bottom_sections, layout_data)
      
      -- Prepare section config
      local render_config = vim.tbl_deep_extend('force', {
        section_type = 'sub',
        title = section_def.title,
        show_title = true,
        show_underline = true,
        title_alignment = 'center',
        content_alignment = 'center',
        vertical_alignment = 'top'
      }, section_def.config or {})
      
      -- Handle menu-specific config migration
      if section_def.type == 'menu' then
        local menu = require('luxdash.utils.menu')
        render_config.menu_items = render_config.menu_items or menu.options(config.options or {})
        render_config.extras = render_config.extras or config.extras or {}
      end
      
      -- Apply alignment from config
      local alignment = render_config.alignment or {}
      render_config.title_alignment = alignment.title_horizontal or render_config.title_alignment
      render_config.content_alignment = alignment.content_horizontal or render_config.content_alignment
      render_config.vertical_alignment = alignment.vertical or render_config.vertical_alignment
      
      local section_content = section_renderer.render_section(
        section_module,
        section_layout.width,
        section_layout.height,
        render_config
      )
      
      table.insert(sections_content, {
        content = section_content,
        width = section_layout.width
      })
    else
      -- Empty section fallback
      local section_layout = M.get_section_layout(i, #bottom_sections, layout_data)
      local empty_content = {}
      for j = 1, section_layout.height do
        table.insert(empty_content, string.rep(' ', section_layout.width))
      end
      table.insert(sections_content, {
        content = empty_content,
        width = section_layout.width
      })
    end
  end
  
  -- Combine sections horizontally
  M.combine_sections_horizontally(sections_content, layout_data.bottom.height)
end

function M.get_section_layout(section_index, total_sections, layout_data)
  if total_sections == 1 then
    return {
      width = layout_data.bottom.width or layout_data.bottom.left.width + layout_data.bottom.center.width + layout_data.bottom.right.width,
      height = layout_data.bottom.height
    }
  elseif total_sections == 2 then
    if section_index == 1 then
      return {
        width = layout_data.bottom.left.width + math.floor((layout_data.bottom.center.width + layout_data.bottom.right.width) / 2),
        height = layout_data.bottom.height
      }
    else
      return {
        width = math.ceil((layout_data.bottom.center.width + layout_data.bottom.right.width) / 2),
        height = layout_data.bottom.height
      }
    end
  else
    -- Three or more sections - use the existing layout
    if section_index == 1 then
      return {
        width = layout_data.bottom.left.width,
        height = layout_data.bottom.height
      }
    elseif section_index == 2 then
      return {
        width = layout_data.bottom.center.width,
        height = layout_data.bottom.height
      }
    else
      return {
        width = layout_data.bottom.right.width,
        height = layout_data.bottom.height
      }
    end
  end
end

function M.combine_sections_horizontally(sections_content, height)
  -- Helper function to ensure exact width
  local function ensure_exact_width(line, target_width)
    -- For complex format lines, use line_utils to properly handle width
    if type(line) == 'table' and #line > 0 and type(line[1]) == 'table' then
      -- Complex format: {{highlight, text}, {highlight, text}, ...}
      local combined = line_utils.combine_line_parts({line})
      local text = type(combined) == 'table' and combined[1] or combined
      local text_width = vim.fn.strwidth(text)
      
      if text_width < target_width then
        -- Add padding by appending spaces to the combined text
        local padding = string.rep(' ', target_width - text_width)
        -- Return the original complex format with padding appended
        local padded_line = {}
        for _, part in ipairs(line) do
          table.insert(padded_line, part)
        end
        if target_width > text_width then
          table.insert(padded_line, {'Normal', padding})
        end
        return padded_line
      elseif text_width > target_width then
        -- Truncate by removing characters from the end
        return line -- For now, let section renderer handle truncation
      end
      return line
    elseif type(line) == 'table' and line[2] then
      -- Simple format: {highlight, text}
      local text = tostring(line[2])
      local text_width = vim.fn.strwidth(text)
      if text_width < target_width then
        return {line[1], text .. string.rep(' ', target_width - text_width)}
      elseif text_width > target_width then
        return {line[1], vim.fn.strpart(text, 0, target_width)}
      end
      return line
    else
      -- Plain text
      local text = tostring(line)
      local text_width = vim.fn.strwidth(text)
      if text_width < target_width then
        return text .. string.rep(' ', target_width - text_width)
      elseif text_width > target_width then
        return vim.fn.strpart(text, 0, target_width)
      end
      return text
    end
  end

  for i = 1, height do
    local line_parts = {}
    
    for j, section in ipairs(sections_content) do
      local section_line = section.content[i] or string.rep(' ', section.width)
      section_line = ensure_exact_width(section_line, section.width)
      table.insert(line_parts, section_line)
      
      -- Add spacer between sections (except after the last one)
      if j < #sections_content then
        -- Check if this is an underline row
        local function contains_underline(line)
          if type(line) == 'table' then
            if line[2] and type(line[2]) == 'string' then
              -- Simple format: {highlight, text}
              return string.find(line[2], '─') ~= nil
            elseif #line > 0 and type(line[1]) == 'table' then
              -- Complex format: {{highlight, text}, {highlight, text}, ...}
              for _, part in ipairs(line) do
                if type(part) == 'table' and part[2] and type(part[2]) == 'string' and string.find(part[2], '─') then
                  return true
                end
              end
            end
          elseif type(line) == 'string' then
            return string.find(line, '─') ~= nil
          end
          return false
        end
        
        if contains_underline(section_line) then
          -- Add vertical separator on underline rows
          table.insert(line_parts, {'LuxDashSubSeparator', '│'})
        else
          -- Add spacing on regular content rows
          table.insert(line_parts, string.rep(' ', 2))
        end
      end
    end
    
    local combined_line = line_utils.combine_line_parts(line_parts)
    dashboard_data.add_line(combined_line)
  end
end

return M