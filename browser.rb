require 'socket'
require 'json'

hostname = 'localhost'
port = 3000
path = "/index.html"

# Ask user for post type
puts "Please type 'post' to create a new viking, or type 'get' to get a webpage:"
request_type = gets.chomp.upcase

until request_type == "POST" ||  request_type == "GET"
    puts "Please choose either 'get' or 'post'"
    request_type = gets.chomp.upcase
end

def create_viking(name, email)
    {viking: { name: name, email: email} }
end

# Create viking and set post request json of Viking data
if request_type == "POST"
    puts "Alright you chose POST!"
    puts "Let's make a viking!"
    puts "What would you like to name your viking?"
    name = gets.chomp
    puts "What is the viking's email address?"
    email = gets.chomp
    puts "Thank you, we are now doing some Nordic magic to create "
    puts "your new viking, #{name}, with the email: #{email}"
    puts
    puts "Here is your response:"
    puts
    path = "/thanks.html"
    viking_json = create_viking(name, email).to_json

    request = "POST /thanks.html HTTP/1.1\r\n" +
                    "Content-Type: application/json\r\n" +
                    "Content-Length: #{viking_json.size}\r\n" +
                    "\r\n" +
                    viking_json

elsif  request_type == "GET"
    request = "GET #{path} HTTP/1.1\r\n\r\n"
end

socket = TCPSocket.open(hostname, port)

socket.print(request)

response = socket.read
headers, body = response.split("\r\n\r\n", 2)
print headers
print body