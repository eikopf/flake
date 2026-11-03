import json
import socket
import sys


def response(stream):
    while line := stream.readline():
        message = json.loads(line)
        if "error" in message:
            raise RuntimeError(message["error"])
        if "return" in message:
            return
    raise RuntimeError("QMP connection closed before command completed")


with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
    connection.settimeout(5)
    connection.connect(sys.argv[1])
    with connection.makefile("rwb") as stream:
        greeting = json.loads(stream.readline())
        if "QMP" not in greeting:
            raise RuntimeError("Missing QMP greeting")
        for command in ("qmp_capabilities", "system_powerdown"):
            stream.write(json.dumps({"execute": command}).encode() + b"\n")
            stream.flush()
            response(stream)
