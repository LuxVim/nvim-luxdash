local M = {}

function M.command()
  return {
    keymap = "r",
    label = "Recent Files",
    command = ":Backtrack<CR>"
  }
end

return M