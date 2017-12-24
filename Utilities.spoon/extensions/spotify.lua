local spotify_ext = {}

spotify_ext.tell = function(...)
  my.application.tell('Spotify', ...)
end

------

return spotify_ext
