local M = {}

function M.command()
  return {
    keymap = "s",
    label = "Search Project",
    command = ":Files<CR>"
  }
end

return M