module Nexus 
	class Core
		
		attr_accessor :start, :time, :debug, :me
		attr_accessor :config, :userconfig

		def self.init(args)
			@state = STATE_STARTUP
			@userconfig = YAML::load(File.open("#{CONFIG_PATH}config.yml"))
			auth = @userconfig["auth"]

			puts "Retreiving configuration:"
			puts "         URL: #{auth["url"]}"
			puts "         Key: #{auth["key"]}"
			json_result = JSON.parse(
				Curl::Easy.perform("#{auth["url"]}#{auth["path"]}#{auth["key"]}").body_str
			)
			if json_result["status"] != 1
				puts "This node is currently disabled"
				exit 1
			end

		  @config = YAML::load(json_result["config"].gsub("\\r\\n", "\n"))
			puts "Configuration:" 
			puts " Server Name: #{@config["server"]["name"]}"
			puts "       Vhost: #{@config["server"]["vhost"]}"
			puts "Database: "
			puts "     Adapter: #{@config["database"]["adapter"]}"
			puts "    hostname: #{@config["database"]["hostname"]}"

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

			@me = ClientManager.create_client(0)
			@me.name = @config["server"]["name"]
			@me.host = @config["server"]["vhost"]
			@me.link = nil

			EventEngine::TimedEvent.add_event({
				:class   => Nexus::Core,
				:handler => :garbage_run 
			})
		end

		def self.me
			return @me
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
