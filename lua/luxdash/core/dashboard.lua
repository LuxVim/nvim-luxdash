---Dashboard instance factory
---Creates dashboard instances to hold rendered content
local M = {}

---Create a new dashboard instance
---@return DashboardInstance
function M.create()
  local instance = {
    lines = {},
    metadata = {
      created_at = vim.loop.now(),
      line_count = 0
    }
  }

  ---Get all dashboard lines
  ---@return table lines Array of dashboard lines
  function instance:get_lines()
    return self.lines
  end

  ---Set dashboard lines (replaces all content)
  ---@param data table Array of lines
  function instance:set_lines(data)
    self.lines = data or {}
    self.metadata.line_count = #self.lines
  end

  ---Clear all dashboard content
  function instance:clear()
    self.lines = {}
    self.metadata.line_count = 0
  end

  ---Add a single line to the dashboard
  ---@param line any Line content (string or table)
  function instance:add_line(line)
    table.insert(self.lines, line)
    self.metadata.line_count = #self.lines
  end

  ---Add multiple lines to the dashboard
  ---@param lines table Array of lines
  function instance:add_lines(lines)
    for _, line in ipairs(lines) do
      table.insert(self.lines, line)
    end
    self.metadata.line_count = #self.lines
  end

  ---Get the number of lines in the dashboard
  ---@return number count Line count
  function instance:get_line_count()
    return #self.lines
  end

  ---Get dashboard metadata
  ---@return table metadata Dashboard metadata
  function instance:get_metadata()
    return vim.deepcopy(self.metadata)
  end

  return instance
end

return M