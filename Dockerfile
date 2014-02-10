FROM debian:latest

RUN apt-get update

######################################################################
# Icecast
######################################################################

RUN apt-get install -y wget
RUN wget --no-check-certificate http://github.com/karlheyes/icecast-kh/archive/icecast-2.3.3-kh9.tar.gz
RUN tar xvfz icecast-2.3.3-kh9.tar.gz
RUN apt-get install -y build-essential
RUN apt-get install -y libxml2-dev libxslt1-dev curl libcurl4-openssl-dev libvorbis-dev libogg-dev
RUN cd icecast-kh-icecast-2.3.3-kh9 && ./configure
RUN cd icecast-kh-icecast-2.3.3-kh9 && make
RUN cd icecast-kh-icecast-2.3.3-kh9 && make install
RUN mkdir -p /usr/local/var/log
RUN useradd user -m
RUN cp /usr/local/etc/icecast.xml /home/user/.
RUN chown user /home/user/icecast.xml
RUN mkdir -p /usr/local/var/log/icecast
RUN touch /usr/local/var/log/icecast/error.log
RUN chown user /usr/local/var/log/icecast
RUN apt-get install -y sudo mime-support
RUN sed -i 's/^\(<\/icecast>\)$/\
    <mount>\
        <mount-name>\/stream.ogg<\/mount-name>\
        <authentication type="url">\
            <option name="listener_add" value="http:\/\/127\.0\.0\.1:5000\/auth"\/>\
        <\/authentication>\
    <\/mount>\n\1/' /home/user/icecast.xml

# The mount being inserted:
#
#     <mount>
#         <mount-name>/stream.ogg</mount-name>
#         <authentication type="url">
#             <option name="listener_add" value="http://127.0.0.1:5000/auth"/>
#         </authentication>
#     </mount>

######################################################################
# Script
######################################################################
RUN apt-get install -y python3 python3-pip
RUN pip3 install Flask
RUN echo "from flask import Flask\nfrom flask import make_response\nfrom subprocess import call\nimport time\napp = Flask(__name__)\n\n@app.route('/auth', methods=['POST'])\ndef auth():\n    call(['mpc', 'play'])\n    time.sleep(1)\n    resp = make_response('', 200)\n    resp.headers['icecast-auth-user'] = 1\n    return resp\n\nif __name__ == '__main__':\n    app.run()" > /home/auth.py

# The script being inserted:
#
#     from flask import Flask
#     from flask import make_response
#     from subprocess import call
#     import time
#     app = Flask(__name__)
#
#     @app.route('/auth', methods=['POST'])
#     def auth():
#         call(['mpc', 'play'])
#         time.sleep(1)
#         resp = make_response('', 200)
#         resp.headers['icecast-auth-user'] = 1
#         return resp

######################################################################
# MPD and MPC
######################################################################

RUN apt-get install -y mpc mpd
RUN sed -i 's/^\(audio_output\)/audio_output \{\n  type            "shout"\n  name            "RasPi MPD Stream"\n  description     "MPD stream on Raspberry Pi"\n  host            "localhost"\n  port            "8000"\n  mount           "\/stream\.ogg"\n  password        "hackme"\n  bitrate         "128"\n  format          "44100:16:2"\n  encoding        "ogg"\n  protocol        "icecast2"\n\}\n\n\1/' /etc/mpd.conf
RUN wget http://www.jonobacon.org/files/freesoftwaresong/jonobacon-freesoftwaresong2.ogg
RUN mv jonobacon-freesoftwaresong2.ogg /var/lib/mpd/music/.

# Setting being inserted:
#
#     audio_output {
#       type            "shout"
#       name            "Stream"
#       description     "MPD stream"
#       host            "localhost"
#       port            "8000"
#       mount           "/stream.ogg"
#       password        "hackme"
#       bitrate         "128"
#       format          "44100:16:2"
#       encoding        "ogg"
#       protocol        "icecast2"
#     }

######################################################################
# CMD
######################################################################

CMD sudo -u user icecast -b -c /home/user/icecast.xml && /etc/init.d/mpd start && mpc update && mpc ls | mpc add && mpc repeat on && mpc play && bash
