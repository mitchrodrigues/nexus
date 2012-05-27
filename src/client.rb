class Client

	attr_accessor :socket, :name, :host, :link
	

	def to_i 
		return @socket.to_i
	end
	
	def initialize(sock)
		if sock == nil
			@socket = rand(1024,10000)
		end
		@socket = sock
	end

	def send(message, eol = "\r\n")
		return if @socket.kind_of?(Integer)
		send_string = message		
		if message.kind_of?(Array)
			send_string = message.join(eol)
		end
		@socket << "#{send_string}#{eol}"
	end

	def send_cmd(src, tokens, suffix = nil)
		if tokens.kind_of?(Array)
			send_str = tokens.join(" ")
		else
			send_str = tokens
		end
		send_str += " :#{suffix}" if suffix
		send(":#{src.to_s} #{send_str}")
	end

	def to_s 
		return @name
	end	
	def close(message = nil)
		send(message) if message
		@socket.close
	end

end