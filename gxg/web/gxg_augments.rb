# Alteration to Opal's Buffer::Array
class Buffer
  class Array
    def native_object()
      `#@native`
    end
  end
end
# Place holders for Hash & Array modifications:
module GxG
  module Database
    class Field
      #
    end
    class PersistedArray
      #
    end
    class PersistedHash
      #
    end
  end
end
# Logger (minimal) support:
class Logger
  DEBUG = 0
  INFO = 1
  WARN = 2
  ERROR = 3
  FATAL = 4
  UNKNOWN = 5
  TRACE = 5
  #
  def initialize(loglevel=3)
    @level = loglevel
  end
  #
  def level()
    @level
  end
  #
  def level=(loglevel=3)
    @level = loglevel
  end
  #
  def add(severity = nil, message = nil, progname = nil, origin = nil, &block)
    #
    unless [::Logger::DEBUG, ::Logger::INFO, ::Logger::WARN, ::Logger::ERROR, ::Logger::FATAL, ::Logger::UNKNOWN].include?(severity)
      severity = ::Logger::UNKNOWN
    end
    if progname
      unless message
        message = progname
        progname = nil
      end
    end
    begin
      unless message
        if block.respond_to?(:call)
          message = block.call()
        end
      end
      levels = ["DEBUG", "INFO", "WARN", "ERROR", "FATAL", "ANY"]
      puts "#{levels[(severity)].to_s}, [#{Time.now.strftime('%Y-%m-%dT%H:%M:%S%z')}##{$$.inspect}] #{Time.now.to_i.to_s} -- #{progname.inspect}: #{message.to_s}\n"
      #
      true
    rescue Exception => the_error
      log_error({:error => the_error, :parameters => {:severity => severity, :message => message, :progname => progname, :block => block}})
      false
    end
  end
  #
  def debug(progname = nil, &block)
    add(DEBUG, nil, progname, &block)
  end
  #
  def info(progname = nil, &block)
    add(INFO, nil, progname, &block)
  end
  #
  def warn(progname = nil, &block)
    add(WARN, nil, progname, &block)
  end
  alias :warning :warn
  #
  def error(progname = nil, &block)
    add(ERROR, nil, progname, &block)
  end
  #
  def fatal(progname = nil, &block)
    add(FATAL, nil, progname, &block)
  end
  #
  def unknown(progname = nil, &block)
    add(UNKNOWN, nil, progname, &block)
  end
  alias :trace :unknown
  #
end
#
class Time
  def to_d()
    BigDecimal("%#{::Float::DIG}f" % self.to_f)
  end
end
#
class DateTime < Date
  # Review : totally revamp and rethink this.
  # Notes, see: https://ruby-doc.org/stdlib-2.5.0/libdoc/date/rdoc/DateTime.html#method-c-parse
  def intialize(*args)
    @data = Time.parse(*args)
    super(*args)
  end
  #
  def to_time()
    ::Time.parse(self.to_s)
  end
  #
  def to_d()
    BigDecimal(self.to_time.to_d)
  end
  #
  def self.now()
    DateTime.parse(Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'))
  end
  
	def to_s()
		self.strftime('%Y-%m-%dT%H:%M:%S%z')
	end
  
  def to_json()
    self.strftime('%Y-%m-%dT%H:%M:%S%z')
  end
  
  def strftime(fmt='%FT%T%:z')
    super(fmt)
  end

  def self._strptime(str, fmt='%FT%T%z')
    super(str, fmt)
  end

  def iso8601_timediv(n) # :nodoc:
    n = n.to_i
    strftime('T%T' +
             if n < 1
               ''
             else
               '.%0*d' % [n, (sec_fraction * 10**n).round]
             end +
             '%:z')
  end

  private :iso8601_timediv

  def iso8601(n=0)
    super() + iso8601_timediv(n)
  end

  def rfc3339(n=0) iso8601(n) end

  def xmlschema(n=0) iso8601(n) end # :nodoc:

  def jisx0301(n=0)
    super() + iso8601_timediv(n)
  end
end
# ######## Hassle-free Cloning support
#class NilClass
#  public
#  def initialize_clone
#    nil
#  end
#  alias :initialize_dup :initialize_clone
#  alias :dup :initialize_clone
#  def clone()
#    initialize_clone
#  end
#end
##
#class FalseClass
#  public
#  def initialize_clone
#    false
#  end
#  alias :initialize_dup :initialize_clone
#  alias :dup :initialize_clone
#  def clone()
#    initialize_clone
#  end
#end
##
#class TrueClass
#  public
#  def initialize_clone
#    true
#  end
#  alias :initialize_dup :initialize_clone
#  alias :dup :initialize_clone
#  def clone()
#    initialize_clone
#  end
#end
##
class Integer
#  public
#  def initialize_clone
#    (self | self).to_i
#  end
#  alias :initialize_dup :initialize_clone
#  alias :dup :initialize_clone
#  def clone()
#    initialize_clone
#  end
  def to_d()
    BigDecimal("%#{::Float::DIG}f" % self.to_f)
  end
end
##
class Float
  public
  def to_d()
    BigDecimal("%#{::Float::DIG}f" % self)
  end
#  def initialize_clone
#    (self + 0.0)
#  end
#  alias :initialize_dup :initialize_clone
#  alias :dup :initialize_clone
#  def clone()
#    initialize_clone
#  end
end
#
#class Symbol
#  def initialize_clone
#    (self.to_s.dup.to_sym)
#  end
#  alias :initialize_dup :initialize_clone
#  alias :dup :initialize_clone
#  def clone()
#    initialize_clone
#  end
#end
#
class String
  #
  def cast_to_ascii()
    `new window.TextDecoder("ascii").decode(new window.TextEncoder().encode(#{self.clone}.toString()))`.to_s
  end
  #
  def valid_date?()
    # Match for Date pattern
    if (/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/.match(self))
      true
    else
      false
    end
  end
  #
  def valid_datetime?()
    # Match for ISO 8601 pattern
    if (/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9][+-][0-9][0-9]:[0-9][0-9]/.match(self))
      true
    else
      false
    end
  end
  #
  def valid_datetime_nolocale?()
    # Match for not-so-much ISO 8601-ish pattern
    if (/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/.match(self))
      true
    else
      false
    end
  end
  #
  def valid_path?()
    if (/.*(?:\\|\/)(.+)$/.match(self) || (self.split(" ").size == 1 || self.split("/").size > 1 || self == "/"))
      true
    else
      false
    end
  end
  #
  def valid_jid?()
    if /^(?:([^@]*)@)??([^@\/]*)(?:\/(.*?))?$/.match(self)
      true
    else
      false
    end
  end
  #
  def camel_case?()
    # self.match(/([A-Z][a-z]+[A-Z][a-zA-Z]+)/)
    if self.match(/[A-Z]([A-Z0-9]*[a-z][a-z0-9]*[A-Z]|[a-z0-9]*[A-Z][A-Z0-9]*[a-z])[A-Za-z0-9]*/)      
      true
    else
      false
    end
  end
  #
  def split_camelcase()
    if self.camel_case?()
      self.split(/(?=[A-Z])/)
    else
      self
    end
  end
  #
  #  def write(*args)
  #    # no-op
  #  end
  #  #
  #  def mime_type()
  #    result = nil
  #    raw = ::MimeMagic.by_magic(::StringIO.new(self.cast_to_ascii(self.clone)))
  #    if raw
  #      result = {:type => (raw.type), :mediatype => (raw.mediatype), :subtype => (raw.subtype)}
  #    end
  #    result
  #  end
  #
  def json_1?()
    self.slice(0,1) == '{'
  end
  #
  def json_2?()
    (self.json_1?() && (self.match('"apiVersion"\s?:\s?"2.0"') || false))
  end
  #
  def json?()
    self.json_1?() || self.json_2?()
  end
  #
  def from_json(symbolize_names = true)
    if self.json?
      the_object = ::JSON::parse(self,{:symbolize_names => symbolize_names})
      if the_object.is_any?(::Hash, ::Array)
        the_object.process! do |value, selector, container|
          if value.is_a?(::String)
            if (value.valid_datetime? || value.valid_datetime_nolocale?)
              container[(selector)] = ::DateTime::parse(value)
            else
              item = value.numeric_values()
              if item.is_a?(::Hash)
                if item[:integer]
                  item = item[:integer]
                  container[(selector)] = item
                else
                  if item[:float]
                    item = item[:float]
                    container[(selector)] = item
                  end
                end
              end
            end
            #
            if value[0..6] == "binary:" && value[7..-1].base64?
              container[(selector)] = GxG::ByteArray.new(value[7..-1].decode64)
            end
          end
          nil
        end
        #
      end
    else
      self
    end
  end
  # Base64 Stuff:
  def base64?()
    # RFC 4648
    # SOMEDAY: use regex based detection, current is open to some bugs.
    # See: http://www.perlmonks.org/?node_id=775820
    # See: http://mattfaus.com/blog/2007/02/14/base64-regular-expression/
    # See: http://stackoverflow.com/questions/475074/regex-to-parse-or-validate-base64-data
    # Regex Testing: http://www.myregexp.com/signedJar.html
    # For now:
    begin
        # Weird: the word 'page' and 'form' are considered a base64 strings. (time to monkey patch a fix)
        if ! ["page","form", "left"].include?(self)
          # ^(?:[A-Za-z0-9+/]{4})+(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$
          # failing: ^(?:[A-Za-z0-9+\/]{4}\n?)*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$
          # ^@(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$
          # /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}[AEIMQUYcgkosw048]=|[A-Za-z0-9+\/][AQgw]==)?\z/
          # (?:[A-Za-z0-9+\/]{4}){2,}(?:[A-Za-z0-9+\/]{2}[AEIMQUYcgkosw048]=|[A-Za-z0-9+\/][AQgw]==)
          # if (self.size > 0 && /^(?:[A-Za-z0-9+\/]{4})+(?:[A-Za-z0-9+\/]{2}[AEIMQUYcgkosw048]=|[A-Za-z0-9+\/][AQgw]==)?\z/.match(self))
          if (self.size > 0)
            begin
              Base64::strict_decode64(self)
              true
            rescue Exception => the_error
              false
            end
          else
            false
          end
        else
            false
        end
    rescue Exception => the_error
      false
    end
  end
  #
  def encode64()
    # RFC 4648
    if self.base64?()
      self
    else
      ::Base64::strict_encode64(self)
    end
  end
  #
  def decode64()
    # RFC 4648
    if self.base64?()
      ::Base64::strict_decode64(self)
    else
      self
    end
  end
  #
  def encrypt(withkey="")
    #
    if withkey.to_s.size > 0
      keybytes = ::GxG::ByteArray.new(withkey.to_s)
      container = ::GxG::ByteArray.new(self.to_s)
      #
      container.each_index do |index|
        the_value = container[(index)]
        #
        keybytes.each do |the_byte|
          [127,63,31,15,7,3,1,0].each do |the_bit|
            if the_byte > the_bit
              the_value += 1
              if the_value > 255
                the_value = 0
              end
            else
              the_value -= 1
              if the_value < 0
                the_value = 255
              end
            end
          end
        end
        #
        container[(index)] = the_value
      end
      #
      result = container.to_s
      result
    else
      self.dup
    end
  end
  #
  def decrypt(withkey="")
    #
    if withkey.to_s.size > 0
      keybytes = ::GxG::ByteArray.new(withkey.to_s)
      container = ::GxG::ByteArray.new(self.to_s)
      #
      container.each_index do |index|
        the_value = container[(index)]
        #
        keybytes.each do |the_byte|
          [127,63,31,15,7,3,1,0].each do |the_bit|
            if the_byte > the_bit
              the_value -= 1
              if the_value < 0
                the_value = 255
              end
            else
              the_value += 1
              if the_value > 255
                the_value = 0
              end
            end
          end
        end
        #
        container[(index)] = the_value
      end
      #
      result = container.to_s
      result
    else
      self.dup
    end
  end
  #
  def to_d()
    BigDecimal(self)
  end
end
#
class Hash
  #
  def self.process(the_hash={},&block)
    new_hash = {}
    if block.respond_to?(:call)
      if the_hash.is_any?(::Array, ::Hash, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
        new_hash = the_hash.process!(&block)
      else
        raise ArgumentError, "you must pass a Hash or an Array, or a ByteArray"
      end
    end
    new_hash
  end
  #
  def self.search(the_hash={},&block)
    new_hash = {}
    if block.respond_to?(:call)
      if the_hash.is_any?(::Array, ::Hash, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
        new_hash = the_hash.search(&block)
      else
        raise ArgumentError, "you must pass a Hash or an Array, or a ByteArray"
      end
    end
    new_hash
  end
  #
  def iterative(&block)
    result = []
    visit = Proc.new do |the_node=nil, accumulator=[]|
      node_stack = []
      if the_node
        node_stack << ({:parent => nil, :parent_selector => nil, :object => (the_node)})
        while (node_stack.size > 0) do
          a_node = node_stack.shift
          #
          if a_node[:object].is_any?(::Hash, ::Struct, ::GxG::Database::PersistedHash)
            a_node[:object].each_pair do |the_key, the_value|
              node_stack << ({:parent => a_node[:object], :parent_selector => the_key, :object => the_value})
            end
          end
          if a_node[:object].is_any?(::Array, ::GxG::Database::PersistedArray)
            a_node[:object].each_with_index do |the_value, the_index|
              node_stack << ({:parent => a_node[:object], :parent_selector => the_index, :object => the_value})
            end
          end
          #
          accumulator << a_node
        end
      end
      accumulator
    end
    #
    children_of = Proc.new do |the_db=[], the_parent=nil|
      list = []
      the_db.each do |node|
        if node[:parent].object_id == the_parent.object_id
          list << node
        end
      end
      list
    end
    #
    begin
      database = visit.call(self,[])
      link_db = children_of.call(database, self)
      if block.respond_to?(:call)
        while (link_db.size > 0) do
          entry = link_db.shift
          unless entry[:object].object_id == self.object_id
            # calls with parameters: the_value, the_key/the_index (the_selector), the_container
            raw_result = block.call(entry[:object], entry[:parent_selector], entry[:parent])
            if raw_result
              result << raw_result
            end
          end
          if entry[:object].object_id != nil.object_id
            children = children_of.call(database, entry[:object])
            children.each do |child|
              link_db << child
            end
          end
        end
      end
      #
    rescue Exception => the_error
      log_error({:error => the_error, :parameters => {}})
    end
    #
    result
  end
  #
  def process(&block)
    result = self.clone
    result.iterative(&block)
    result
  end
  #
  def process!(&block)
    self.iterative(&block)
    self
  end
  #
  def search(&block)
    results = []
    if block.respond_to?(:call)
      results = self.iterative(&block)
    end
    results
  end
  #
  def paths_to(the_object=nil,base_path="")
    # new idea here:
    search_results = []
    unless base_path[0] == "/"
      base_path = ("/" + base_path)
    end
    if base_path.size > 1
      path_stack = base_path.split("/")[1..-1].reverse
    else
      path_stack = []
    end
    origin = self.get_at_path(base_path)
    container_stack = [{:selector => nil, :container => origin, :prefix => "/"}]
    find_container = Proc.new do |the_container|
      result = nil
      container_stack.each_with_index do |entry, index|
        if entry[:container] == the_container
          result = entry
          break
        end
      end
      result
    end
    last_container = origin
    found = false
    # tester = {:a=>1, :b=>2, :c=>[0, 5], :testing=>{:d=>4.0, :e=>0.9, :f => nil}}
    if origin.is_any?(::Hash, ::Array, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
      origin.process! do |the_value, selector, container|
        if last_container.object_id != container.object_id
          container_record = find_container.call(container)
          if container_record
            path_stack = container_record[:prefix].split("/").reverse
            if path_stack.size == 0
              path_stack << ""
            end
          end
          last_container = container
        end
        if selector.is_a?(Symbol)
          safe_key = (":" + selector.to_s)
        else
          safe_key = selector.to_s
        end
        safe_key = safe_key.gsub("/","%2f")
        path_stack.unshift(safe_key)
        # compare the_value
        found = false
        if the_value.is_a?(::GxG::Database::Field)
          if (the_value.content == the_object)
            found = true
          end
        else
          if (the_value == the_object)
            found = true
          end
        end
        if found
          search_results << ("/" + path_stack.reverse.join("/"))
        end
        #
        if the_value.is_any?(::Array, ::Hash, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
          container_stack.unshift({:selector => selector, :container => the_value, :prefix => (path_stack.reverse.join("/"))})
        end
        path_stack.shift
        #
        nil
      end
    else
      search_results << ("/" + path_stack.join("/"))
    end
    search_results
  end
  #
  def get_at_path(the_path="/")
    result = nil
    if the_path == "/"
      result = self
    else
      object_stack = [(self)]
      path_stack = the_path.split("/")
      path_stack.to_enum.each do |path_element|
        element = nil
        if path_element.size > 0
          if (path_element =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
            element = path_element.to_i
          else
            element = path_element
            element = element.gsub("%2f","/")
            if element[0] == ":"
              element = element[(1..-1)].to_sym
            end
          end
        end
        if element
          result = object_stack.first[(element)]
          if result.is_a?(NilClass)
            break
          else
            object_stack.unshift(result)
          end
        else
          # ignore double slashes? '//'
          # break
        end
      end
    end
    result
  end
  #
  def set_at_path(the_path="/",the_value=nil)
    result = nil
    if the_path != "/"
      container = self.get_at_path(::File::dirname(the_path))
      if container
        raw_selector = ::File::basename(the_path)
        selector = nil
        if raw_selector.size > 0
          if (raw_selector =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
            selector = raw_selector.to_i
          else
            selector = raw_selector
            selector = selector.gsub("%2f","/")
            if selector[0] == ":"
              selector = selector[(1..-1)].to_sym
            end
          end
        end
        if selector
          container[(selector)] = the_value
          result = container[(selector)]
        else
          # ignore double slashes? '//'
          # break
        end
        #
      end
    end
    result
  end
  #
  #
  def symbolize_keys()
    self.process! do |value, selector, container|
      if container.is_a?(::Hash)
        unless selector.is_a?(::Symbol)
          container[(selector.to_sym)] = container.delete(selector)
        end
      end
      nil
    end
    self
  end
  # 
  def gxg_export()
    result = {:type => "Hash", :content => {}}
    export_db = [{:parent => nil, :parent_selector => nil, :object => self, :record => result}]
    children_of = Proc.new do |the_parent=nil|
      list = []
      export_db.each do |node|
        if node[:parent].object_id == the_parent.object_id
          list << node
        end
      end
      list
    end
    export_record = Proc.new do |the_value|
      if the_value.is_any?(Integer, Float, String)
        if the_value.is_a?(Numeric)
          if the_value.to_s.include?(".")
            {:type => "Float", :content => the_value}
          else
            {:type => "Integer", :content => the_value}
          end
        else
          {:type => (the_value.class.to_s), :content => the_value}
        end
      else
        {:type => (the_value.class.to_s), :content => the_value.to_s}
      end
    end
    # Build up export_db:
    self.search do |the_value, the_selector, the_container|
      if the_value.is_a?(::Hash)
        export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => "Hash", :content => {}}}
      else
        if the_value.is_a?(::Array)
          export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => "Array", :content => []}}
        else
          export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => export_record.call(the_value)}
        end
      end
    end
    # Collect children export content:
    link_db =[(export_db[0])]
    while link_db.size > 0 do
      entry = link_db.shift
      children_of.call(entry[:object]).each do |the_child|
        entry[:record][:content][(the_child[:parent_selector])] = the_child[:record]
        if the_child[:object].is_any?(Hash, Array)
          link_db << the_child
        end
      end
    end
    #
    result
  end
  #
  def self.gxg_import(the_exported_record=nil)
    result = nil
    if the_exported_record.is_a?(Hash)
      if the_exported_record[:type] == "Array"
        result = ::Array::gxg_import(the_exported_record)
      else
        import_value = Proc.new do |type,value|
          if value.is_a?(String)
            begin
              the_class = eval(type)
              if the_class.respond_to?(:parse)
                value = the_class.parse(value)
              else
                if the_class.respond_to?(:new)
                  value = the_class.new(value)
                else
                  if the_class.respond_to?(:try_convert)
                    value = the_class.try_convert(value)
                  end
                end
              end
            rescue Exception => the_error
            end
          end
          value
        end
        if the_exported_record[:type] == "Hash"
          result = {}
          import_db = [{:parent => nil, :parent_selector => nil, :object => result, :record => the_exported_record}]
          while import_db.size > 0 do
            entry = import_db.shift
            if entry[:record][:content].is_a?(Hash)
              entry[:record][:content].each_pair do |selector, value|
                if value[:type] == "Hash"
                  entry[:object][(selector)] = {}
                  import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                else
                  if value[:type] == "Array"
                    entry[:object][(selector)] = []
                    import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                  else
                    entry[:object][(selector)] = import_value.call(value[:type], value[:content])
                  end
                end
              end
            else
              if entry[:record][:content].is_a?(Array)
                entry[:record][:content].each_with_index do |value, selector|
                  if value[:type] == "Hash"
                    entry[:object][(selector)] = {}
                    import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                  else
                    if value[:type] == "Array"
                      entry[:object][(selector)] = []
                      import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                    else
                      entry[:object][(selector)] = import_value.call(value[:type], value[:content])
                    end
                  end
                end
              end
            end
          end
        else
          result = import_value.call(the_exported_record[:type], the_exported_record[:content])
        end
      end
    end
    result
  end
  #
end
#
class Array
  #
  def self.process(the_array=[],&block)
    new_array = []
    if block.respond_to?(:call)
      if the_array.is_any?(::Array, ::Hash, ::GxG::ByteArray, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
        new_array = the_array.process(&block)
      else
        raise ArgumentError, "you must pass a Array, a Hash, or a ByteArray"
      end
    end
    new_array
  end
  #
  def self.search(the_array=[],&block)
    new_array = []
    if block.respond_to?(:call)
      if the_array.is_any?(::Array, ::Hash, ::GxG::ByteArray, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
        new_array = the_array.search(&block)
      else
        raise ArgumentError, "you must pass a Array, a Hash, or a ByteArray"
      end
    end
    new_array
  end
  #
  def iterative(&block)
    result = []
    visit = Proc.new do |the_node=nil, accumulator=[]|
      node_stack = []
      if the_node
        node_stack << ({:parent => nil, :parent_selector => nil, :object => (the_node)})
        while (node_stack.size > 0) do
          a_node = node_stack.shift
          #
          if a_node[:object].is_any?(::Hash, ::Struct, ::GxG::Database::PersistedHash)
            a_node[:object].each_pair do |the_key, the_value|
              node_stack << ({:parent => a_node[:object], :parent_selector => the_key, :object => the_value})
            end
          end
          if a_node[:object].is_any?(::Array, ::GxG::Database::PersistedArray)
            a_node[:object].each_with_index do |the_value, the_index|
              node_stack << ({:parent => a_node[:object], :parent_selector => the_index, :object => the_value})
            end
          end
          #
          accumulator << a_node
        end
      end
      accumulator
    end
    #
    children_of = Proc.new do |the_db=[], the_parent=nil|
      list = []
      the_db.each do |node|
        if node[:parent].object_id == the_parent.object_id
          list << node
        end
      end
      list
    end
    #
    begin
      database = visit.call(self,[])
      link_db = children_of.call(database, self)
      if block.respond_to?(:call)
        while (link_db.size > 0) do
          entry = link_db.shift
          unless entry[:object].object_id == self.object_id
            # calls with parameters: the_value, the_key/the_index (the_selector), the_container
            raw_result = block.call(entry[:object], entry[:parent_selector], entry[:parent])
            if raw_result
              result << raw_result
            end
          end
          if entry[:object].object_id != nil.object_id
            children = children_of.call(database, entry[:object])
            children.each do |child|
              link_db << child
            end
          end
        end
      end
      #
    rescue Exception => the_error
      log_error({:error => the_error, :parameters => {}})
    end
    #
    result
  end
  #
  def process(&block)
    result = self.clone
    result.iterative(&block)
    result
  end
  #
  def process!(&block)
    self.iterative(&block)
    self
  end
  #
  def search(&block)
    results = []
    if block.respond_to?(:call)
      results = self.iterative(&block)
    end
    results
  end
  #
  #
  def paths_to(the_object=nil,base_path="")
    # new idea here:
    search_results = []
    unless base_path[0] == "/"
      base_path = ("/" + base_path)
    end
    if base_path.size > 1
      path_stack = base_path.split("/")[1..-1].reverse
    else
      path_stack = []
    end
    origin = self.get_at_path(base_path)
    container_stack = [{:selector => nil, :container => origin}]
    find_container = Proc.new do |the_container|
      result = nil
      container_stack.each_with_index do |entry, index|
        if entry[:container] == the_container
          result = entry
          break
        end
      end
      result
    end
    last_container = origin
    found = false
    # tester = {:a=>1, :b=>2, :c=>[0, 5], :testing=>{:d=>4.0, :e=>0.9, :f => nil}}
    if origin.is_any?(::Hash, ::Array, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
      origin.process! do |the_value, selector, container|
        if last_container.object_id != container.object_id
          container_record = find_container.call(container)
          if container_record
            path_stack = container_record[:prefix].split("/").reverse
            if path_stack.size == 0
              path_stack << ""
            end
          end
          last_container = container
        end
        if selector.is_a?(Symbol)
          safe_key = (":" + selector.to_s)
        else
          safe_key = selector.to_s
        end
        safe_key = safe_key.gsub("/","%2f")
        path_stack.unshift(safe_key)
        # compare the_value
        found = false
        if the_value.is_a?(::GxG::Database::Field)
          if (the_value.content == the_object)
            found = true
          end
        else
          if (the_value == the_object)
            found = true
          end
        end
        if found
          search_results << ("/" + path_stack.reverse.join("/"))
        end
        #
        if the_value.is_any?(::Array, ::Hash, ::Struct, ::GxG::Database::PersistedHash, ::GxG::Database::PersistedArray)
          container_stack.unshift({:selector => selector, :container => the_value, :prefix => (path_stack.reverse.join("/"))})
        end
        path_stack.shift
        #
        nil
      end
    else
      search_results << ("/" + path_stack.join("/"))
    end
    search_results
  end
  #
  def get_at_path(the_path="/")
    # /^(?:[0-9])*[0-9](?:[0-9])*$/ = nil if an alpha present there, else 0 only numeric
    # Attribution : http://stackoverflow.com/questions/1240674/regex-match-a-string-containing-numbers-and-letters-but-not-a-string-of-just-nu
    #
    # if ":" detected do: (str.gsub("%2f","/").to_sym) as key else (str.gsub("%2f","/"))
    result = nil
    if the_path == "/"
      result = self
    else
      object_stack = [(self)]
      path_stack = the_path.split("/")
      path_stack.to_enum.each do |path_element|
        element = nil
        if path_element.size > 0
          if (path_element =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
            element = path_element.to_i
          else
            element = path_element
            element = element.gsub("%2f","/")
            if element[0] == ":"
              element = element[(1..-1)].to_sym
            end
          end
        end
        if element
          result = object_stack.first[(element)]
          if result.is_a?(NilClass)
            break
          else
            object_stack.unshift(result)
          end
        else
          # ignore double slashes? '//'
          # break
        end
      end
    end
    result
  end
  #
  def set_at_path(the_path="/",the_value=nil)
    result = nil
    if the_path != "/"
      container = self.get_at_path(::File::dirname(the_path))
      if container
        raw_selector = ::File::basename(the_path)
        selector = nil
        if raw_selector.size > 0
          if (raw_selector =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
            selector = raw_selector.to_i
          else
            selector = raw_selector
            selector = selector.gsub("%2f","/")
            if selector[0] == ":"
              selector = selector[(1..-1)].to_sym
            end
          end
        end
        if selector
          container[(selector)] = the_value
          result = container[(selector)]
        else
          # ignore double slashes? '//'
          # break
        end
        #
      end
    end
    result
  end
  #
  def gxg_export()
    result = {:type => "Array", :content => []}
    export_db = [{:parent => nil, :parent_selector => nil, :object => self, :record => result}]
    children_of = Proc.new do |the_parent=nil|
      list = []
      export_db.each do |node|
        if node[:parent].object_id == the_parent.object_id
          list << node
        end
      end
      list
    end
    export_record = Proc.new do |the_value|
      if the_value.is_any?(Integer, Float, String)
        if the_value.is_a?(Numeric)
          if the_value.to_s.include?(".")
            {:type => "Float", :content => the_value}
          else
            {:type => "Integer", :content => the_value}
          end
        else
          {:type => (the_value.class.to_s), :content => the_value}
        end
      else
        {:type => (the_value.class.to_s), :content => the_value.to_s}
      end
    end
    # Build up export_db:
    self.search do |the_value, the_selector, the_container|
      if the_value.is_a?(::Hash)
        export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => "Hash", :content => {}}}
      else
        if the_value.is_a?(::Array)
          export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => "Array", :content => []}}
        else
          export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => export_record.call(the_value)}
        end
      end
    end
    # Collect children export content:
    link_db =[(export_db[0])]
    while link_db.size > 0 do
      entry = link_db.shift
      children_of.call(entry[:object]).each do |the_child|
        entry[:record][:content][(the_child[:parent_selector])] = the_child[:record]
        if the_child[:object].is_any?(Hash, Array)
          link_db << the_child
        end
      end
    end
    #
    result
  end
  #
  def self.gxg_import(the_exported_record=nil)
    result = nil
    if the_exported_record.is_a?(Hash)
      if the_exported_record[:type] == "Hash"
        result = ::Hash::gxg_import(the_exported_record)
      else
        import_value = Proc.new do |type,value|
          if value.is_a?(String)
            begin
              the_class = eval(type)
              if the_class.respond_to?(:parse)
                value = the_class.parse(value)
              else
                if the_class.respond_to?(:new)
                  value = the_class.new(value)
                else
                  if the_class.respond_to?(:try_convert)
                    value = the_class.try_convert(value)
                  end
                end
              end
            rescue Exception => the_error
            end
          end
          value
        end
        if the_exported_record[:type] == "Array"
          result = []
          import_db = [{:parent => nil, :parent_selector => nil, :object => result, :record => the_exported_record}]
          while import_db.size > 0 do
            entry = import_db.shift
            if entry[:record][:content].is_a?(Hash)
              entry[:record][:content].each_pair do |selector, value|
                if value[:type] == "Hash"
                  entry[:object][(selector)] = {}
                  import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                else
                  if value[:type] == "Array"
                    entry[:object][(selector)] = []
                    import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                  else
                    entry[:object][(selector)] = import_value.call(value[:type], value[:content])
                  end
                end
              end
            else
              if entry[:record][:content].is_a?(Array)
                entry[:record][:content].each_with_index do |value, selector|
                  if value[:type] == "Hash"
                    entry[:object][(selector)] = {}
                    import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                  else
                    if value[:type] == "Array"
                      entry[:object][(selector)] = []
                      import_db << {:parent => entry[:object], :parent_selector => selector, :object => entry[:object][(selector)], :record => value}
                    else
                      entry[:object][(selector)] = import_value.call(value[:type], value[:content])
                    end
                  end
                end
              end
            end
          end
        else
          result = import_value.call(the_exported_record[:type], the_exported_record[:content])
        end
      end
    end
    result
  end
end
#