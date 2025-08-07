# Require Core Library:
# require 'opal/full'
require 'opal'
require 'opal/paths'
#
## Require Standard Library:
# require 'benchmark'
require 'bigdecimal'
require 'buffer'
require 'base64'
require 'console'
require 'date'
require 'delegate'
require 'enumerator'
# require 'erb'
require 'forwardable'
require 'iconv'
require 'json'
require 'js'
require 'observer'
require 'opal-parser'
require 'opal-platform'
# require 'ostruct'
require 'pathname'
require 'pp'
require 'promise'
require 'securerandom'
# require 'set'
require 'singleton'
require 'stringio'
require 'strscan'
# require 'template'
require 'thread'
require 'time'
# GxG Requirements:
require 'deps/chronic'
#require 'deps/rexml/document'
#require 'deps/xml-simple'
require 'web/gxg'
#require 'gxg_uri'
require 'web/gxg_augments'
# require 'gxg_datetime'
require 'web/gxg_elements'
require 'web/gxg_events'
require 'web/gxg_database'
require 'web/gxg_libraries'
require 'web/gxg_applications'
# Ferro-Alternative: Foundation Framwork
require 'web/gxg_vdom'
require 'web/gxg_foundation'
require 'web/gxg_layout'
require 'web/gxg_windows'
require 'web/gxg_gui'
require 'web/gxg_comm'
#
module GxG
    DISPLAY_DETAILS = {:server_status => :running, :logged_in => false, :host_path => "", :use_ssl => false, :socket => nil, :object => nil, :theme => "default", :query => {}, :article => nil, :mode => :browsing}
    LAYOUT = {:"top-left" => {}, :top => {}, :"top-right" => {}, :right => {}, :"bottom-right" => {}, :bottom => {}, :"bottom-left" => {}, :left => {}}
    LAYOUT_LIMITS = {:top => 0, :left => 0, :bottom => `window.innerHeight`.to_i, :right => `window.innerWidth`.to_i, :page_width => `window.innerWidth`.to_i, :page_height => `window.innerHeight`.to_i}
    APPLICATIONS = {:processes => {}, :libraries => {}, :viewports => {}, :prefetching => false}
    ANIMATION = {:animations => {}, :assets => {}}
    DB = {:formats => {}}
    CONNECTION = ::GxG::Networking::Connector.new
    SOCKET_MONITOR = ::GxG::Networking::SocketMonitor.new
    THEMES = {}
    PAGES = {}
    DOCUMENTS = {}
end
#
class Object
    private
    def page()
        ::GxG::DISPLAY_DETAILS[:object]
    end
    #
    def applications()
        ::GxG::APPLICATIONS[:processes]
    end
    #
    def libraries()
        ::GxG::APPLICATIONS[:libraries]
    end
    #
    def viewports()
        ::GxG::APPLICATIONS[:viewports]
    end
    #
    def connector()
        ::GxG::CONNECTION
    end
    #
    def socket()
        ::GxG::DISPLAY_DETAILS[:socket] 
    end
    #
    def sockets()
        ::GxG::SOCKET_MONITOR
    end
    #
    def documents()
        ::GxG::DOCUMENTS
    end
    #
end
#