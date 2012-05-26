EVENT_CONT = 0
EVENT_STOP = 1

module EventEngine

	class Command
		attr_accessor :controllers
		def self.add_command(command, klass)
			cmd = command.downcase

			#Init if not already set
			@controllers ||= {}
			@controllers[cmd] ||= []
			
			@controllers[cmd] << klass
		end
		def self.dispatch(client, command, args)
			cmd = command.downcase
			if @controllers[cmd]
				@controllers[cmd].each do |ctrl|
					if ctrl.respond_to?(cmd)
						ctrl.send(cmd, client, args)
					end 
				end
			end
		end
		def self.del_controller

		end
	end

	class TimedEvent 
		attr_accessor :events 

		def self.add_event(options)
			@events ||= []
			@events << options
		end

		# XXX- Refactor this becuase its very C-ish
		def self.dispatch(time)
			@events.each do |event|
				event[:lastrun] ||= time
				timeout = event[:timeout]? event[:timeout] : 900
				if (event[:lastrun] + timeout) >= time || !event[:class]
					next
				elsif !event[:class].respond_to?(event[:handler])
					next
				else
					case event[:class].send(event[:handler])
					when EVENT_STOP
						NEXUS_LOGGER.error "TimedEvent chain has been halted by EVENT_STOP"
						NEXUS_LOGGER.error "When handling function #{event[:class].class}.#{event[:handler]}"
						return
					else
						event[:lastrun] = time
					end
				end
			end
		end
	end
end
