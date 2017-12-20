fs = require('hs.fs')

-- Returns a list of directories in the given path.
function fs.dirs(path)
  local _,directoryContents = hs.fs.dir(path)
  local directories = {}
  repeat
    local filename = directoryContents:next()
    if (
      filename and
      filename:match("^%.") == nil and -- Exclude dotfiles
      hs.fs.attributes(path..filename, 'mode') == 'directory'
    ) then

      table.insert(directories, filename)
    end
  until filename == nil
  directoryContents:close()

  return directories
end
