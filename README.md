# Icecast Server Setup

Author: Daniel "MaTachi" Jonsson
License: [MIT License](LICENSE)

## Features:

* **Distribution:** Debian 8 Jessie
* **Server:** Icecast2
* **Source:** mpd

## Setup

    $ sudo docker build -t matachi/icecast .

## Run

    $ sudo docker run -i -t -p 127.0.0.1:8000:8000 matachi/icecast

Inside the Docker container:

    $ python3 /home/auth.py

Next, open Firefox, SMPlayer, Clementine, VLC, or any other program that is
able to play an ogg vorbis audio stream. Then open
<http://127.0.0.1:8000/stream.ogg> and enjoy!

## About and what it does

The mount point `/stream.ogg` has url authentication turned on. The
authentication's `listener_add` value points to `http://127.0.0.1:5000/auth`.
At that port there is a local Python 3 Flask site running, started with
`python3 /home/auth.py` from inside the Docker container. Note that this site
won't be reachable from outside the Docker container. The Flask site will
always return the HTTP response "200 OK" along with the HTTP header
`icecast-auth-user = 1`. So the listener who connects to the stream will always
get authenticated. However, the site will, before returning the response,
launch mpd with `mpc play` if it isn't already playing a track. This means
that if there are no listeners, mpd can safely be stopped with `mpc stop`
without consuming any CPU cycles required for encoding the music to the stream.
In other words, if the Python code is extended further, it could turn off the
encoding to the stream if there are no listeners.
