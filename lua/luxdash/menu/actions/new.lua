local M = {}

function M.command()
  return {
    keymap = "n",
    label = "New File",
    command = ":enew<CR>"
  }
end

return M