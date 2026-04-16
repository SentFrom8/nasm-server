import socket
import time

bytes = b""

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# s.connect(("172.232.212.171", 8080))
s.connect(("127.0.0.1", 8080))
# s.send(b"GET loremipsum%21%23%2f%2E/////////tt//2/%2Fh%2F%2F.%2e HTTP/1.1\r\n\r\n")
s.send(b"GET /mona_lisa.jpg HTTP/1.1\r\n\r\n")
for _ in range(10):
    print(s.recv(10))
    time.sleep(5)
#while (message := s.recv(100000000)):
#    bytes += message

#print(bytes)


s.close()
