local M = {}

function M.command()
  return {
    keymap = "q",
    label = "Quit",
    command = ":qa!<CR>"
  }
end

return M