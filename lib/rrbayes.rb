require 'redis'
Dir.glob(File.join(File.dirname(__FILE__), "rrbayes", "*.rb")).each { |file| require file }
