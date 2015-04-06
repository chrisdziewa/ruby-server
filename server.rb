require 'socket'
require 'uri'

WEB_ROOT = "./public"

host = "localhost"
port = 3000

CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

def requested_file(request_line)
  request_uri  = request_line.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)

  clean = []

  # Split the path into components
  parts = path.split("/")

  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."),
    # remove the last clean component.
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end

  # return the web root joined to the clean path
  File.join(WEB_ROOT, *clean)
end


# Parses the extension of the requested file
def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

DEFAULT_CONTENT_TYPE = 'application/octet-stream'

puts "Server listening on port 3000"
server = TCPServer.open(port)

loop do
    client = server.accept

    request_line = client.gets
    request_parts = request_line.split(" ")
    request_type = request_parts[0]
    original_path  = request_parts[1]

    path = requested_file(request_line)

    path = File.join(path, "index.html") if File.directory?(path)

    if File.exist?(path) && !File.directory?(path)
      # Gather contents for response body from requested file
      contents = File.open(path, "rb").read
      client.print "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: text/html\r\n" +
                      "Content-Length: #{contents.length}\r\n" +
                      "Connection: close\r\n"

      client.print "\r\n"

      client.print contents
    else
      message = "The requested file was not found on our server."
      client.print "HTTP/1.1 404 Not Found\r\n" +
                      "Content-Type: plain/text\r\n" +
                      "Content-Length: #{message.length}\r\n" +
                      "Connection: close\r\n"

      client.print "\r\n"

      client.print message
    end

    client.close
end