FROM debian:jessie

RUN apt-get update

######################################################################
# Icecast
######################################################################
RUN apt-get install -y icecast2
RUN sed -i 's/^ENABLE=false$/ENABLE=true/' /etc/default/icecast2
RUN sed -i 's/^\(<\/icecast>\)$/    <mount>\n        <mount-name>\/stream.ogg<\/mount-name>\n        <authentication type="url">\n            <option name="listener_add" value="http:\/\/127\.0\.0\.1:5000\/auth"\/>\n        <\/authentication>\n    <\/mount>\n\1/' /etc/icecast2/icecast.xml

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
RUN apt-get install -y wget
RUN wget http://www.jonobacon.org/files/freesoftwaresong/jonobacon-freesoftwaresong2.ogg
RUN mv jonobacon-freesoftwaresong2.ogg /var/lib/mpd/music/.

# Setting being inserted:
#
#     audio_output {
#       type            "shout"
#       name            "RasPi MPD Stream"
#       description     "MPD stream on Raspberry Pi"
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

CMD /etc/init.d/icecast2 start && /etc/init.d/mpd start && mpc update && mpc ls | mpc add && mpc repeat on && bash
