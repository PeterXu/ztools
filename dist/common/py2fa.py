import sys

try:
    import pyotp
except:
    print("WARN: pls install pyotp by pip!\n")
    sys.exit(2)

def print_usage():
    print("Usage:")
    print("  %s key" % sys.argv[0])
    print("  %s key index" % sys.argv[0])
    print("")

if len(sys.argv) < 2:
    print_usage()
    sys.exit(1)

key = sys.argv[1]
totp = pyotp.TOTP(key)

info = None
if len(sys.argv) == 2:
    code = totp.now()
    ret = totp.verify(code)
    info = [code, ret]
elif len(sys.argv) == 3:
    index = int(sys.argv[2])
    code = totp.at(index)
    ret = totp.verify(code, index)
    info = [code, index, ret]
else:
    print_usage()
    sys.exit(1)

print("key: %s - %s\n" % (key, info))
sys.exit(0)
