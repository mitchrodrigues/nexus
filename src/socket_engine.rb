
MAX_READ 	  = 48096

SOCKET_TYPE_CONNECT = 0
SOCKET_TYPE_LISTEN  = 1
SOCKET_TYPE_NORMAL  = 2

SOCKET_STATE_WRITE = 0
SOCKET_STATE_READ  = 1

SOCKET_OK   = true
SOCKET_DEAD = false


class SocketEngine 

  attr_accessor :sockets, :listeners
  def self.init
		@sockets = []
  end

  #Create a socket for listening.
  def self.create_listener(host, port) 
	begin
		NEXUS_LOGGER.info "Opening Listener: #{host}:#{port}"
		socket = Socket.new(AF_INET, SOCK_STREAM, 0)
		socket.bind( Socket.sockaddr_in(port, host))
		socket.listen(5)

		socket.set_flags(SOCKET_STATE_READ, 
						 SOCKET_TYPE_LISTEN,
						 SOCKET_OK)

	 	@sockets << socket
	rescue
		NEXUS_LOGGER.info "Unable to open socket for listen"
		NEXUS_LOGGER.error "#{$!}"
	end
  end

  def self.shutdown
	@sockets.each do |sock|
		sock.close()
		@sockets.delete sock
	end 	
  end

  def self.loop_once 	
	  read = []; write = []
	  @sockets.each do |sock|
		unless sock.is_ok?
			destroy(sock)
			next
		end
		if sock.isin_write?
			write << sock
		else
			read << sock
		end
	  end
      r,w,e = select(read, write, nil, 1) 
	  unless r.nil?   
		  r.each do |s|
			if s.is_listener?
				Thread.new(s.accept_nonblock) {|sock, addr| 
					Thread.pass
					sock.set_flags
					@sockets << sock 
					NEXUS_LOGGER.info "Accepting connection #{sock.fileno}"
					# Nexus::ClientManager.create_client sock
				}			
				next
			end
			Thread.new(s.recv(MAX_READ)) {|inbuffer|
				Thread.pass
	      	  	inbuffer.split("\r\n").each do |line| 
	      			Parser.parse_line(s, line) 
	      		end
	      	}
		  end
	  end
	  unless w.nil?
		w.each do |s|
			s.socket_state = SOCKET_STATE_READ
		end
	  end
      #Handle Errors
	  unless e.nil?
      	e.each { |s| destroy(s) }
	  end
  end

  def self.destroy(sock)
      sock.close()
      @sockets.delete sock
  end

  #Open a new socket for connecting outwards
  def self.new_socket(host, port)
    s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
     NEXUS_LOGGER.info "Connecting to: #{host}:#{port.to_s}\n"
    begin
       sockaddr_server = [
			Socket::AF_INET, 
			port, 
			Socket.gethostbyname(host)[3], 
			0, 
			0	
       	].pack("snA4NN")
       s.connect(sockaddr_server)
    rescue 
      NEXUS_LOGGER.error "error: #{$!}\n"
      return nil
    end
	s.set_flags()
    (@sockets << s)
  end
end


class Socket < BasicSocket
	attr_accessor :socket_type, :socket_state
	attr_accessor :socket_status 
	
	def set_flags(state = SOCKET_STATE_WRITE, 
			      type  = SOCKET_TYPE_NORMAL, 
			     status = SOCKET_OK)
	
		@socket_state  =  state
		@socket_type   =   type
		@socket_status = status 
	end
	
	def isin_read?
		(!isin_write?)
	end

	def isin_write?
		(@socket_state == SOCKET_STATE_WRITE)
	end

	def is_listener?
		(@socket_state == SOCKET_TYPE_LISTEN)
	end

	def is_ok?
		(@socket_state != SOCKET_DEAD)
	end

end
