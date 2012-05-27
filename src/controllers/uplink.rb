class UplinkController
	def self.server(client, args)
		return if (args.size < 2)
		
		unless args[2].nil?
			client.link = ClientManager.find_by_socket(client.socket)
		else
			client.link = ClientManager.client0 # Me
		end

		client.name = args[0]
		client.host = args[1]

		client.send_cmd(Nexus::Core.me, ["BURST", "START"])
		EventEngine::Event.dispatch("BURST", client)
		client.send_cmd(Nexus::Core.me, ["BURST", "END"])
		
		return EVENT_OK
	end

	def self.burst(args)
		EVENT_STOP
	end

	def self.usercon(args)
		args.send_cmd(Nexus::Core.me, ["WELCOME", "#{VERSION_STRING}"])
		args.send_cmd(Nexus::Core.me, 
								 ["SERVER", Nexus::Core.me.to_s, "AUTHKEY"])
		EVENT_STOP
	end

	def self.quit(client, args)
		ClientManager.all do |cli|
				if cli.link == Nexus::Core.me
					cli.send_cmd(cli, ["QUIT"], "Has disconnected")
				end
		end
		ClientManager.destroy(client)
	end
end

EventEngine::Event.add("BURST", UplinkController)
EventEngine::Event.add("USERCON", UplinkController)
EventEngine::Command.add("SERVER", UplinkController)
EventEngine::Command.add("QUIT", UplinkController)