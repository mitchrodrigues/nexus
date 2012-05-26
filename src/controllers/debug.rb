class DebugCommand

	def self.showclients(client, args)
		map = {}
		ClientManager.all do |cli|
			next if cli.link.nil?
			map_index = cli.link.to_s
			map[map_index] ||= []
			map[map_index] << cli.to_s
		end
		puts map.inspect
		map.each do |uplink, links| 
			client.send_cmd(Nexus::Core.me, ["001", client.to_s], ",----- #{uplink}")
			
			links.each do |cli|
				client.send_cmd(Nexus::Core.me,["001", client.to_s],"|- #{cli}")
			end

			client.send_cmd(Nexus::Core.me, ["001", client.to_s],  "`------")
		end
	
		return EVENT_OK
	end
end
EventEngine::Command.add("showclients", DebugCommand)