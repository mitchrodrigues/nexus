module Nexus 
	class Core
		
		attr_accessor :start, :time, :debug, :me
		attr_accessor :config, :userconfig

		def self.init(args)
			@state = STATE_STARTUP
			@userconfig = YAML::load(File.open("#{CONFIG_PATH}config.yml"))
		
			if !get_config
				puts "Unable to retrieve runtime configs."
				exit 1
			end

			# puts "Configuration:"
			# puts " "
			# puts " Server:" 
			# puts "        Name: #{@config["server"]["name"]}"
			# puts "       Vhost: #{@config["server"]["vhost"]}"
			# puts " Database: "
			# puts "     Adapter: #{@config["database"]["adapter"]}"
			# puts "    hostname: #{@config["database"]["hostname"]}"
			# puts " "
			NEXUS_LOGGER.info "@config: #{@config.inspect}"

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
			EventEngine::TimedEvent.add_event({
				:class   => Nexus::Core,
				:handler => :get_config 
			})
		end

		def self.get_config
      auth = @userconfig["auth"]
			NEXUS_LOGGER.info "Retrieving configuration values"
			NEXUS_LOGGER.info "URL: #{auth['url']}#{auth['key']}"
			
			# puts "Retrieving configuration:"
			# puts "         URL: #{auth["url"]}"
			# puts "         Key: #{auth["key"]}"
			begin 
				json_result = JSON.parse(
					Curl::Easy.perform("#{auth["url"]}#{auth["path"]}#{auth["key"]}").body_str
				)
			rescue
				return false
			end

			if json_result["status"] != 1
				puts "This node is currently disabled"
				exit 1
			end
			
		  @config = YAML::load(json_result["config"].gsub("\\r\\n", "\n"))
			return true
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
			puts @config["listeners"].inspect
			@config["listeners"].each_value do |listener|
				puts listener.inspect
				SocketEngine.create_listener(
						listener["host"], listener["port"]
				)
			end
			@state = STATE_RUNNING
			begin
				while @state != STATE_SHUTDOWN			
					@time = Time.now # Adjust server time.
					EventEngine::TimedEvent.dispatch(@time)
					SocketEngine.loop_once
				end
			rescue => e
				NEXUS_LOGGER.error "Shutting down on error."
				NEXUS_LOGGER.error "Message: #{e.message}"
				NEXUS_LOGGER.error e.backtrace	
			ensure
				shutdown
			end
		end
	end
end
