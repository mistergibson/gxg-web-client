# frozen_string_literal: false
require 'deps/rexml/parseexception'
module REXML
  class UndefinedNamespaceException < ParseException
    def initialize( prefix, source, parser )
      super( "Undefined prefix #{prefix} found" )
    end
  end
end
