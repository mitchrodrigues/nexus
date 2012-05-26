module Nexus 
	class Core
		attr_accessor :state, :config 
		attr_accessor :start, :time, :debug

		def self.init(args)
			@state = STATE_STARTUP
			
			# Open database connection using activerecord
			ActiveRecord::Base.establish_connection(
				YAML::load(File.open("#{CONFIG_PATH}database.yml")
			))

			Signal.trap('TERM') {  @state = STATE_SHUTDOWN } 
			Signal.trap('INT')  {  @state = STATE_SHUTDOWN } 
			Signal.trap('QUIT') {  @state = STATE_SHUTDOWN }

			#@config = YAML::load(File.open("#{CONFIG_PATH}config.yml"))
			@time = @age = Time.now
			
			@debug = false

			# Parse command line arguments
			args.each do |argument|
				case argument
				when "debug"
					@debug = true
				end
			end

			EventEngine::TimedEvent.add_event({
				:class   => Nexus::Core,
				:handler => :garbage_run 
			})

		end

		def self.garbage_run

		end

		def self.debug 
			return @debug
		end

		def self.shutdown 
			SocketEngine.shutdown
		end

		def self.run
			SocketEngine.init
			SocketEngine.create_listener "0.0.0.0", "8000"
			@state = STATE_RUNNING
			while @state != STATE_SHUTDOWN	
				begin	
					@time = Time.now # Adjust server time.
					EventEngine::TimedEvent.dispatch(@time)
					SocketEngine.loop_once
				rescue => e
					NEXUS_LOGGER.error "Shutting down on error."
					NEXUS_LOGGER.error "Message: #{e.message}"
					puts e.backtrace
					shutdown	
					break
				end
			end
		end
	end


	class ClientManager
		attr_accessor :clients

		def self.create_client(sock)
			@clients ||= []
			@clients[sock.to_i] = Client.new sock
			puts @clients.to_json
		end

		def self.find(socket)
			return @clients[socket.to_i]
		end

		def self.all(&block)
			@clients.each do |cli| 
				block.call cli 
			end
		end

		def self.destroy_client(socket)
			sd = socket.to_i
			@clients[sd].close
			@clients.delete[sd] = nil
		end

		def self.raw_all(line)
			@clients.each do |client|
				client.send(line)
			end
		end

	end
end
