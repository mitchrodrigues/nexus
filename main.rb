#!/usr/bin/ruby
PATH = Dir.pwd

# Set up gems listed in the Gemfile.

require "#{PATH}/include/standard_inc"

print "
 NEXUS CLUSTER SERVER 
Omega Development Team

Developers: Twitch
Version: #{VERSION_STRING_DOTTED}
Process Id: 

"


require_from_dir(SRC_DIR)

##
# Server in 4 lines
##

NEXUS_LOGGER = Logger.new(Nexus::Core.debug ? STDOUT : LOG_PATH + "/nexus.log")
Nexus::Core.init(ARGV)
Nexus::Core.run
Nexus::Core.shutdown

####

