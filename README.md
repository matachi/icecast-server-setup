# Icecast Server Setup

Author: Daniel "MaTachi" Jonsson  
License: [MIT License](LICENSE)

## Features:

* **Distribution:** Debian 8 Jessie
* **Server:** Icecast2.3.3-kh10
* **Source:** Liquidsoap
* **Audio codec:** It's set up to stream in Opus. However, Vorbis works fine
  too.

## Setup

    $ sudo docker build -t matachi/icecast .

## Run

    $ sudo docker run -i -t -p 127.0.0.1:8000:8000 matachi/icecast

Inside the Docker container:

    $ sudo -u user icecast -b -c /home/user/icecast.xml # Start Icecast
    $ sudo -u user liquidsoap /home/user/liquidsoap.conf & # Start Liquidsoap
    $ sudo -u user python3 /home/user/auth.py # Start authentication site

Next, open Firefox, Clementine, VLC, or any other program that is able to play
an Ogg Opus audio stream. Then open <http://127.0.0.1:8000/stream.opus> and
enjoy!

## About and what it does

The mount point `/stream.opus` has url authentication turned on. The
authentication's `listener_add` value points to `http://127.0.0.1:5000/auth`.
At that port there is a local Python 3 Flask site running, started with
`python3 /home/auth.py` from inside the Docker container. Note that this site
won't be reachable from outside the Docker container. The Flask site will
always return the HTTP response "200 OK" along with the HTTP header
`icecast-auth-user = 1`. So the listener who connects to the stream will always
get authenticated. However, the site could, before returning the response,
launch Liquidsoap if it isn't already playing a track (Not implemented yet).
This means that if there are no listeners, Liquidsoap could safely be turned
off, consuming no CPU cycles required for encoding the music to the stream. In
other words, if the Python code is extended further, it could turn off the
encoding to the stream if there are no listeners.
