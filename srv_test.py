import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# s.connect(("172.232.212.171", 8080))
s.connect(("127.0.0.1", 8080))
s.send(b"GET /mona_lisa.jpg \r\n\r\n")
print(s.recv(1000))
s.close()