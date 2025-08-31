# Events Section:
module GxG
  GXG_FEDERATION = {:title => "Untitled", :uuid => nil, :available => {}, :connections => {}}
  # ::GxG::SOCKET_MONITOR
  module Messages
    class ChannelManager
      #
      def update_channels
        result = false
        channels = []
        GXG_FEDERATION[:connections].values.each do |the_channel|
          channels << the_channel
        end
        channels.each do |the_channel|
          the_message = the_channel.read()
          while the_message do
            self.dispatch_message(the_message)
            the_message = the_channel.read()
          end
        end
        if channels.size > 0
          result = true
        end
        result
      end
      #
      def dispatch_message(the_message=nil)
        result = false
        if the_message.is_a?(::GxG::Events::Message)
          destination = the_message[:to]
          # uuid
          if ::GxG::valud_uuid?(destination.to_s)
            channel = self.fetch_channel(destination.to_s.to_sym)
            if channel
              channel.write(the_message)
            else
              # Send format: channel.socket.send({ :payload => the_message.export.to_s.encrypt(channel.secret).encode64 }.to_json.encode64, :text)
              socket.send({ :payload => the_message.export.to_s.encrypt(connector.secret).encode64 }.to_json.encode64, :text)
            end
            result = true
          end
          # email address -- TODO
        end
        result
      end
      #
      def fetch_channel(the_uuid)
        GXG_FEDERATION[:connections][(the_uuid)]
      end
      #
      def create_channel(the_uuid)
        GXG_FEDERATION[:connections][(the_uuid)] = ::GxG::Messages::Channel.new(the_uuid)
      end
      #
      def destroy_channel(the_uuid)
        channel = self.fetch_channel(the_uuid)
        if channel
          channel.outbox_size.times do |indexer|
            the_message = channel.read()
            if the_message
              self.dispatch_message(the_message)
            end
          end
        end
        GXG_FEDERATION[:connections].delete(the_uuid)
      end
      #
      def next_message(the_uuid)
        result = nil
        channel = self.fetch_channel(the_uuid)
        if channel
          result = channel.next_message()
        end
        result
      end
      #
      def send_message(the_uuid, the_message)
        channel = self.fetch_channel(the_uuid)
        if channel
          channel.send_message(the_message)
        end
      end
      #
      def initialize
        self
      end
      #
    end
  end
  # ###
  module Events
    #
    class Message
      def self.import(the_data=nil)
        the_message = new_message {}
        the_message.import(the_data)
        the_message
      end
      #
      def initialize(*args)
        # MUST provide a hash with at least :sender message field set
        # {:sender => <some-object>, :body => <some-object>, :post_process => <some-proc>, :error_handler => <some-object>/<some-proc> }
        unless args[0].is_a?(::Hash)
          raise ArgumentError, "you must pass a Hash to create the message"
        end
        @data = {:sender => nil. :id => GxG::uuid_generate().to_s.to_sym, :subject => args[1], :body => nil, :on_success => nil, :on_fail => nil}.merge(args[0])
        unless @data[:sender]
          raise ArgumentError, "you must set the :sender key in the argument Hash"
        end
        self
      end
      #
      def inspect()
        @data.inspect
      end
      #
      def id()
        @data[:id]
      end
      #
      def sender()
        @data[:sender]
      end
      #
      def subject()
        @data[:subject]
      end
      #
      def body()
        @data[:body]
      end
      #
      def succeed(input=nil)
        if @data[:on_success].respond_to?(:call)
          @data[:on_success].call(input)
        end
      end
      #
      def fail(input=nil)
        if @data[:on_fail].respond_to?(:call)
          @data[:on_fail].call(input)
        end
      end
      #
      def on(event_type=nil,&block)
        if [:success, :fail].include?(event_type)
          if block.respond_to?(:call)
            case event_type
            when :success
              @data[:on_success] = block
            when :fail
              @data[:on_fail] = block
            end
          else
            raise ArgumentError, "You MUST provide a callable block."
          end
        else
          raise ArgumentError, "Unknown event type: #{event_type}"
        end
      end
      # Hash-like support methods:
      def keys()
        @data.keys()
      end
      def [](the_key)
        @data[(the_key)]
      end
      def []=(the_key, the_value)
        @data[(the_key)] = the_value
      end
      def process(&block)
        @data.process(&block)
      end
      def process!(&block)
        @data.process!(&block)
      end
      def search(&block)
        @data.search(&block)
      end
      def paths_to(*args)
        @data.paths_to(*args)
      end
      def get_at_path(*args)
        @data.get_at_path(*args)
      end
      def set_at_path(*args)
        @data.set_at_path(*args)
      end
      #
      def import(the_data=nil)
        # Requires gxg_export+JSON String or gxg_export Hash
        unless the_data.is_any?(::String, ::Hash)
          raise Exception.new("You MUST supply a JSON string or a Hash, you supplied: #{the_data.class.inspect}")
        end
        result = false
        if the_data.is_a?(::String)
          the_data = JSON.parse(the_data, {:symbolize_names => true})
        end
        if the_data.is(::Hash)
          @data.merge(::Hash::gxg_import(the_data))
          result = true
        end
        result
      end
      #
      def export()
        @data.gxg_export.to_json.to_s
      end
      def to_s()
        self.export.to_s
      end
      def to_json
        self.to_s
      end
      #
    end
    #
    class LoggerDB
      #
    end
    #
    class LogRing
      #
      def initialize()
        @uuid = ::GxG.uuid_generate().to_sym
        @busy = false
        @outlets = {}
        @messages = []
      end
      #
      def uuid()
        @uuid
      end
      #
      def keys()
        @outlets.keys()
      end
      #
      def [](the_key)
        @outlets[(the_key)]
      end
      #
      def []=(the_key,the_logger)
        if the_logger.is_any?(::Logger, ::GxG::Events::LoggerDB)
          @outlets[(the_key)] = the_logger
          the_logger
        else
          raise ArgumentError, "You must supply a Logger or GxG::Events::LoggerDB instance, you provided a #{the_logger.class}"
        end
      end
      #
      def process_messages()
        unless @busy
          @busy = true
          #
          the_message = @messages.shift
          if the_message.is_a?(::GxG::Events::Message)
            begin
              if the_message[:subject] == :notification
                if the_message[:body].is_a?(::Hash)
                  outlets = self.keys()
                  outlets.to_enum(:each).each do |the_outlet_key|
                    the_outlet = self[(the_outlet_key)]
                    if (the_message[:body][:severity] || ::Logger::UNKNOWN) >= the_outlet.level()
                      # output
                      if the_outlet.is_a?(::GxG::Events::LoggerDB)
                        # TODO: GxG::Events::LogRing : build out object-based event logging:
                      else
                        # conventional string based:
                        if (the_message[:body][:message].is_a?(::String) || the_message[:body][:message].is_a?(::Exception))
                          the_outlet.add(the_message[:body][:severity], the_message[:body][:message], the_message[:body][:progname])
                        else
                          if the_message[:body][:message].is_a?(::Hash)
                            #
                            if the_message[:body][:message][:error].is_a?(::Exception)
                              if the_message[:body][:message][:error].backtrace.is_a?(::Array)
                                if the_message[:body][:message][:parameters]
                                  the_outlet.add(the_message[:body][:severity], ("\n #{the_message[:body][:message][:error].exception.class.to_s}: " + the_message[:body][:message][:error].to_s + "\n Parameters: " + the_message[:body][:message][:parameters].inspect + "\n Trace: " + the_message[:body][:message][:error].backtrace.join("\n") + "\n"), the_message[:body][:progname])
                                else
                                  the_outlet.add(the_message[:body][:severity], ("\n #{the_message[:body][:message][:error].exception.class.to_s}: " + the_message[:body][:message][:error].to_s + "\n Trace: " + the_message[:body][:message][:error].backtrace.join("\n") + "\n"), the_message[:body][:progname])
                                end
                              else
                                if the_message[:body][:message][:parameters]
                                  the_outlet.add(the_message[:body][:severity], ("\n #{the_message[:body][:message][:error].exception.class.to_s}: " + the_message[:body][:message][:error].to_s + "\n Parameters: " + the_message[:body][:message][:parameters].inspect + "\n"), the_message[:body][:progname])
                                else
                                  the_outlet.add(the_message[:body][:severity], ("\n #{the_message[:body][:message][:error].exception.class.to_s}: " + the_message[:body][:message][:error].to_s + "\n"), the_message[:body][:progname])
                                end
                              end
                            else
                              the_outlet.add(the_message[:body][:severity], the_message[:body][:message].inspect, the_message[:body][:progname])
                            end
                          else
                            the_outlet.add(the_message[:body][:severity], the_message[:body][:message].inspect, the_message[:body][:progname])
                          end
                        end
                      end
                    end
                    #
                  end
                end
              end
            rescue Exception => the_error
              @busy = false
              # log_error({:error => the_error, :parameters => {:message => the_message}})
            end
          end
          #
          @busy = false
        end
        true
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
          # self.mailbox << ::GxG::Events::Message.new({:sender => (origin || self), :severity => severity, :message => message, :progname => progname})
          the_message = new_message({:severity => severity, :message => message, :progname => progname}, :notification)
          if origin
            the_message[:sender] = origin
          end
          while @busy == true do
            sleep 0.333
          end
          @busy = true
          @messages << the_message
          @busy = false
          true
        rescue Exception => the_error
          @busy = false
          # log_error({:error => the_error, :parameters => {:severity => severity, :message => message, :progname => progname, :block => block}})
          false
        end
      end
      #
      def unknown?()
        true
      end
      alias :trace? unknown?
      def unknown(message = nil, progname = nil, origin = nil, &block)
        self.add(::Logger::UNKNOWN, message, progname, (origin || self), &block)
      end
      alias :trace :unknown
      def fatal?()
        true
      end
      def fatal(message = nil, progname = nil, origin = nil, &block)
        self.add(::Logger::FATAL, message, progname, (origin || self), &block)
      end
      def error?()
        true
      end
      def error(message = nil, progname = nil, origin = nil, &block)
        self.add(::Logger::ERROR, message, progname, (origin || self), &block)
      end
      def warn?()
        true
      end
      alias :warning? :warn?
      def warn(message = nil, progname = nil, origin = nil, &block)
        self.add(::Logger::WARN, message, progname, (origin || self), &block)
      end
      alias :warning :warn
      def info?()
        true
      end
      def info(message = nil, progname = nil, origin = nil, &block)
        self.add(::Logger::INFO, message, progname, (origin || self), &block)
      end
      def debug?()
        true
      end
      def debug(message = nil, progname = nil, origin = nil, &block)
        self.add(::Logger::DEBUG, message, progname, (origin || self), &block)
      end
    end
    #
    class EventDispatcher
      def initialize(interval=0.333)
        super()
        @uuid = ::GxG.uuid_generate().to_sym
        @event_queues = {:root => {:events => [], :settings => {:active => true, :portion => 100.0}}}
        @running = false
        @ticking = false
        # Timer format: {:when => Time_Object.to_f, :what => event_frame, :interval => float, :id => uuid.sym}
        @timers = []
        # JavaScript main pushing timer:
        @js_interval = (interval.to_f * 1000.0).to_i
        @host_timer = nil
        # Register with global dispatcher pool:
        self
      end
      #
      def startup()
        @running = true
        unless @host_timer
          @host_timer = `setInterval(#{method(:tick).to_proc}, #{@js_interval})`
        end
        if @host_timer
          true
        else
          false
        end
      end
      #
      def shutdown()
        @running = false
        if @host_timer
          if @host_timer.is_a?(Numeric)
            `clearInterval(#{@host_timer})`
          else
            `clearInterval(#{@host_timer}._id)`
          end
        end
        self.cancel_all_timers
        @host_timer = nil
        true
      end
      #
      def tick()
        if @running
          unless @ticking
            @ticking = true
            events = []
            #
            if @timers.size > 0
              triggered = []
              current = ::Time.now.to_f
              @timers.each_with_index do |timer,indexer|
                if current >= timer[:when]
                  events << timer[:what]
                  if timer[:interval]
                    @timers[(indexer)][:when] = (current + timer[:interval].to_f)
                  else
                    triggered.unshift(indexer)
                  end
                end
              end
              triggered.each do |indexer|
                @timers.delete_at(indexer)
              end
            end
            #
            total_slots = 100
            load_size = 0
            queues = {}
            @event_queues.keys.each do |the_queue|
              if (@event_queues[(the_queue)][:settings][:active] && @event_queues[(the_queue)][:events].size > 0)
                queues[(the_queue)] = {:portion => ((@event_queues[(the_queue)][:settings][:portion].to_f / 100.0) * total_slots.to_f).to_i}
                if queues[(the_queue)][:portion] == 0
                  # Fudging a little here in case of real heavy loads and/or too many queues.
                  queues[(the_queue)][:portion] = 1
                end
                queues[(the_queue)][:size] = @event_queues[(the_queue)][:events].size
                load_size += queues[(the_queue)][:size]
              end
            end
            queues.keys.each do |the_queue|
              # TODO: devise apportioned event dispatch
              queues[(the_queue)][:portion].times do 
                op = @event_queues[(the_queue)][:events].shift
                if op.respond_to?(:call)
                  events << op
                else
                  break
                end
              end
            end
            #
            events.each do |the_event|
              if the_event
                begin
                  the_event.call()
                rescue Exception => the_error
                  #
                end
              end
            end
            #
            @ticking = false
          end
        end
      end
      #
      def inspect_timers()
        @timers
      end
      def inspect_queue(queue=:root)
        @event_queues[(queue)]
      end
      #
      def adjust_event_queue(queue=:root,settings={})
        # RESEARCH: GxG::Events::EventDispatcher.adjust_event_queue : refactor :portion of each queue algo needed.
        unless queue.to_s.to_sym == :root
          if @event_queues[(queue.to_sym)]
            # LATER: Eventually add :portion as valid setting to accept.
            [:active].each do |the_setting|
              if settings[(the_setting.to_sym)]
                new_setting = {}
                # portion adjustment algo here
                new_setting[(the_setting.to_sym)] = settings[(the_setting.to_sym)]
                #
                @event_queues[(queue.to_sym)][:settings].merge!(new_setting)
              end
            end
          else
            puts "Warning: queue #{queue.inspect} does not exist"
            # For Now: just ignore references to non-existent queues. (reconsider later)
            # raise ArgumentError, "Event Queue :#{queue} does not exist to alter"
          end
        end
      end
      #
      def create_event_queue(settings={})
        unless settings.is_a?(Hash)
          raise ArgumentError, "you must provide a Hash as a parameter set"
        end
        queue_name = settings.delete(:name).to_s.to_sym
        if queue_name.to_s.size > 0
          if @event_queues[(queue_name)]
            raise ArgumentError, "Event Queue #{queue_name.inspect} already exists"
          else
            @event_queues[(queue_name)] = {:events => [], :settings => {:active => false, :portion => 0.0}}
            # For Now: simply evenly divide the portions equally, only :root can be 100%.
            even_portion = (100.0 / @event_queues.keys.size.to_f)
            @event_queues.keys.each do |the_queue|
              @event_queues[(the_queue)][:settings][:portion] = (even_portion)
            end
            self.adjust_event_queue(queue_name, settings.merge({:active => true}))
            true
          end
        else
          raise ArgumentError, ":name must be provided for Event Queue"
        end
      end
      #
      def delete_event_queue(queue=nil)
        if queue.to_s.to_sym == :root
          false
        else
          @event_queues.delete(queue)
          # For Now: simply evenly divide the portions equally, only :root can be 100%.
          even_portion = (@event_queues.keys.size.to_f / 100.0)
          @event_queues.keys.each do |the_queue|
            @event_queues[(the_queue)][:settings][:portion] = (even_portion)
          end
          true
        end
      end
      #
      def pause_event_queue(queue=nil)
        unless queue.to_s.to_sym == :root
          self.adjust_event_queue(queue,{:active => true})
        end
      end
      #
      def unpause_event_queue(queue=nil)
        unless queue.to_s.to_sym == :root
          self.adjust_event_queue(queue,{:active => false})
        end
      end
      #
      def post_to_event_queue(queue=:root,the_event=nil)
        if the_event.respond_to?(:call)
          if @event_queues[(queue)]
            @event_queues[(queue)][:events] << the_event
          else
            # issue a warning, and post to :root queue anyways (for now). (link to logger, and output)
            @event_queues[:root][:events] << the_event
          end
        end
      end
      #
      def post_event(queue_name=:root,&block)
        unless @event_queues[(queue_name.to_sym)]
          self.create_event_queue({:name => queue_name.to_sym})
        end
        self.post_to_event_queue(queue_name.to_sym,block)
        true
      end
      #
      # Adding Timers
      def add_timer(options={},&block)
        what_time = options[:when]
        what = (options[:do] || block)
        #
        if what_time.is_a?(::Numeric)
          # ms offset
          what_time = (::Time::now.to_f + what_time.to_f)
        else
          if what_time.is_a?(::Time)
            what_time = what_time.to_f
          else
            raise ArgumentError, "you must specify a :when => millisecond (float) offset, or a Time for the timer"
          end
        end
        #
        unless what.respond_to?(:call)
          raise ArgumentError, "you must provide a :do => callable object (Proc) for the timer, or a block"
        end
        the_id = ::GxG.uuid_generate().to_sym
        @timers << {:when => what_time, :what => what, :id => the_id}
        {:timer => the_id}
      end
      #
      def add_periodic_timer(options={},&block)
        interval = options[:interval]
        what = (options[:do] || block)
        #
        what_time = ::Time::now.to_f
        if interval.is_a?(::Numeric)
          # offset
          what_time += interval.to_f
        else
          raise ArgumentError, "you must specify an :interval => Float (as you would with sleep) offset interval for the periodic timer"
        end
        #
        unless what.respond_to?(:call)
          raise ArgumentError, "you must provide a :do => callable object (Proc) for the timer, or a block"
        end
        the_id = ::GxG.uuid_generate().to_sym
        @timers << {:when => what_time, :what => what, :interval => interval.to_f, :id => the_id}
        {:timer => the_id}
      end
      #
      def cancel_timer(params={})
        the_id = params[:timer]
        result = false
        if the_id
          @timers.each_index do |indexer|
            if @timers[(indexer)][:id] == the_id
              @timers.delete_at(indexer)
              result = true
              break
            end
          end
        end
        result
      end
      #
      def cancel_all_timers()
        while @ticking == true do
          sleep 0.333
        end
        @timers = []
        true
      end
      #
    end
  end
end
# Establish Console Logger for Applications:
module GxG
  # setup LOG.
  if const_defined?(:LOG)
    remove_const(:LOG)
  end
  LOG = ::GxG::Events::LogRing.new()
end
::GxG::LOG[:default] = ::Logger.new(::Logger::WARN)
# Establish Dispatcher Service for Applications:
module GxG
  # setup DISPATCHER & LOG timer.
  if const_defined?(:DISPATCHER)
    remove_const(:DISPATCHER)
  end
  DISPATCHER = ::GxG::Events::EventDispatcher.new(0.1)
  DISPATCHER.startup
  LOG_TIMER = DISPATCHER.add_periodic_timer({:interval => 1.0}) { ::GxG::LOG.process_messages }
  def self.shutdown()
    DISPATCHER.shutdown
  end
end
#

module GxG
  CHANNELS = ::GxG::Messages::ChannelManager.new
end
class Object
  #
  def send_message(the_message)
    unless @uuid
      @uuid = ::GxG::uuid_generate.to_s.to_sym
      ::GxG::CHANNELS.create_channel(@uuid)
    end
    ::GxG::CHANNELS.send_message(@uuid, the_message)
    true
  end
  #
  def next_message()
    unless @uuid
      @uuid = ::GxG::uuid_generate.to_s.to_sym
      ::GxG::CHANNELS.create_channel(@uuid)
    end
    ::GxG::CHANNELS.next_message(@uuid)
  end
  #
  def post(the_message)
    unless @uuid
      @uuid = ::GxG::uuid_generate.to_s.to_sym
      ::GxG::CHANNELS.create_channel(@uuid)
    end
    channel = ::GxG::CHANNELS.fetch_channel(@uuid)
    if channel 
      channel.write(the_message)
    end
    true
  end