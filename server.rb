require 'socket'
require 'uri'
require 'json'

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
server = TCPServer.open(host, port)

loop do
    client = server.accept

    header = ""
    while line = client.gets
      header += line
      break if line == "\r\n"
   end

   header_lines = header.split("\n")
   STDERR.puts header_lines

   request_line = header_lines[0]
   request_type = request_line.split(" ")[0]

    path = requested_file(request_line)

    path = File.join(path, "index.html") if File.directory?(path)

    if File.exist?(path) && !File.directory?(path)
      # Gather contents for response body from requested file
      if request_type == "POST"

        # Pull JSON lobject length from request header
        content_length = header_lines[2].split(" ")[1].to_i
        json_data = client.read(content_length)
        json_object = JSON.parse(json_data)

        viking = json_object["viking"]
        dynamic_content = ""
        viking.each do |key, value|
          dynamic_content += "<li>#{key.to_s}: #{value}</li>"
        end

        contents = File.open(path, "rb").read

        contents.gsub!("<%= yield %>", dynamic_content)
        client.print "HTTP/1.1 200 OK\r\n" +
                        "Content-Type: #{content_type(path)}\r\n" +
                        "Content-Length: #{contents.length}\r\n" +
                        "Connection: close\r\n"

        client.print "\r\n"

        client.print contents
      elsif request_type == "GET"
        contents = File.open(path, "rb").read
        client.print "HTTP/1.1 200 OK\r\n" +
                        "Content-Type: #{content_type(path)}\r\n" +
                        "Content-Length: #{contents.length}\r\n" +
                        "Connection: close\r\n"

        client.print "\r\n"

        client.print contents
      end
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