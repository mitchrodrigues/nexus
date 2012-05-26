class Client

	attr_accessor :socket, :name
	
	def initialize(sock)
		puts "Initializing client: #{sock.to_i}"
		@socket = sock
		@name = ""
	end

	def send(message, eol = "\r\n")
		send_string = message		
		if message.kind_of?(Array)
			send_string = message.join("\r\n")
		end
		@socket << "#{send_string}#{eol}"
	end

	def close(message = nil)
		send(message) if message
		@socket.close
	end

end