local M = {}

-- Dashboard data storage
local dashboard = {}

function M.get_dashboard()
  return dashboard
end

function M.set_dashboard(data)
  dashboard = data or {}
end

function M.clear_dashboard()
  dashboard = {}
end

function M.add_line(line)
  table.insert(dashboard, line)
end

function M.get_line_count()
  return #dashboard
end

return M