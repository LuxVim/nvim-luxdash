---Event bus for decoupled component communication
---Allows components to communicate without direct dependencies
local M = {}

---@type table<string, function[]>
local handlers = {}

---Register an event handler
---@param event string Event name
---@param handler function Callback function to handle the event
function M.on(event, handler)
  if type(handler) ~= 'function' then
    error('Event handler must be a function')
  end

  handlers[event] = handlers[event] or {}
  table.insert(handlers[event], handler)
end

---Emit an event to all registered handlers
---@param event string Event name
---@param ... any Arguments to pass to handlers
function M.emit(event, ...)
  local event_handlers = handlers[event]
  if not event_handlers then
    return
  end

  for _, handler in ipairs(event_handlers) do
    local ok, err = pcall(handler, ...)
    if not ok then
      vim.notify(
        string.format('LuxDash event handler error (%s): %s', event, tostring(err)),
        vim.log.levels.ERROR
      )
    end
  end
end

---Remove all handlers for an event
---@param event string Event name
function M.clear(event)
  handlers[event] = nil
end

---Remove all handlers for all events
function M.clear_all()
  handlers = {}
end

---Get count of handlers for an event (for testing)
---@param event string Event name
---@return number count Number of handlers registered
function M.count_handlers(event)
  return handlers[event] and #handlers[event] or 0
end

return M
