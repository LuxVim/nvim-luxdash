-- In small windows, give controls and file entries the available rows first.
local M = {}
local text = require('luxdash.utils.text')
local normalizer = require('luxdash.layout.width_normalizer')
local sections = require('luxdash.rendering.section_renderer')

function M.build(context, width, height)
  local dashboard, config = context.dashboard, context.config
  local menu = require('luxdash.utils.menu')
  local recent = require('luxdash.sections.recent_files')
  dashboard:clear()
  menu.clear(context.bufnr)
  if context.bufnr then recent.clear_file_keymaps(context.bufnr) end
  dashboard:add_line({ 'LuxDashMainTitle', text.truncate_chars(config.name or 'LuxDash', width) })
  local remaining = height - 1
  if remaining > 6 then dashboard:add_line(''); remaining = remaining - 1 end
  local actions, files
  for _, section in ipairs(config.sections.bottom or {}) do
    if section.type == 'menu' then actions = section end
    if section.type == 'recent_files' then files = section end
  end

  local function append(module, definition, allocated, extra)
    local opts = vim.tbl_deep_extend('force', definition.config or {}, {
      title = definition.title, show_title = true, show_underline = false,
      title_spacing = false, content_alignment = 'left', title_alignment = 'left',
      vertical_alignment = 'top', padding = { left = 0, right = 0 }, section_type = 'sub',
    }, extra or {})
    for _, line in ipairs(sections.render_section(module, width, allocated, opts, context)) do
      dashboard:add_line(normalizer.ensure_exact_width(line, width))
    end
    remaining = remaining - allocated
  end

  if actions and remaining > 0 then
    local definitions = (actions.config or {}).menu_items or {}
    local count = math.min(#definitions, math.max(0, remaining - 1))
    local items = definitions
    if type(definitions[1]) == 'string' then items = menu.options(definitions, context.bufnr, count) end
    append(require('luxdash.sections.menu'), actions, math.min(remaining, #items + 1), { menu_items = items })
  end
  if files and remaining > 0 then
    append(recent, files, remaining)
  end
end

return M
