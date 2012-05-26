
class ClientManager
	attr_accessor :clients

	def self.create_client(sock)
		puts "Creating client #{sock}"
		@clients ||= {}
		@clients[sock.to_i] = Client.new sock
		return
	end
	
	# Static Alias for findbyname
	def self.find(name)
		return find_by_name(name)
	end

	def self.find_by_name(name)
		@clients.each_value do |client|
			next unless client
			return client if (client.name == name)
		end
		return nil
	end

	def self.find_by_socket(socket)
		if @clients
			return @clients[socket.to_i]
		end
		return nil
	end

	def self.all(&block)
		@clients.each_value do |cli| 
			next unless cli
			block.call cli 
		end
	end

	def index_of(socket)
		@clients.each do |key, cli|
			return cli if cli.socket == socket
		end
		return nil
	end

	def self.destroy_client(socket)
		sd = socket.to_i
		if (sd <= 0)
			sd = index_of(socket)
		end
		@clients[sd].close
		@clients.delete[sd] = nil
	end
	
	def self.raw_all(line)
		@clients.each_value do |client|
			next unless client
			client.send(line)
		end
	end

end