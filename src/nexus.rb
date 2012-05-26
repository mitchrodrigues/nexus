module Nexus 
	class Core
		attr_accessor :state, :config 
		attr_accessor :start, :time, :debug

		def self.init(args)
			@state = STATE_STARTUP
			

			# Open database connection using activerecord

			@config = YAML::load(File.open("#{CONFIG_PATH}config.yml"))
	
			ActiveRecord::Base.establish_connection(@config["database"])
			Signal.trap('TERM') {  @state = STATE_SHUTDOWN } 
			Signal.trap('INT')  {  @state = STATE_SHUTDOWN } 
			Signal.trap('QUIT') {  @state = STATE_SHUTDOWN }

			@time = @age = Time.now
			@debug = false

			# Parse arguments
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

		def self.config 
			return @config
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
			@config["listeners"].each_value do |listener|
				SocketEngine.create_listener(
						listener["host"], listener["port"]
				)
			end
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
end
