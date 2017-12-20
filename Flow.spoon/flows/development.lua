BaseWorkflow = ... -- Expect our base object to be passed in while loading this file.
dev = BaseWorkflow.new('Development')

dev:setActionPalette({
  {
    name = 'Open project',
    command = function()
      local tapjoyProjectRoot = '~/github/tapjoy/'
      local tapjoyProjects = hs.chooser.generateChoiceTable(hs.fs.dirs(tapjoyProjectRoot))
      hs.chooser.new(
        function(project)
          if project ~= nil then
            local projectPath = tapjoyProjectRoot..project.text
            hs.execute('atom '..projectPath, true)
          end
        end
      ):choices(tapjoyProjects):show()
    end
  }
})

hs.hotkey.bind({'cmd', 'shift'}, '`', function() dev:enter() end)
