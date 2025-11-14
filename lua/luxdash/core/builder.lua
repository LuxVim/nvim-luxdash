---Dashboard builder - constructs dashboard content using dependency injection
local M = {}

local layout = require('luxdash.layout')
local section_renderer = require('luxdash.rendering.section_renderer')
local line_formatter = require('luxdash.rendering.line_formatter')
local width_normalizer = require('luxdash.layout.width_normalizer')

---Build dashboard content using context
---@param context RenderContext Rendering context with all dependencies
function M.build(context)
  -- Validate context
  local valid, err = context:validate()
  if not valid then
    vim.notify('LuxDash: Invalid context - ' .. err, vim.log.levels.ERROR)
    return
  end

  local config = context.config
  local width = context.dimensions.width
  local height = context.dimensions.height

  -- Apply buffer padding with validation
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }

  -- Validate padding values
  vim.validate({
    ['padding.left'] = { padding.left, 'number' },
    ['padding.right'] = { padding.right, 'number' },
    ['padding.top'] = { padding.top, 'number' },
    ['padding.bottom'] = { padding.bottom, 'number' },
  })

  -- Ensure padding doesn't exceed window size
  padding.left = math.max(0, math.min(padding.left, width - 1))
  padding.right = math.max(0, math.min(padding.right, width - padding.left - 1))
  padding.top = math.max(0, math.min(padding.top, height - 1))
  padding.bottom = math.max(0, math.min(padding.bottom, height - padding.top - 1))

  local content_width = math.max(1, width - padding.left - padding.right)
  local content_height = math.max(1, height - padding.top - padding.bottom)

  local layout_data = layout.calculate_layout(content_height, content_width, config.layout_config)

  -- Clear dashboard before building
  context.dashboard:clear()

  -- Render sections
  M.render_main_section(context, layout_data)
  M.render_bottom_sections(context, layout_data)

  -- Update render count
  context:increment_render_count()
end

---Render main section (typically logo)
---@param context RenderContext Rendering context
---@param layout_data table Layout configuration
function M.render_main_section(context, layout_data)
  local config = context.config

  -- Validate config structure
  if not config.sections or not config.sections.main then
    vim.notify('LuxDash: Invalid configuration - missing sections.main', vim.log.levels.ERROR)
    return
  end

  local main_section_config = config.sections.main
  local ok, section_module = pcall(layout.load_section, main_section_config.type)

  if not ok or not section_module then
    vim.notify('LuxDash: Failed to load main section, using fallback logo', vim.log.levels.WARN)
    -- Fallback to logo section
    ok, section_module = pcall(layout.load_section, 'logo')
    if not ok or not section_module then
      vim.notify('LuxDash: Failed to load fallback logo section', vim.log.levels.ERROR)
      return
    end
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

  -- Render with error handling
  local ok, main_content = pcall(section_renderer.render_section,
    section_module,
    layout_data.main.width,
    layout_data.main.height,
    render_config
  )

  if not ok then
    vim.notify('LuxDash: Failed to render main section: ' .. tostring(main_content), vim.log.levels.ERROR)
    main_content = {}
  end

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
    context.dashboard:add_line(main_line)
  end
end

---Render bottom sections (menu, recent files, git status, etc.)
---@param context RenderContext Rendering context
---@param layout_data table Layout configuration
function M.render_bottom_sections(context, layout_data)
  local config = context.config
  local bottom_sections = config.sections.bottom or {}
  local sections_content = {}

  -- Render each bottom section
  for i, section_def in ipairs(bottom_sections) do
    if not section_def or not section_def.type then
      vim.notify(string.format('LuxDash: Invalid section definition at index %d', i), vim.log.levels.WARN)
      goto continue
    end

    local ok, section_module = pcall(layout.load_section, section_def.type)

    if ok and section_module then
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
        vertical_alignment = 'top',
        padding = { left = 2, right = 2 } -- Add consistent padding for all subsections
      }, section_def.config or {})

      -- Handle menu-specific config migration
      if section_def.type == 'menu' then
        local menu = require('luxdash.utils.menu')
        if render_config.menu_items and type(render_config.menu_items[1]) == 'string' then
          -- Convert string array to processed menu items
          render_config.menu_items = menu.options(render_config.menu_items)
        end
      end

      -- Apply alignment from config
      local alignment = render_config.alignment or {}
      render_config.title_alignment = alignment.title_horizontal or render_config.title_alignment
      render_config.content_alignment = alignment.content_horizontal or render_config.content_alignment
      render_config.vertical_alignment = alignment.vertical or render_config.vertical_alignment

      -- Render with error handling
      local render_ok, section_content = pcall(section_renderer.render_section,
        section_module,
        section_layout.width,
        section_layout.height,
        render_config
      )

      if not render_ok then
        vim.notify(string.format('LuxDash: Failed to render section %d: %s', i, tostring(section_content)), vim.log.levels.WARN)
        section_content = {}
      end

      table.insert(sections_content, {
        content = section_content,
        width = section_layout.width
      })
    else
      vim.notify(string.format('LuxDash: Failed to load section %d (%s), using empty fallback', i, section_def.type or 'unknown'), vim.log.levels.WARN)
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

    ::continue::
  end

  -- Combine sections horizontally
  M.combine_sections_horizontally(context, sections_content, layout_data.bottom.height)
end

function M.get_section_layout(section_index, total_sections, layout_data)
  -- Validate inputs
  vim.validate({
    section_index = { section_index, 'number' },
    total_sections = { total_sections, 'number' },
    layout_data = { layout_data, 'table' },
  })

  if section_index < 1 or section_index > total_sections then
    vim.notify(string.format('LuxDash: Invalid section_index %d (total: %d)', section_index, total_sections), vim.log.levels.WARN)
    return { width = 0, height = 0 }
  end

  if not layout_data.bottom then
    vim.notify('LuxDash: Missing layout_data.bottom', vim.log.levels.WARN)
    return { width = 0, height = 0 }
  end

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

---Combine multiple sections horizontally into dashboard lines
---@param context RenderContext Rendering context
---@param sections_content table Array of section content
---@param height number Target height
function M.combine_sections_horizontally(context, sections_content, height)
  for i = 1, height do
    local line_parts = {}

    for j, section in ipairs(sections_content) do
      local section_line = section.content[i] or string.rep(' ', section.width)
      section_line = width_normalizer.ensure_exact_width(section_line, section.width)
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
    
    -- Combine line parts while preserving section boundaries for proper highlighting
    local combined_line = line_formatter.combine_line_parts(line_parts)
    context.dashboard:add_line(combined_line)
  end
end

return M