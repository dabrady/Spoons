require('hs.spotify')
hs.spotify.tell = hs.fnutils.partial(hs.application.tell, 'Spotify')
