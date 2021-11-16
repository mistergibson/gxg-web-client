#
module GxG
  module Networking
    class Channel
      #
      def initialize(the_connector=nil, settings={})
        unless the_connector.is_a?(GxG::Networking::Connector)
          raise ArgumentError, "You MUST provide a GxG::Networking::Connector to associate with."
        end
        @connector = the_connector
        @uuid = (settings[:uuid] || GxG::uuid_generate().to_sym)
        @remote_uuid = settings[:remote_uuid]
        @remote_interface = []
        @mounted_object = nil
        @pending = {}
        # messages from server
        @buffer = []
        # messages from objects
        @inbox = []
        # deferred messages to send (to object or server) ???
        @outbox = []
        #
        @timer = post_event_periodic(0.333) do
          self.process_messages
        end
        # 
        post_event(:communications) do
          gxg_message = new_message
          gxg_message[:sender] = @uuid
          gxg_message[:to] = @remote_uuid
          gxg_message[:body] = {:operation => "fetch_interface"}
          @connector.transmit(gxg_message)
        end
        #
        self
      end
      #
      def closed?()
        if @timer.is_a?(Hash)
          false
        else
          true
        end
      end
      #
      def close()
        result = false
        if @timer.is_a?(Hash)
          cancel_periodic(@timer)
          @timer = nil
        end
        # send out close_channel operation to partner on server, set result = true
        result
      end
      #
      def uuid()
        @uuid
      end
      #
      def remote_uuid()
        @remote_uuid
      end
      #
      def mounted()
        @mounted_object
      end
      #
      def mount(something=nil)
        @mounted_object = something
      end
      #
      def process_messages()
        # process @buffer items, add to @outbox
        server_message = @buffer.shift
        if server_message[:body].is_a?(Hash)
          # puts "Channel Processing: #{server_message.inspect}"
          # puts "Got channel message: #{server_message.inspect}"
          if server_message[:body][:operation]
            case server_message[:body][:operation]
            when "define_interface"
              if server_message[:body][:interface].is_a?(Array)
                @remote_interface = []
                server_message[:body][:interface].each do |entry|
                  @remote_interface << entry.to_s.to_sym
                end
              end
              if @mounted_object
                @mounted_object.set_remote_uuid(server_message[:body][:remote_uuid].to_s.to_sym)
              end
            when "fetch_interface"
              if @mounted_object
                method_list = []
                @mounted_object.public_methods.each do |entry|
                  method_list << entry.to_s
                end
                gxg_message = new_message
                gxg_message[:sender] = @uuid
                gxg_message[:to] = server_message[:sender]
                gxg_message[:body] = {:operation => "define_interface", :remote_uuid => @mounted_object.uuid.to_s, :interface => method_list}
                @connector.transmit(gxg_message)
              end
            when "mount_object"
              # a) by registry uuid, b) create with params, c) ?
              # GxG::OBJECT_SPACE[:registry][(the_uuid)]
              # GxG::object_by_uuid(the_uuid)
              # puts "Attempting to mount object"
              if server_message[:body][:uuid]
                @mounted_object = GxG::object_by_uuid(server_message[:body][:uuid].to_s.to_sym)
                if @mounted_object
                  if server_message[:body][:remote_uuid]
                    @mounted_object.set_remote_uuid(server_message[:body][:remote_uuid].to_s.to_sym)
                  end
                end
              end
              # ???
              if server_message[:body][:type]
                case server_message[:body][:type].to_s
                when "GxG::Gui::Display"
                  @mounted_object = nil
                  # puts "Creating Display ..."
                  if server_message[:body][:parameters]
                    if server_message[:body][:parameters].is_a?(Array)
                        @mounted_object = ::GxG::Gui::Display.new(*server_message[:body][:parameters])
                    else
                      @mounted_object = ::GxG::Gui::Display.new(server_message[:body][:parameters])
                    end
                  else
                    @mounted_object = ::GxG::Gui::Display.new()
                  end
                  # BUG - FIX - Never gets to this line of code:
                  # puts "Mounted: #{@mounted_object.inspect} with Parameters: #{server_message[:body][:parameters].inspect}"
                else
                  log_error({:error => (Exception.new("Unrecognized object type")), :parameters => {:message => server_message}})
                end
                #
              end
              #
              if @mounted_object != nil
                # 
                # puts "Object MOUNTED."
                @mounted_object.set_channel(self)
                method_list = []
                @mounted_object.public_methods.each do |entry|
                  method_list << entry.to_s
                end
                gxg_message = new_message
                gxg_message[:sender] = @uuid
                gxg_message[:to] = server_message[:sender]
                gxg_message[:body] = {:operation => "define_interface", :remote_uuid => @mounted_object.uuid.to_s, :interface => method_list}
                @connector.transmit(gxg_message)
              else
                log_error({:error => (Exception.new("Failed to mount object")), :parameters => {:mesaage => server_message}})
              end
              #
            end
          else
            # RPC message
            # Layer 3
            rpc_message = new_message
            server_message[:body].keys.each do |rpc_key|
              rpc_message[(rpc_key)] = server_message[:body][(rpc_key)]
            end
            if rpc_message[:body][:response]
              case rpc_message[:body][:response]
              when "success"
                responder = @pending.delete(rpc_message.id().to_s.to_sym)
                if responder
                  if responder[:success].respond_to?(:call)
                    responder[:success].call(rpc_message)
                  end
                end
              when "fail"
                responder = @pending.delete(rpc_message.id().to_s.to_sym)
                if responder
                  if responder[:fail].respond_to?(:call)
                    responder[:fail].call(rpc_message)
                  end
                end
              end
            else
              if @mounted_object
                # {:method => :nil, :parameters => []/{}/etc}
                if rpc_message[:body][:method]
                  if @mounted_object.public_methods.include?(rpc_message[:body][:method].to_s.to_sym)
                    begin
                      if rpc_message[:body][:parameters]
                        if rpc_message[:body][:parameters].is_a?(Array)
                          result = @mounted_object.send(rpc_message[:body][:method].to_s.to_sym, *rpc_message[:body][:parameters])
                        else
                          result = @mounted_object.send(rpc_message[:body][:method].to_s.to_sym, rpc_message[:body][:parameters])
                        end
                      else
                        result = @mounted_object.send(rpc_message[:body][:method].to_s.to_sym)
                      end
                      # result success back.
                      gxg_message = new_message
                      gxg_message[:sender] = @uuid
                      gxg_message[:to] = server_message[:sender]
                      gxg_message[:body] = {:sender => rpc_message[:to], :to => rpc_message[:sender], :id => rpc_message[:id], :subject => rpc_message[:subject], :body => {:response => "success", :result => result}}
                      @connector.transmit(gxg_message)
                      #
                    rescue Exception => the_error
                      gxg_message = new_message
                      gxg_message[:sender] = @uuid
                      gxg_message[:to] = server_message[:sender]
                      gxg_message[:body] = {:sender => rpc_message[:to], :to => rpc_message[:sender], :id => rpc_message[:id], :subject => rpc_message[:subject], :body => {:response => "fail", :error => the_error}}
                      @connector.transmit(gxg_message)
                      #
                    end
                  else
                    gxg_message = new_message
                    gxg_message[:sender] = @uuid
                    gxg_message[:to] = server_message[:sender]
                    gxg_message[:body] = {:sender => rpc_message[:to], :to => rpc_message[:sender], :id => rpc_message[:id], :subject => rpc_message[:subject], :body => {:response => "fail", :error => "remote method missing"}}
                    @connector.transmit(gxg_message)
                    #
                  end
                end
              else
                gxg_message = new_message
                gxg_message[:sender] = @uuid
                gxg_message[:to] = server_message[:sender]
                gxg_message[:body] = {:sender => rpc_message[:to], :to => rpc_message[:sender], :id => rpc_message[:id], :subject => rpc_message[:subject], :body => {:response => "fail", :error => "no mount available"}}
                @connector.transmit(gxg_message)
                #
              end
            end
            #
          end
        end
        # process next message in @inbox
      end
      #
      def in_buffer(the_message)
        @buffer << the_message
      end
      #
      def transmit(the_message)
        if the_message.is_a?(GxG::Events::Message)
          @connector.transmit(the_message)
        end
        #
      end
      #
      def remote_call(the_message)
        # Layer 3
        if @remote_interface.size > 0
          if (the_message[:success].respond_to?(:call)) || (the_message[:fail].respond_to?(:call))
            @pending[(the_message.id().to_s.to_sym)] = the_message
          end
          rpc_message = {}
          the_message.keys.each do |the_key|
            unless [:success, :fail].include?(the_key.to_sym)
              rpc_message[(the_key)] = the_message[(the_key)]
            end
          end
          gxg_message = new_message
          gxg_message[:sender] = @uuid
          gxg_message[:to] = @remote_uuid
          gxg_message[:body] = rpc_message
          @connector.transmit(gxg_message)
        else
          error_message = "No Remote Interface Loaded."
          @pending.delete(the_message.id().to_s.to_sym)
          if (the_message[:fail].respond_to?(:call))
            the_message[:fail].call({:response => "fail", :error => error_message})
          else
            raise Exception, error_message
          end
        end
      end
      #
      def remote_interface()
        @remote_interface
      end
      #
    end
    #
    class Connector
      #
      def transmit(the_message)
        # Fully qualified GxG::Events::Message with all the data needed to send it out.
        # Packet Frame Format: {:id => <uuid>, :routing => <array>, :index => <int>, :total => <int>, :subject => <string>, :payload => <Base64-JSON>}
        if @active == true
          begin
            while @out_busy == true do
              sleep 0.333
            end
            @out_busy = true
            if the_message.is_a?(Hash)
              if the_message[:operation]
                @socket << the_message.to_json.encode64
              end
            else
              unless the_message.is_a?(GxG::Events::Message)
                raise ArgumentError, "You MUST provide a valid GxG::Events::Message message object."
              end
              if the_message[:body].is_a?(String)
                if the_message[:body].base64?
                  payload = the_message[:body]
                else
                  payload = the_message[:body].encode64
                end
              else
                if the_message[:body].is_any?(Hash,Array)
                  payload = the_message[:body].to_json.encode64
                else
                  raise ArgumentError, "You MUST supply a message body that is a Hash, an Array, or a Base64 String."
                end
              end
              if the_message[:routing].is_a?(Array)
                packet = {:id => the_message[:id], :routing => the_message[:routing], :index => 0, :total => 10000, :subject => the_message[:subject], :payload => ""}
              else
                packet = {:id => the_message[:id], :routing => [(the_message[:sender]), (the_message[:to])], :index => 0, :total => 10000, :subject => the_message[:subject], :payload => ""}
              end
              overhead = packet.to_json.size
              ranges = GxG.apportioned_ranges(payload.size,(65536 - overhead))
              packet[:total] = ranges.size
              ranges.each_with_index do |the_range,indexer|
                packet[:index] = indexer
                packet[:payload] = payload[(the_range)]
                @socket << packet.to_json.encode64
              end
            end
            @out_busy = false
            true
          rescue Exception => the_error
            log_error({:error => the_error, :parameters => {:message => the_message}})
            @out_busy = false
            false
          end
        end
      end
      #
      def receive(data)
        # Data will ALWAYS be: Base64 JSON
        # Packet Frame Format: {:id => <uuid>, :routing => <array>, :index => <int>, :total => <int>, :subject => <string>, :payload => <Base64-JSON>}
        # On Mulit-Packet transfers: :id, :routing, :total, :subject are the same on each packet - only :index and :payload differ. 
        # Routing: first=sender, last=recipient; Connectors are invisible and don't have an entry in the routing table. Channels operate as Pairs.
        # :index (which packet of :total set)? 0-offset (Marshalling)
        # recipient Channel is found and sent the completed data set when all packets are in. Further processing will happen in the Channel object.
        begin
          while @in_busy == true do
            sleep 0.333
          end
          @in_busy = true
          packet = JSON.parse(data.decode64,{:symbolize_names => true})
          unless packet.is_a?(Hash)
            raise Exception, "Malformed Packet received."
          end
          # puts "Message Received: #{packet.inspect}"
          if packet[:operation]
            # Connector Operation
            case packet[:operation]
            when "introduction"
              @remote_uuid = packet[:uuid]
            when "heartbeat_query"
              self.transmit({:operation => "heartbeat_acknowledge"})
            when "create_channel"
              unless @channels[(packet[:uuid])]
                @channels[(packet[:uuid])] = GxG::Networking::Channel.new(self,{:uuid => packet[:uuid], :remote_uuid => packet[:remote_uuid]})
              end
            end
          else
            # Data packet
            unless (packet[:id] && packet[:routing] && packet[:index] && packet[:total] && packet[:payload])
              raise Exception, "Malformed Packet received."
            end
            # puts "Routing: #{packet[:routing].inspect}"
            sender = packet[:routing].first.to_sym
            recipient = packet[:routing].last.to_sym
            if packet[:total] > 1
              # Multi-part Packet Set
              unless @buffers[(recipient)].is_a?(Array)
                @buffers[(recipient)] = []
                packet[:total].times do
                  @buffers[(recipient)] << nil
                end
              end
              @buffers[(recipient)][(packet[:index])] = packet
              complete = true
              @buffers[(recipient)].each_index do |indexer|
                unless @buffers[(recipient)][(indexer)]
                  complete = false
                  break
                end
              end
              if complete == true
                buffer = ""
                @buffers[(recipient)].each_index do |indexer|
                  buffer = (buffer + @buffers[(recipient)][(indexer)][:payload])
                end
                if buffer.base64?
                  begin
                    buffer = ::JSON.parse(buffer.decode64,{:symbolize_names => true})
                  rescue Exception => the_error
                    log_error({:error => the_error, :parameters => {:payload => buffer}})
                  end
                end
                the_message = new_message
                the_message[:sender] = sender
                the_message[:to] = recipient
                the_message[:id] = packet[:id]
                the_message[:subject] = packet[:subject]
                the_message[:body] = buffer
                unless @channels[(recipient)]
                  @channels[(recipient)] = GxG::Networking::Channel.new(self,{:uuid => recipient, :remote_uuid => sender})
                end
                @channels[(recipient)].in_buffer(the_message)
                @buffers.delete(recipient)
              end
            else
              # Single Packet
              if packet[:payload].is_a?(String)
                if packet[:payload].base64?
                  begin
                    packet[:payload] = ::JSON.parse(packet[:payload].decode64,{:symbolize_names => true})
                  rescue Exception => the_error
                    log_error({:error => the_error, :parameters => {:payload => packet[:payload]}})
                  end
                end
              end
              the_message = new_message
              the_message[:sender] = sender
              the_message[:to] = recipient
              the_message[:id] = packet[:id]
              the_message[:subject] = packet[:subject]
              the_message[:body] = packet[:payload]
              unless @channels[(recipient)]
                @channels[(recipient)] = GxG::Networking::Channel.new(self,{:uuid => recipient, :remote_uuid => sender})
              end
              @channels[(recipient)].in_buffer(the_message)
            end
          end
        rescue Exception => the_error
          log_error({:error => the_error, :parameters => {:data => data}})
        end
        @in_busy = false
        true
      end
      #
      def close()
        self.transmit({:operation => "disconnect"})
        @socket.close(1000)
        @active = false
      end
      # Channel supports:
      def channels()
        @channels
      end
      #
      def initialize(the_url=nil)
        unless the_url
          raise ArgumentError, "You MUST provide a URL String to contact a host."
        end
        @uuid = GxG.uuid_generate().to_sym
        @remote_uuid = nil
        @active = false
        @in_busy = false
        @out_busy = false
        @pending = {}
        @channels = {}
        @buffers = {}
        @the_connector = self
        @socket = Browser::Socket.new(the_url) do |the_socket|
          the_socket.on :open do
            @active = true
            @the_connector.transmit({:operation => "introduction", :uuid => @uuid.to_s, :location => `window.location["href"]`})
          end
          the_socket.on :close do
            @active = false
          end
          the_socket.on :message do |the_event|
            @the_connector.receive(the_event.data)
          end
        end
        # Set trap for page closure / refresh / unload / etc
        `jQuery(window).bind("beforeunload", function() { Opal.eval("GxG::CONNECTION.close"); });`
        self
      end
    end
  end
end
