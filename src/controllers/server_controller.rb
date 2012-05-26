
class ServerCommand
	def self.server(client, args)
		puts "Recieved server command from: #{client.socket.fileno}"
	end
end

EventEngine::Command.add_command("server", ServerCommand)