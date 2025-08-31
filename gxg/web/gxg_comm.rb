#
#require 'gxg_uri'
#
module GxG
    module Networking
        # WebSocket Connector:
        class SocketMonitor
            #
            def initialize()
                @event_handlers = {}
                self
            end
            #
            def on(the_operation=nil, &block)
                if the_operation.is_any?(::String, ::Symbol)
                    if block.respond_to?(:call)
                        @event_handlers[(the_operation.to_s.downcase.to_sym)] = block
                    end
                end
            end
            #
            def follow_up(options={})
                operation_frame = GxG::DISPLAY_DETAILS[:socket].next_message()
                if operation_frame.is_a?(::Hash)
                    the_operation = (operation_frame.keys[0])
                    if @event_handlers[(the_operation)].respond_to?(:call)
                        @event_handlers[(the_operation)].call(operation_frame[(the_operation)])
                    end
                end
            end
            #
        end
        #
        class Socket
            #
            def inbox()
                @inbox
            end
            #
            def add_to_inbox(payload="")
                begin
                    @inbox << ::JSON.parse(payload.decode64,{:symbolize_names => true})
                rescue Exception => the_error
                    log_error({:error => the_error, :parameters => payload.decode64})
                end
            end
            #
            def error_message(the_message)
                log_error({:error => Exception.new(the_message)})
            end
            #
            def next_message()
                @inbox.shift
            end
            #
            def write(the_data="")
                # Expects: String or Hash
                if the_data.is_any?(::Hash, ::GxG::Database::DetachedHash)
                    if the_data.is_a?(::Hash)
                        # ??? Where to encrypt : encrypt(connector().secret)
                        the_data = JSON.generate(the_data).to_s.encode64
                    else
                        # Discouraged: no context of an operation this way. Not good. (deprecate?)
                        the_data = JSON.generate(the_data.export).to_s.encode64
                    end
                end
                thesocket = @socket
                if thesocket
                    `thesocket.send(the_data)`
                    true
                else
                    false
                end
            end
            #
            def close()
                thesocket = @socket
                if thesocket
                    `thesocket.close`
                    @socket = nil
                    true
                else
                    false
                end
            end
            #
            def open?()
                if @socket
                    true
                else
                    false
                end
            end
            #
            def open(the_location)
                @socket = nil
                if (`window.location['href']`).include?("https://")
                    the_url = "wss://#{the_location}"
                else
                    the_url = "ws://#{the_location}"
                end
                begin
                    # Unencrypted Preamble
                    greeting = {:attach_display => true}.to_json.encode64
                    the_socket = `new WebSocket(the_url)`
                    %x{
                        the_socket.onopen = function(e) {
                            the_socket.send(greeting);
                        };
                        the_socket.onmessage = function(event) {
                            Opal.eval("GxG::DISPLAY_DETAILS[:socket].add_to_inbox('" + event.data + "')");
                        };
                        the_socket.onclose = function(event) {
                            Opal.eval("GxG::DISPLAY_DETAILS[:socket].close");
                        };
                        the_socket.onerror = function(error) {
                            Opal.eval("GxG::DISPLAY_DETAILS[:socket].error_message('" + error.message + "')");
                        };
                    }
                    @socket = the_socket
                rescue Exception => the_error
                    log_error(:error => the_error, :parameters => {:url => the_url.to_s})
                end
                if @socket
                    ::GxG::DISPLAY_DETAILS[:socket] = self
                end
            end
            #
            def set_remote_uuid(the_uuid=nil)
                if GxG::valid_uuid?(the_uuid)
                    @remote_uuid = the_uuid.to_sym
                    true
                else
                    false
                end
            end
            #
            def initialize()
                @uuid = GxG::uuid_generate().to_sym
                @remote_uuid = nil
                @inbox = []
                self
            end
        end
    end
    # XHR Connector:
    module Networking
        class Channel
            #
        end
        #
        class Connector
            #
            def remote_uuid()
                @remote_uuid
            end
            #
            def open?()
                @active
            end
            #
            def close()
                the_message = new_message({:close => true})
                the_message[:sender] = @uuid
                the_message[:to] = @remote_uuid
                self.pull(the_message,{:synchronous => true})
                @active = false
                @csrf = nil
                if @heart_beat_timer.is_a?(::Hash)
                    GxG::DISPATCHER.cancel_timer(@heart_beat_timer)
                end
                true
            end
            #
            def post(form_data="", options={}, &handler)
                # Uses POST method, with data payload
                if @active
                    if form_data.is_a?(::GxG::Gui::Form)
                        action = form_data.get_attribute("action").to_s
                        if action.size > 0
                            if @relative_url.to_s.size > 0
                                the_url = "#{@host_prefix}#{@relative_url.to_s}#{action.to_s}?display=#{@display_path.to_s}"
                            else
                                the_url = "#{@host_prefix}#{action.to_s}?display=#{@display_path.to_s}"
                            end
                        else
                            if @relative_url.to_s.size > 0
                                the_url = "#{@host_prefix}#{@relative_url.to_s}?display=#{@display_path.to_s}"
                            else
                                the_url = "#{@host_prefix}?display=#{@display_path.to_s}"
                            end
                        end
                        the_xhr = `new XMLHttpRequest`
                        `#{the_xhr}.open('POST',#{the_url},true)`
                        `#{the_xhr}.timeout = #{(options[:timeout] || 5000)}`
                        `#{the_xhr}.setRequestHeader('X-Requested-With','XMLHttpRequest')`
                        `#{the_xhr}.setRequestHeader('Accept','application/json')`
                        `#{the_xhr}.setRequestHeader('X-CSRF-Token', #{@csrf})`
                        `#{the_xhr}.setRequestHeader('Content-Type', 'multipart/form-data')`
                        failed = Proc.new do |reason={:error => "unknown"}|
                            log_error(reason)
                        end
                        succeeded = Proc.new do
                            response_code = (`#{the_xhr}.status`).to_i
                            if response_code < 300
                                begin
                                    the_response = (::JSON.parse(`#{the_xhr}.response`,{:symbolize_names => true}))
                                    log_info(the_response.inspect)
                                    if handler.respond_to?(:call)
                                        handler.call(the_response)
                                    end
                                rescue Exception => the_error
                                    log_error({:error => the_error, :parameters => `#{the_xhr}.response`})
                                end
                            else
                                begin
                                    failed.call(::JSON.parse(`#{the_xhr}.response`,{:symbolize_names => true}))
                                rescue Exception => the_error
                                    log_error({:error => the_error, :parameters => `#{the_xhr}.response`})
                                end
                            end
                        end
                        `#{the_xhr}.addEventListener('load', #{succeeded})`
                        `#{the_xhr}.addEventListener('error', #{failed})`
                        `#{the_xhr}.addEventListener('timeout', #{failed})`
                        `#{the_xhr}.addEventListener('abort', #{failed})`
                        `#{the_xhr}.send(#{form_data.element})`
                        #
                        true
                    else
                        false
                    end
                end
                #
            end
            #
            def download_file(the_vfs_path="", error_handler=nil, &the_handler)
                if self.open?
                    if the_vfs_path.is_a?(::String) && the_handler
                        the_message = new_message({:download_file => {:path => the_vfs_path}})
                        the_message[:sender] = @uuid
                        the_message[:to] = @remote_uuid
                        if error_handler.respond_to?(:call)
                            the_message.on(:fail,&error_handler)
                        end
                        the_message.on(:success) do |response|
                            if response.is_a?(::Hash)
                                file_name = response[:result][:file_name].to_s
                                file_data = response[:result][:file_data].decode64
                                %x{
                                    const streamSaver = window.streamSaver
                                    const fileStream = streamSaver.createWriteStream(#{file_name}, {})
                                    const writer = fileStream.getWriter()
                                    const uInt8 = new TextEncoder().encode(#{file_data})
                                    writer.write(uInt8)
                                    writer.close()
                                }
                                the_handler.call(true)
                            else
                                the_handler.call(false)
                            end
                        end
                        GxG::CONNECTION.pull(the_message)
                        #
                        true
                    else
                        false
                    end
                end
            end
            #
            def push(the_message=nil, options={})
                if @active
                    # Uses PUT method, with data payload
                    if the_message.is_a?(::GxG::Events::Message)
                        if @relative_url.to_s.size > 0
                            the_url = "#{@host_prefix}#{@relative_url.to_s}?display=#{@display_path.to_s}"
                        else
                            the_url = "#{@host_prefix}?display=#{@display_path.to_s}"
                        end
                        payload = the_message.body.to_json.to_s
                        the_xhr = `new XMLHttpRequest`
                        `#{the_xhr}.open('PUT',#{the_url},true)`
                        `#{the_xhr}.timeout = #{(options[:timeout] || 5000)}`
                        `#{the_xhr}.setRequestHeader('X-Requested-With','XMLHttpRequest')`
                        `#{the_xhr}.setRequestHeader('Accept','application/json')`
                        `#{the_xhr}.setRequestHeader('X-CSRF-Token', #{@csrf})`
                        `#{the_xhr}.setRequestHeader('Content-Type', 'application/json')`
                        # unless (`navigator.userAgent`).include?("Firefox") || (`navigator.userAgent`).include?("Chrome")
                        #      `#{the_xhr}.setRequestHeader('Content-Length', #{payload.size})`
                        # end
                        failed = Proc.new do |reason=nil|
                            the_message.fail(reason)
                        end
                        succeeded = Proc.new do
                            response_code = (`#{the_xhr}.status`).to_i
                            if response_code < 300
                                begin
                                    the_message.succeed(::JSON.parse(`#{the_xhr}.response`,{:symbolize_names => true}))
                                rescue Exception => the_error
                                    log_error({:error => the_error, :parameters => `#{the_xhr}.response`})
                                end
                            else
                                failed.call(response_code)
                            end
                        end
                        `#{the_xhr}.addEventListener('load', #{succeeded})`
                        `#{the_xhr}.addEventListener('error', #{failed})`
                        `#{the_xhr}.addEventListener('timeout', #{failed})`
                        `#{the_xhr}.addEventListener('abort', #{failed})`
                        `#{the_xhr}.send(#{payload})`
                        #
                        true
                    else
                        # error?
                        false
                    end
                end
                #
            end
            #
            def pull(the_message=nil, options={:synchronous => false})
                if @active
                    # Uses GET method, with in-URL query specifiers (no data payload)
                    # @display_path
                    if the_message.is_a?(::GxG::Events::Message)
                        the_query = "display=#{@display_path.to_s}&details=#{the_message.body.to_json.encode64}"
                        if @relative_url.to_s.size > 0
                            the_url = (@host_prefix.to_s + @relative_url.to_s + "?" + the_query)
                        else
                            the_url = (@host_prefix.to_s + "?" + the_query)
                        end
                        the_xhr = `new XMLHttpRequest`
                        if options[:synchronous] == true
                            `#{the_xhr}.open('GET',#{the_url.to_s},false)`
                        else
                            `#{the_xhr}.open('GET',#{the_url.to_s},true)`
                            `#{the_xhr}.timeout = #{(options[:timeout] || 600000)}`
                        end
                        `#{the_xhr}.setRequestHeader('X-Requested-With','XMLHttpRequest')`
                        `#{the_xhr}.setRequestHeader('Accept','application/json')`
                        failed = Proc.new do |reason=nil|
                            the_message.fail(reason)
                        end
                        succeeded = Proc.new do
                            response_code = (`#{the_xhr}.status`).to_i
                            if response_code < 300
                                begin
                                    the_message.succeed(::JSON.parse(`#{the_xhr}.response`,{:symbolize_names => true}))
                                    # log_info "got data"
                                rescue Exception => the_error
                                    # log_warn "Parse Error"
                                    log_error({:error => the_error, :parameters => `#{the_xhr}.response`})
                                end
                            else
                                failed.call(response_code)
                            end
                        end
                        `#{the_xhr}.addEventListener('load', #{succeeded})`
                        `#{the_xhr}.addEventListener('error', #{failed})`
                        `#{the_xhr}.addEventListener('timeout', #{failed})`
                        `#{the_xhr}.addEventListener('abort', #{failed})`
                        `#{the_xhr}.send(null)`
                        #
                        true
                    else
                        # error?
                        false
                    end
                end
                #
            end
            #
            def push_message(the_message=nil)
                # TODO: establish a sensible routing scheme and make better use of message :sender and :to in that idea.
            end
            #
            def pull_message(options={})
                # Use to pull a message portion or look for application messages on the server.
            end
            #
            def process_pending(options={})
                #
            end
            # Support-level methods for pulling/pushing objects or object-deltas. 
            def push_object_portions(details={}, error_handler=nil, &the_handler)
                # supply thread and index to send, if successful, will post event to keep chain going.
                # Details: {:thread => "", :index => 0, :portions => 100}
            end
            # Search The Database(s)
            def search_database(details={}, error_handler=nil, &the_handler)
                # FOR NOW: limit 100 records returned at a time.
                # Use: {:limit => 100, :offset => 0} || {:page => 1}
                if details.is_a?(::Hash) && the_handler
                    self.pull_data({:search_database => {:criteria => details}},error_handler, &the_handler)
                    true
                else
                    false
                end
            end
            # Search The Database(s) & PULL a batch of records and formats
            def search_pull(details={}, error_handler=nil, &the_handler)
                # FOR NOW: limit 100 records returned at a time.
                # Use: {:limit => 100, :offset => 0} || {:page => 1}
                if details.is_a?(::Hash) && the_handler
                    self.pull_data({:search_pull => {:criteria => details}},error_handler) do |data|
                        if data.is_a?(::Hash)
                            if data[:result]
                                if data[:result].is_a?(::String)
                                    if data[:result].to_s.base64?
                                        data = data[:result].decode64
                                    end
                                    if data.to_s.json?
                                        begin
                                            data = ::JSON::parse(data.to_s,{:symbolize_names => true})
                                            the_handler.call(::GxG::Database::process_detached_import(data))
                                        rescue Exception => the_error
                                            log_error({:error => the_error, :parameters => {:data => data}})
                                        end
                                    end
                                    #
                                else
                                    # error
                                    log_error({:error => Exception.new("Malformed Response Data"), :parameters => {:data => data[:result]}})
                                end
                            else
                                if data[:error]
                                    if error_handler.respond_to?(:call)
                                        error_handler.call(data)
                                    end
                                end
                            end
                            #
                        end
                    end
                    true
                else
                    false
                end
            end
            # High-level methods for pulling/pushing objects or object-deltas.
            def destroy_object(the_specifier=nil,error_handler=nil,&the_handler)
                if the_specifier && the_handler
                    self.pull_data({:destroy_object => {:path => the_specifier}},error_handler) do |data|
                        if data.is_a?(::Hash)
                            the_handler.call(data)
                        end
                    end
                    true
                else
                    false
                end
            end
            #
            def push_data(details={}, error_handler=nil,&the_handler)
                if details.is_a?(::Hash) && the_handler
                    #
                    the_message = new_message(details)
                    the_message[:sender] = @uuid
                    the_message[:to] = @remote_uuid
                    if error_handler.respond_to?(:call)
                        the_message.on(:fail,&error_handler)
                    end
                    the_message.on(:success) do |response|
                        the_handler.call(response)
                    end
                    GxG::CONNECTION.push(the_message)
                    #
                    true
                else
                    false
                end
            end
            #
            def push_object(details={}, error_handler=nil,&the_handler)
                if details.is_a?(::Hash) && the_handler
                    # ????
                    # Details: {:path => "/path/to/object", :object => (BinaryArray/String/PersistedHash)}
                    exception = nil
                    payload = {}
                    if details[:object].is_any?(::GxG::BinaryArray, ::String)
                        # Binary payload
                        if details[:path].to_s.size > 0
                            payload[:path] = details[:path]
                            payload[:object] = details[:object].to_s.encode64
                        else
                            exception = "You MUST specify a :path to store the data into."
                        end
                    else
                        if details[:object].is_a?(::GxG::Database::DetachedHash)
                            # DB Object / VFS payload
                            if details[:path].to_s.size > 0
                                payload[:path] = details[:path]
                            end
                            payload[:uuid] = details[:object].uuid.to_s
                            # Generate Importation Records
                            format_list = []
                            importation_record = {:formats => {}, :records => []}
                            #
                            if details[:object].format.to_s.size > 0
                                format_list << details[:object].format
                            end
                            details[:object].search do |value, selector, container|
                                if value.is_a?(::GxG::Database::DetachedHash)
                                    if value.format.to_s.size > 0
                                        format_list << value.format
                                    end
                                end
                                if value.is_a?(::GxG::Database::PersistedArray)
                                    if value.constraint.to_s.size > 0
                                        format_list << value.constraint
                                    end
                                end
                            end
                            format_list.each do |the_specifier|
                                format_record = GxG::DB[:formats][(the_specifier.to_s.to_sym)].clone
                                if format_record.is_a?(::Hash)
                                    format_record[:content] = format_record[:content].gxg_export
                                    importation_record[:formats][(the_specifier.to_s.to_sym)] = format_record
                                end
                            end
                            importation_record[:records] << details[:object].export
                            #
                            payload[:object] = importation_record
                        else
                            exception = "Invalid Data Type"
                        end
                    end
                    if exception
                        if error_handler.respond_to?(:call)
                            error_handler.call({:result => nil, :error => exception})
                        end
                        false
                    else
                        self.push_data({:put_object => payload},error_handler) do |data|
                            if data.is_a?(::Hash)
                                the_handler.call(data)
                            end
                        end
                        true
                    end
                else
                    false
                end
            end
            #
            def pull_data(the_specifier={},error_handler=nil,&the_handler)
                if the_specifier && the_handler
                    # accepts entire command frame as specifier:
                    the_message = new_message(the_specifier)
                    the_message[:sender] = @uuid
                    the_message[:to] = @remote_uuid
                    if error_handler.respond_to?(:call)
                        the_message.on(:fail,&error_handler)
                    end
                    the_message.on(:success) do |response|
                        if response.is_a?(::Hash)
                            data = nil
                            if response[:result].is_a?(::String)
                                if response[:result].to_s.base64?
                                    data = response[:result].decode64
                                end
                                if data.to_s.json?
                                    begin
                                        data = ::JSON::parse(data.to_s,{:symbolize_names => true})
                                    rescue Exception => the_error
                                        log_error({:error => the_error, :parameters => {:data => data}})
                                    end
                                end
                                the_handler.call(data)
                            else
                                # error
                                log_error({:error => Exception.new("Malformed Response Data"), :parameters => {:data => response[:result]}})
                            end
                        end
                    end
                    GxG::CONNECTION.pull(the_message)
                end
            end
            #
            def pull_object(the_specifier=nil,error_handler=nil,&the_handler)
                if the_specifier && the_handler
                    # GxG::DISPLAY_DETAILS[:object].set_busy(true)
                    if GxG::valid_uuid?(the_specifier.to_s)
                        op_frame = {:get_object => {:uuid => the_specifier}}
                    else
                        op_frame = {:get_object => {:path => the_specifier}}
                    end
                    self.pull_data(op_frame,error_handler) do |data|
                        if data.is_a?(::Hash)
                            # puts "Got: #{data.inspect}"
                            the_handler.call(::GxG::Database::process_detached_import(data))
                            # xxx
                            # if data[:result]
                            #     if data[:result].is_a?(::String)
                            #         if data[:result].to_s.base64?
                            #             data = data[:result].decode64
                            #         end
                            #         if data.to_s.json?
                            #             begin
                            #                 data = ::JSON::parse(data.to_s,{:symbolize_names => true})
                            #                 the_handler.call(::GxG::Database::process_detached_import(data))
                            #             rescue Exception => the_error
                            #                 log_error({:error => the_error, :parameters => {:data => data}})
                            #             end
                            #         end
                            #         #
                            #     else
                            #         # error
                            #         log_error({:error => Exception.new("Malformed Response Data"), :parameters => {:data => data[:result]}})
                            #     end
                            # else
                            #     if data[:error]
                            #         if error_handler.respond_to?(:call)
                            #             error_handler.call(data)
                            #         end
                            #     end
                            # end
                            # GxG::DISPLAY_DETAILS[:object].set_busy(false)
                        end
                    end
                    true
                else
                    false
                end
            end
            #
            def load_format(details={}, error_handler=nil, &the_handler)
                if details && the_handler
                    self.pull_data({:get_format => details},error_handler) do |data|
                        if data.is_a?(::Hash)
                            if data[:result]
                                if data[:result].is_a?(::String)
                                    if data[:result].to_s.base64?
                                        data = data[:result].decode64
                                    end
                                    if data.to_s.json?
                                        begin
                                            data = ::JSON::parse(data.to_s,{:symbolize_names => true})
                                            ::GxG::Database::process_detached_import(data)
                                            the_handler.call({:result => true})
                                        rescue Exception => the_error
                                            log_error({:error => the_error, :parameters => {:data => data}})
                                        end
                                    end
                                    #
                                else
                                    # error
                                    log_error({:error => Exception.new("Malformed Response Data"), :parameters => {:data => data[:result]}})
                                end
                            else
                                if data[:error]
                                    if error_handler.respond_to?(:call)
                                        error_handler.call(data)
                                    end
                                end
                            end
                            #
                        end
                    end
                    true
                else
                    false
                end
            end
            #
            def store_format(details={}, error_handler=nil, &the_handler)
                if details && the_handler
                    if details.keys.size == 0
                        format_list = ::GxG::DB[:formats].keys
                    else
                        format_list = []
                        ::GxG::DB[:formats].keys.each do |the_uuid|
                            if details[:uuid].to_s.size > 0
                                if the_uuid == details[:uuid]
                                    unless format_list.include?(the_uuid)
                                        format_list << the_uuid
                                    end
                                end
                            end
                            if details[:type].to_s.size > 0
                                if ::GxG::DB[:formats][(the_uuid)][:type] == details[:type]
                                    unless format_list.include?(the_uuid)
                                        format_list << the_uuid
                                    end
                                end
                            end
                            if details[:ufs].to_s.size > 0
                                if ::GxG::DB[:formats][(the_uuid)][:ufs] == details[:ufs]
                                    unless format_list.include?(the_uuid)
                                        format_list << the_uuid
                                    end
                                end
                            end
                            if details[:title].to_s.size > 0
                                if ::GxG::DB[:formats][(the_uuid)][:title] == details[:title]
                                    unless format_list.include?(the_uuid)
                                        format_list << the_uuid
                                    end
                                end
                            end
                            if details[:version].to_s.size > 0
                                if ::GxG::DB[:formats][(the_uuid)][:version] == details[:version]
                                    unless format_list.include?(the_uuid)
                                        format_list << the_uuid
                                    end
                                end
                            end
                        end
                    end
                    importation_record = {:formats => {}, :records => []}
                    format_list.each do |the_uuid|
                        format_record = ::GxG::DB[:formats][(the_uuid.to_s.to_sym)].clone
                        format_record[:content] = format_record[:content].gxg_export
                        importation_record[:formats][(the_uuid.to_s.to_sym)] = format_record
                    end
                    self.push_data({:put_format => importation_record},error_handler) do |data|
                        if data.is_a?(::Hash)
                            the_handler.call(data)
                        end
                    end
                    true
                else
                    false
                end
            end
            #
            def get_permissions(the_specifier=nil,error_handler=nil,&the_handler)
                if the_specifier && the_handler
                    # GxG::DISPLAY_DETAILS[:object].set_busy(true)
                    self.pull_data({:get_permissions => {:path => the_specifier}},error_handler) do |data|
                        if data.is_a?(::Hash)
                            the_handler.call(data)
                            # GxG::DISPLAY_DETAILS[:object].set_busy(false)
                        end
                    end
                    true
                else
                    false
                end
            end
            # Service Call Event Support:
            def call_event(service=:core, op_frame={:interface => true}, error_handler=nil, &the_handler)
                if self.open?
                    if op_frame.is_a?(::Hash) && the_handler
                        self.pull_data({:call_event => {:service => service.to_s, :op_frame => op_frame}}, error_handler,  &the_handler)
                        true
                    else
                        false
                    end
                end
            end
            # Libarary Loading Support:
            def library_pull(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data({:get_library => details},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            # Format Support:
            def format_pull(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_any?(::Array, ::Hash) && the_handler
                        self.pull_data({:format_pull => details},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            # TODO: format_push(data={})
            def format_push(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.push_data({:format_push => details},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def format_list(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data({:format_list => details},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            # Admin:
            def admin(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data({:admin => details},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            # VFS:
            def vfs(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        if [:vfs_mkfile, :vfs_mkdir, :vfs_rename, :vfs_destroy, :vfs_copy, :vfs_move, :set_permissions].include?(details.keys[0])
                            self.pull_data(details, error_handler) do |data|
                                # Review : further decoding needed? base64??
                                the_handler.call(data)
                            end
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
            # Application Support:
            def app_state_push(details={}, error_handler=nil, &the_handler)
                if details.is_a?(::Hash) && the_handler
                    self.push_data({:app_state_push => {:application => details[:application], :data => details[:data]}},error_handler) do |data|
                        if data.is_a?(::Hash)
                            the_handler.call(data)
                        end
                    end
                    true
                else
                    false
                end
            end
            #
            def app_state_pull(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data({:app_state_pull => {:application => details[:application]}},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def application_open(details={}, error_handler=nil, &the_handler)
                # Specify either a :path or :name
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        if details[:name]
                            self.pull_data({:application_open => {:restore => (details[:restore] || false), :name => details[:name]}},error_handler) do |data|
                                the_handler.call(data)
                            end
                        else
                            # Review : remember to call using 'path' - NOT 'location' anymore:
                            self.pull_data({:application_open => {:restore => (details[:restore] || false), :path => details[:path]}},error_handler) do |data|
                                the_handler.call(data)
                            end
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def application_close(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data({:application_close => {:application => details[:application]}},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def application_list(error_handler=nil, &the_handler)
                if self.open?
                    if the_handler
                        self.pull_data({:application_list => true},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def application_menu(error_handler=nil, &the_handler)
                if self.open?
                    if the_handler
                        self.pull_data({:application_menu => true},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def entries(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        GxG::DISPLAY_DETAILS[:object].set_busy(true)
                        # Review : remember to use 'path' - NOT 'location' anymore:
                        self.pull_data({:entries => {:path => details[:path]}},error_handler) do |data|
                            the_handler.call(data)
                            GxG::DISPLAY_DETAILS[:object].set_busy(false)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            def heartbeat()
                if @active
                    heartbeat_message = new_message({:heartbeat => true})
                    heartbeat_message[:sender] = @uuid.to_s
                    heartbeat_message[:to] = @remote_uuid.to_s
                    heartbeat_message.on(:success) do |response|
                        if response.is_a?(::Hash)
                            # FIXME: possible conflict with proper credential setting.
                            if response[:result][:status] == "credentialed"
                                # GxG::DISPLAY_DETAILS[:logged_in] = true
                            else
                                # GxG::DISPLAY_DETAILS[:logged_in] = false
                            end
                            GxG::DISPLAY_DETAILS[:server_status] = response[:result][:server].to_s.to_sym
                        end
                    end
                    GxG::CONNECTION.pull(heartbeat_message)
                end
            end
            #
            # Set Credential:
            def update_credential(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        content = details.to_json.to_s.encrypt(@csrf.to_s).encode64
                        the_message = new_message({:update_credential => content})
                        the_message[:sender] = @uuid
                        the_message[:to] = @remote_uuid
                        the_message[:body][:thread] = the_message.id().to_s
                        the_message.on(:success) do |the_response|
                            if the_response.is_a?(::Hash)
                                if the_response[:status] == "credentialed"
                                    GxG::DISPLAY_DETAILS[:logged_in] = true
                                end
                            end
                            the_handler.call(the_response)
                        end
                        if error_handler
                            the_message.on(:fail) do |the_response|
                                error_handler.call(the_response)
                            end
                        end
                        GxG::CONNECTION.push(the_message)
                    end
                end
            end
            #
            def downgrade_credential(&the_handler)
                # ????
                if @active
                    downgrade_message = new_message({:downgrade_credential => true})
                    downgrade_message[:sender] = @uuid.to_s
                    downgrade_message[:to] = @remote_uuid.to_s
                    downgrade_message.on(:success) do |response|
                        # var evt = new CustomEvent('credentialchanged', { detail: "state" }); ??
                        # window.dispatchEvent(evt);
                        if response.is_a?(::Hash)
                            # FIXME: possible conflict with proper credential setting.
                            if response[:status] == "uncredentialed"
                                GxG::DISPLAY_DETAILS[:logged_in] = false
                                if the_handler.respond_to?(:call)
                                    the_handler.call(response)
                                end
                                new_event = `new CustomEvent('credentialchanged', { detail: #{response[:status].to_s} })`
                                `window.dispatchEvent(#{new_event})`
                            else
                                # GxG::DISPLAY_DETAILS[:logged_in] = true
                            end
                            # GxG::DISPLAY_DETAILS[:server_status] = response[:server].to_s.to_sym
                        end
                    end
                    GxG::CONNECTION.pull(downgrade_message)
                end
            end
            #
            def action(details={}, error_handler=nil, &the_handler)
                # ????
            end
            #
            def relative_url()
                @relative_url
            end
            #
            def query()
                @query
            end
            #
            def article()
                @article
            end
            #
            def display_path()
                @display_path
            end
            #
            def secret()
                @csrf
            end
            #
            def initialize()
                if (`window.location['href']`).include?("https://")
                    @host_prefix = ("https://" + `window.location['host']`)
                else
                    @host_prefix = ("http://" + `window.location['host']`)
                end
                @relative_url = ""
                # Find Relative URL (Note: now provided by host in introduction)
                page_name = File::basename(`window.location['pathname']`)
                subpath_array = (`window.location['pathname']`.split("/"))
                found_at = subpath_array.index(page_name)
                if found_at.is_a?(::Numeric)
                    if found_at > 1
                        @relative_url = subpath_array[(0..(found_at - 1))].join("/")
                    end
                end
                # Process Query if found
                @article = nil
                @query = {}
                query_string = `window.location.href`.split("?")[1]
                if query_string
                    @article = query_string.split("#")[1]
                    query_string = query_string.split("#")[0]
                    if query_string.include?("&amp;")
                        query_array = query_string.split("&amp;")
                    else
                        query_array = query_string.split("&")
                    end
                    query_array.each do |entry|
                        buffer = entry.split("=")
                        @query[(buffer[0].to_s.to_sym)] = buffer[1]
                    end
                else
                    @article = `window.location.href`.split("#")[1]
                end
                #
                @uuid = GxG.uuid_generate().to_sym
                @remote_uuid = nil
                @active = true
                @display_path = nil
                @in_busy = false
                @out_busy = false
                @pending = {}
                @channels = {}
                @buffers = {}
                @csrf = nil
                @the_connector = self
                # Make introduction to host and aquire csrf token
                the_introduction = new_message({:introduction => @uuid.to_s})
                the_introduction[:sender] = @uuid.to_s
                the_introduction[:to] = @host_prefix.to_s
                the_introduction.on(:success) do |response|
                    if response[:result] == "OK"
                        if response[:csrf]
                            @csrf = response[:csrf]
                        end
                        if response[:status] == "credentialed"
                            GxG::DISPLAY_DETAILS[:logged_in] = true
                        else
                            GxG::DISPLAY_DETAILS[:logged_in] = false
                        end
                        if response[:relative_url]
                            @relative_url = response[:relative_url]
                        end
                        #
                        if response[:display] == "unavailable"
                            `alert('Display Resource Unavailable')`
                        else
                            @display_path = response[:display]
                            @active = true
                            # Are we logged in at the server and recovering from a crash ??
                            GxG::DISPATCHER.post_event(:display) do
                                until (`document.readyState`.to_s == "complete") do
                                    sleep 0.5
                                end
                                ::GxG::DISPLAY_DETAILS[:query] = @query
                                ::GxG::DISPLAY_DETAILS[:article] = @article
                                %x{
                                    var do_unload = function (the_event) {
                                        Opal.GxG.$eval("GxG::DISPLAY_DETAILS[:socket].close");
                                        if (the_event) {
                                            the_event.returnValue = "closing...";
                                        }
                                        for (var i = 0; i < 500000000; i++) { }
                                        return "closing...";
                                    };
                                    window.addEventListener('unload', do_unload,false);
                                    window.addEventListener('onunload', do_unload,false);
                                    window.addEventListener('beforeunload', do_unload,false);
                                    window.addEventListener('onbeforeunload', do_unload,false);
                                    window.onbeforeunload = do_unload;
                                    window.beforeunload = do_unload;
                                }
                                # `window.addEventListener('unload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                                # `window.addEventListener('beforeunload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                                # `window.addEventListener('onbeforeunload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                                # Load Page
                                GxG::DISPATCHER.post_event(:display) do
                                    # sleep 0.5
                                    ::GxG::Gui::Vdom::navigate_to(`window.location['pathname']`)
                                end
                                # Establish WebSocket Channel:                    
                                ::GxG::DISPLAY_DETAILS[:socket] = ::GxG::Networking::Socket.new
                                ::GxG::DISPLAY_DETAILS[:socket].open((`window.location['host']` + "/" + @relative_url + "/ws").gsub("//","/"))
                                ::GxG::SOCKET_MONITOR.on(:attach_socket) do |the_uuid|
                                    if ::GxG::valid_uuid?(the_uuid)
                                        the_message = new_message({:attach_socket => the_uuid.to_s})
                                        the_message[:sender] = @uuid
                                        the_message[:to] = @remote_uuid
                                        # Review : add fail/succeed code blocks??
                                        GxG::CONNECTION.push(the_message)
                                    end
                                end
                                # Normally encrypts socket traffic
                                # Send format: channel.socket.send({ :payload => the_message.export.to_s.encrypt(channel.secret).encode64 }.to_json.encode64, :text)
                                ::GxG::SOCKET_MONITOR.on(:payload) do |the_data|
                                    the_message = ::GxG::Events::Message::import(the_data.to_s.decode64.decrypt(@csrf))
                                    if the_message.is_a?(::GxG::Events::Message)
                                        the_channel = ::GxG::CHANNELS.fetch_channel(the_message[:to])
                                        unless the_channel
                                            ::GxG::CHANNELS.create_channel(the_message[:to])
                                            the_channel = ::GxG::CHANNELS.fetch_channel(the_message[:to])
                                        end
                                        if the_channel
                                            the_channel.write(the_message)
                                        end
                                    end
                                end
                                ::GxG::DISPATCHER.add_periodic_timer({:interval => 0.333}) do
                                    ::GxG::SOCKET_MONITOR.follow_up
                                end
                                #
                            end
                            #
                        end
                        #
                    end
                end
                the_introduction.on(:fail) do |response|
                    @active = false
                    log_error({:error => Exception.new("Communication Error"), :parameters => {:response => response}})
                end
                GxG::DISPATCHER.post_event(:communications) do
                    GxG::CONNECTION.pull(the_introduction)
                    @heart_beat_timer = GxG::DISPATCHER.add_periodic_timer({:interval => 60.0}) do
                        GxG::CONNECTION.heartbeat()
                    end
                    # ????
                end
                # #
                # `window.addEventListener('unload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                # `window.addEventListener('beforeunload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                # `window.addEventListener('onbeforeunload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                # `window.onbeforeunload = function do_reload (the_event) {
                #     Opal.eval("GxG::CONNECTION.close");
                #     the_event.returnValue = "closing...";
                #     return "closing...";
                #     };
                # `
                #
                self
            end
            #
        end
    end
end
