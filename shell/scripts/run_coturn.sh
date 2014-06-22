
#
# For WebRTC, 
# -a:   --lt-cred-mech, long-term authentication mechanism
# -r:   --realm, default realm
# -u:   --user, <user:pwd>
# -b:   --userdb, userdb config file.
# -f:   --fingerprint,
# --min-port, --max-port: limit port ranges
# -o:   --daemon,
# -X:   --external-ip, set if behind a NAT
# -v:   view connection users
#

realm="uskee.org"
user="user:passwd"
userdb="turnuserdb.conf"

turnserver -a -r $realm -f --min-port=50000 --max-port=60000 -v -o --syslog
#turnserver -a -r $realm -b $userdb -f --min-port=50000 --max-port=60000 -v -o --syslog
#turnserver -a -r $realm -u $user -f --min-port=50000 --max-port=60000 -v -o --syslog

exit 0
