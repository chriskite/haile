__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)

require "rubygems"
require "httparty"

require "haile/version"
require "haile/client"
require "haile/response"

module Haile
end
