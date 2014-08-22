FROM ubuntu:trusty

RUN apt-get update
RUN apt-get dist-upgrade -y

######################################################################
# Icecast
######################################################################

# Download Icecast kh source and build tools
RUN apt-get install -y wget
RUN wget --no-check-certificate http://github.com/karlheyes/icecast-kh/archive/icecast-2.3.3-kh10.tar.gz
RUN tar xvfz icecast-2.3.3-kh10.tar.gz
RUN apt-get install -y build-essential
RUN apt-get install -y libxml2-dev libxslt1-dev curl libcurl4-openssl-dev libvorbis-dev libogg-dev

# Compile and install
RUN cd icecast-kh-icecast-2.3.3-kh10 && ./configure
RUN cd icecast-kh-icecast-2.3.3-kh10 && make
RUN cd icecast-kh-icecast-2.3.3-kh10 && make install

# Create user
RUN useradd -d /home/user -m user

# Set up user and config
RUN cp /usr/local/etc/icecast.xml /home/user/.
RUN chown user /home/user/icecast.xml
RUN mkdir -p /usr/local/var/log/icecast
RUN touch /usr/local/var/log/icecast/error.log
RUN chown -R user /usr/local/var/log/icecast
RUN apt-get install -y sudo mime-support
RUN sed -i 's/^\(<\/icecast>\)$/\
    <mount>\
        <mount-name>\/stream.opus<\/mount-name>\
        <authentication type="url">\
            <option name="listener_add" value="http:\/\/127\.0\.0\.1:5000\/auth"\/>\
        <\/authentication>\
    <\/mount>\n\1/' /home/user/icecast.xml

# The mount being inserted:
#
#     <mount>
#         <mount-name>/stream.opus</mount-name>
#         <authentication type="url">
#             <option name="listener_add" value="http://127.0.0.1:5000/auth"/>
#         </authentication>
#     </mount>

######################################################################
# Liquidsoap
######################################################################

# Compile Liquidsoap
# The pre-built version of Liquidsoap seems to have some issues
RUN apt-get build-dep -y liquidsoap
RUN apt-get source -y liquidsoap
RUN cd liquidsoap-1.1.1 && ./configure
RUN cd liquidsoap-1.1.1 && make
RUN cd liquidsoap-1.1.1 && make install

# Download sample song
RUN wget http://www.jonobacon.org/files/freesoftwaresong/jonobacon-freesoftwaresong2.ogg
RUN mv jonobacon-freesoftwaresong2.ogg /home/user/.

# Create playlist
RUN echo "/home/user/jonobacon-freesoftwaresong2.ogg" > /home/user/music.m3u

# Otherwise an exclamation mark will throw an error in echo
# http://www.linuxquestions.org/questions/programming-9/bash-double-quotes-don%27t-protect-exclamation-marks-545662/
RUN h=$histchars
RUN histchars=

RUN echo "#!/usr/bin/liquidsoap\n\
# Log dir\n\
set(\"log.file.path\",\"/tmp/liquidsoap.log\")\n\
\n\
# Music\n\
myplaylist = playlist(\"/home/user/music.m3u\")\n\
# If something goes wrong, we'll play this\n\
security = single(\"/home/user/jonobacon-freesoftwaresong2.ogg\")\n\
\n\
# Start building the feed with music\n\
radio = myplaylist\n\
# And finally the security\n\
radio = fallback(track_sensitive = false, [radio, security])\n\
\n\
# Stream it out\n\
output.icecast(%opus,\n\
  host = \"localhost\", port = 8000,\n\
  password = \"hackme\", mount = \"stream.opus\",\n\
  radio)" > /home/user/liquidsoap.conf

RUN histchars=$h

# Setting being inserted:
#
#     #!/usr/bin/liquidsoap
#     # Log dir
#     set("log.file.path","/tmp/liquidsoap.log")
#
#     # Music
#     myplaylist = playlist("/home/user/music.m3u")
#     # If something goes wrong, we'll play this
#     security = single("/home/user/jonobacon-freesoftwaresong2.ogg")
#
#     # Start building the feed with music
#     radio = myplaylist
#     # And finally the security
#     radio = fallback(track_sensitive = false, [radio, security])
#
#      # Stream it out
#     output.icecast(%opus,
#       host = "localhost", port = 8000,
#       password = "hackme", mount = "stream.opus",
#       radio)

######################################################################
# Script
######################################################################

RUN apt-get install -y python3-pip
RUN pip3 install Flask
RUN echo "from flask import Flask\nfrom flask import make_response\nimport time\napp = Flask(__name__)\n\n@app.route('/auth', methods=['POST'])\ndef auth():\n    # Start Liquidsoap here\n    time.sleep(1)\n    resp = make_response('', 200)\n    resp.headers['icecast-auth-user'] = 1\n    return resp\n\nif __name__ == '__main__':\n    app.run()" > /home/user/auth.py

# The script being inserted:
#
#     from flask import Flask
#     from flask import make_response
#     import time
#     app = Flask(__name__)
#
#     @app.route('/auth', methods=['POST'])
#     def auth():
#         # Start Liquidsoap here
#         time.sleep(1)
#         resp = make_response('', 200)
#         resp.headers['icecast-auth-user'] = 1
#         return resp

######################################################################
# CMD
######################################################################

CMD bash
