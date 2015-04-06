require 'socket'

hostname = 'localhost'
port = 3000
path = "/index.html"

socket = TCPSocket.open(hostname, port)

request = "GET #{path} HTTP/1.1\r\n\r\n"

socket.print(request)

response = socket.read
headers, body = response.split("\r\n\r\n", 2)
print headers
print body