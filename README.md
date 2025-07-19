# fish_flac2opus
convert flac to opus recursively with multithreading. art cover, tags management, parallelism. album artist. etc…
needs ffmpeg jq, imagemagick.
tested on macos, should works on linux too.

it will export the music with artist/year - album/disc number - track number - track title.opus
it will add a cover.jpg with 480px witdh (hiby r1 screen witdth)

if it’s a compilation it will try to use album artist instead of artist for the artist tag folder.

it use all the cores available.
