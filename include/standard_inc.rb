ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'rubygems'
require 'active_record'
require 'yaml'
require 'logger'
require 'socket'

require_relative 'constants'

include Socket::Constants

def require_from_dir(dir)
	Dir.foreach(dir) do |item|
		next if item == '.' or item == '..'
		if File.directory?("#{dir}#{item}")
			require_from_dir("#{dir}#{item}/")
			next
		end		
		if File.extname(item) == '.rb'
			puts "Loading: #{item}" 			
			require "#{dir}#{item}"
		end
	end
end
