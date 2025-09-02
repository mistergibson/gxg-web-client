# GxG for Opal
# Place Holders:
module GxG
  LOG = nil
  DISPATCHER = nil
  OBJECT_SPACE = {:registry => {}}
end
$object_space = {:registry => {}}
# Alterations to basic Object
class Object
  private
  #
  def bytes(*args)
    GxG::ByteArray::try_convert(args)
  end
  #
  def new_message(*args)
    unless @uuid
      @uuid = ::GxG::uuid_generate.to_s.to_sym
      ::GxG::CHANNELS.create_channel(@uuid)
    end
    ::GxG::Events::Message.new({:sender => @uuid, :subject => args[1], :body => args[0]})
  end
  # logging hooks
  def log_unknown(message = nil, progname = nil, &block)
    # a.k.a 'unknown'
    if ::GxG::LOG
      ::GxG::LOG.unknown(message, progname, self, &block)
    end
  end
  alias :log_trace :log_unknown
  def log_fatal(message = nil, progname = nil, &block)
    if ::GxG::LOG
      ::GxG::LOG.fatal(message, progname, self, &block)
    end
  end
  def log_error(message = nil, progname = nil, &block)
    if ::GxG::LOG
      ::GxG::LOG.error(message, progname, self, &block)
    end
  end
  def log_warn(message = nil, progname = nil, &block)
    if ::GxG::LOG
      ::GxG::LOG.warn(message, progname, self, &block)
    end
  end
  alias :log_warning :log_warn
  def log_info(message = nil, progname = nil, &block)
    if ::GxG::LOG
      ::GxG::LOG.info(message, progname, self, &block)
    end
  end
  def log_debug(message = nil, progname = nil, &block)
    if ::GxG::LOG
      ::GxG::LOG.debug(message, progname, self, &block)
    end
  end
  #
  def post_event(queue_name=:root,dispatcher=nil,&block)
    result = false
    if dispatcher.is_a?(::GxG::Events::EventDispatcher)
      result = dispatcher.post_event(queue_name,&block)
    else
      if ::GxG::DISPATCHER
        result = ::GxG::DISPATCHER.post_event(queue_name,&block)
      else
        log_error("No Event Dispatcher Defined")
      end
    end
    result
  end
  #
  def post_event_at(at_time=Time.now,dispatcher=nil,&block)
    result = nil
    if dispatcher.is_a?(::GxG::Events::EventDispatcher)
      result = dispatcher.add_timer({:when => at_time},&block)
    else
      if ::GxG::DISPATCHER
        result = ::GxG::DISPATCHER.add_timer({:when => at_time},&block)
      else
        log_error("No Event Dispatcher Defined")
      end
    end
    result
  end
  #
  def post_event_periodic(interval=0.333,dispatcher=nil,&block)
    result = nil
    if dispatcher.is_a?(::GxG::Events::EventDispatcher)
      result = dispatcher.add_periodic_timer({:interval => interval},&block)
    else
      if ::GxG::DISPATCHER
        result = ::GxG::DISPATCHER.add_periodic_timer({:interval => interval},&block)
      else
        log_error("No Event Dispatcher Defined")
      end
    end
    result
  end
  #
  def cancel_periodic(reference=nil,dispatcher=nil)
    result = false
    if reference.is_a?(Hash)
      if dispatcher.is_a?(::GxG::Events::EventDispatcher)
        result = dispatcher.cancel_timer(reference)
      else
        if ::GxG::DISPATCHER
          result = ::GxG::DISPATCHER.cancel_timer(reference)
        else
          log_error("No Event Dispatcher Defined")
        end
      end
    end
    result
  end
  #
  public
  def is_any?(*args)
    result = false
    args.flatten.to_enum.each do |thing|
      if thing.class == Class
        if self.is_a?(thing)
          result = true
          break
        end
      end
    end
    result
  end
  #
  def defederate()
    if @uuid
      the_channel = ::GxG::CHANNELS.fetch_channel(@uuid)
      if the_channel
        ::GxG::CHANNELS.destroy_channel(@uuid)
      end
    end
    true
  end
  #
end
#
module GxG
  # Generic toolbox of methods
  def self.uuid_generate()
    SecureRandom.uuid()
  end
  #
  def self.passes_needed(size_used=0, container_limit=0)
    if size_used > 0 and container_limit > 0
      needed_raw = size_used.to_f / container_limit.to_f
      overhang = needed_raw - needed_raw.to_i.to_f
      needed_raw = needed_raw.to_i.to_f
      if overhang > 0.0
        needed_raw += 1.0
      end
      needed_raw.to_i
    else
      0
    end
  end
  #
  def self.apportioned_ranges(how_much_data=0, container_limit=0, original_offset=0)
    result = []
    the_count = ::GxG::passes_needed(how_much_data, container_limit)
    if the_count > 0
      offset = original_offset
      the_count.times do
        if (offset + (container_limit - 1)) <= (how_much_data - 1)
          end_point = (offset + (container_limit - 1))
        else
          end_point = (how_much_data - 1)
        end
        result << ((offset)..(end_point))
        offset = (end_point + 1)
      end
    end
    result
  end
  #
  def self.valid_uuid?(uuid=nil,strict=true)
    if uuid.is_any?(::String, ::Symbol)
      if strict == true
        pattern = /[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[4][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/
      else
        pattern = /[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/
      end
      if uuid.to_s.match(pattern)
        if uuid.to_s.size == 36
          true
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end
  #
  def self.replace_registry(new_registry={})
    $object_space[:registry] = new_registry
    true
  end
  #
  def self.register(something=nil, parent=nil)
    unless $object_space[:registry][(something.uuid.to_s.to_sym)]
      if parent
        ordinal = GxG::children_of(parent).size
      else
        ordinal = 0
      end
      $object_space[:registry][(something.uuid.to_s.to_sym)] = {:object => something, :parent => parent, :ordinal => ordinal}
    end
    true
  end
  #
  def self.unregister(the_uuid=nil)
    if $object_space[:registry][(the_uuid.to_s.to_sym)] && GxG::DISPLAY_DETAILS[:object].uuid.to_s.to_sym != the_uuid.to_s.to_sym
      $object_space[:registry].delete(the_uuid.to_s.to_sym)
    end
    true
  end
  #
  def self.register_uuid_list()
    $object_space[:registry].keys
  end
  #
  def self.record_by_uuid(the_uuid=nil)
    result = nil
    if $object_space[:registry][(the_uuid.to_s.to_sym)]
      result = $object_space[:registry][(the_uuid.to_s.to_sym)]
    end
    result
  end
  #
  def self.object_by_uuid(the_uuid=nil)
    (GxG::record_by_uuid(the_uuid) || {})[:object]
  end
  #
  def self.children_of(something=nil)
    result = []
    buffer = []
    $object_space[:registry].values.each do |entry|
      if entry[:parent].object_id == something.object_id
        buffer << entry
      end
    end
    buffer = buffer.sort { |record_a,record_b| record_a[:ordinal] <=> record_b[:ordinal] }
    buffer.each do |the_record|
      result << the_record[:object]
    end
    result
  end
  #
  def self.set_ordinal(the_selector=nil,the_ordinal=0)
    result = false
    if the_selector.is_any?(String, Symbol)
      the_object = GxG::object_by_uuid(the_selector.to_sym)
    else
      the_object = the_selector
    end
    parent = GxG::parent_of(the_object)
    if parent
      list = GxG::children_of(parent)
      current = list.find_index(the_object)
      if current
        if the_ordinal >= (list.size - 1)
          list << list.delete_at(current)
        else
          if the_ordinal < 0
            list = list.unshift(list.delete_at(current))
          else
            list = list.insert(the_ordinal,list.delete_at(current))
          end
        end
        #
        list.each_with_index do |an_object, indexer|
          record = GxG::record_by_uuid(an_object.uuid.to_sym)
          record[:ordinal] = indexer
        end
        result = true
      end
    end
    result
  end
  #
  def self.parent_of(something=nil)
    result = nil
    $object_space[:registry].values.each do |entry|
      if entry[:object].object_id == something.object_id
        result = entry[:parent]
        break
      end
    end
    result
  end
  #
  def self.lineage_of(something=nil)
    result = []
    the_parent = GxG::parent_of(something)
    until the_parent == nil do
      result.unshift(the_parent)
      the_parent = GxG::parent_of(the_parent)
    end
    # first = base progenitor.
    result
  end
  #
end
#