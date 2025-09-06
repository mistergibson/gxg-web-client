#
#require 'gxg_uri'
#
module GxG
    module Networking
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
                the_message = new_message({:operation => "close", :display_path => @display_path})
                the_message[:sender] = @uuid
                the_message[:to] = @remote_uuid
                self.pull(the_message,{:synchronous => true})
                @active = false
                @csrf = nil
                if @heart_beat_timer.is_a?(::Hash)
                    GxG::DISPATCHER.cancel_timer(@heart_beat_timer)
                end
            end
            #
            def push(the_message=nil,options={})
                if @active
                    # Uses PUT method, with data payload
                    if the_message.is_a?(::GxG::Events::Message)
                        payload = the_message.body.to_json.to_s
                        the_xhr = `new XMLHttpRequest`
                        `#{the_xhr}.open('PUT',#{@host_prefix},true)`
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
                                the_message.succeed(::JSON.parse(`#{the_xhr}.response`,{:symbolize_names => true}))
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
            def pull(the_message=nil,options={:synchronous => false})
                if @active
                    # Uses GET method, with in-URL query specifiers (no data payload)
                    if the_message.is_a?(::GxG::Events::Message)
                        the_query = ""
                        the_message.body.keys.each do |the_key|
                            the_query = the_query + ("#{the_key.to_s}=#{the_message.body[(the_key)].to_s}")
                            unless the_key == the_message.body.keys.last
                                the_query = the_query + "&"
                            end
                        end
                        the_url = (@host_prefix.to_s + "?" + the_query)
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
                                the_message.succeed(::JSON.parse(`#{the_xhr}.response`,{:symbolize_names => true}))
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
                    self.pull_data({:operation => :search_database, :criteria => details},error_handler) do |data|
                        if data.is_a?(::Hash)
                            the_handler.call(data)
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
                    self.pull_data({:operation => :destroy_object, :location => the_specifier},error_handler) do |data|
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
                    content = details.to_json.to_s.encode64
                    msg_frame = {:sender => @uuid.to_s, :to => @remote_uuid.to_s, :display_path => @display_path, :operation => "put_portion", :thread => "00000000-0000-4000-0000-000000000000", :index => 99999, :total => 100000, :payload => ""}
                    portions = ::GxG::apportioned_ranges(content.size,(65536 - msg_frame.to_json.size))
                    #
                    if portions.size > 1
                        the_message = new_message({ :operation => "put_data", :display_path => @display_path})
                        the_message[:sender] = @uuid
                        the_message[:to] = @remote_uuid
                        the_message[:body][:thread] = the_message.id().to_s
                        #
                        if the_handler.respond_to?(:call)
                            the_message.on(:success) do |response|
                                 @buffer.delete(the_message[:body][:thread])
                                the_handler.call(response)
                            end
                        end
                        if error_handler.respond_to?(:call)
                            the_message.on(:fail) do |response|
                                @buffer.delete(the_message[:body][:thread])
                                error_handler.call(response)
                            end
                        end
                        #
                        @buffer[(the_message[:body][:thread])] = []
                        #
                        portions.each_with_index do |the_range, indexer|
                            the_msg_portion = msg_frame.clone
                            the_msg_portion[:thread] = the_message[:body][:thread]
                            the_msg_portion[:index] = indexer
                            the_msg_portion[:total] = portions.size
                            the_msg_portion[:payload] = content[(the_range)]
                            @buffer[(the_message[:body][:thread])] << the_msg_portion
                        end
                        # -----------------------------------------------------
                        # Send portions
                        (0..(portions.size - 1)).each do |the_portion|
                            ::GxG::DISPATCHER.post_event(:communications) do
                                if @buffer[(the_message[:body][:thread])].is_a?(::Array)
                                    if @buffer[(the_message[:body][:thread])][(the_portion)].is_a?(::Hash)
                                        #
                                        portion_message = new_message(@buffer[(the_message[:body][:thread])][(the_portion)])
                                        portion_message[:sender] = @uuid
                                        portion_message[:to] = @remote_uuid
                                        # 
                                        portion_message.on(:succeed) do |response|
                                            if the_portion == (@buffer[(the_message[:body][:thread])].size - 1)
                                                if @buffer[(the_message[:body][:thread])]
                                                    GxG::CONNECTION.push(the_message)
                                                end
                                            end
                                        end
                                        # 
                                        portion_message.on(:fail) do |response|
                                            the_message.fail(response)
                                        end
                                        #
                                        GxG::CONNECTION.push(portion_message)
                                    end
                                end
                            end
                        end
                        #
                    else
                        # single message payload
                        the_message = new_message({ :operation => "put_data", :display_path => @display_path, :payload => content})
                        the_message[:sender] = @uuid
                        the_message[:to] = @remote_uuid
                        GxG::CONNECTION.push(the_message)
                    end
                    #
                    true
                else
                    false
                end
            end
            #
            def push_object(details={}, error_handler=nil,&the_handler)
                if details.is_a?(::Hash) && the_handler
                    self.push_data({:operation => :put_object, :data => details},error_handler) do |data|
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
            def pull_data(the_specifier={},error_handler=nil,&the_handler)
                if the_specifier && the_handler
                    the_message = new_message({:operation => "get_data", :thread => nil, :display_path => @display_path, :details => the_specifier.to_json.encode64})
                    the_message[:sender] = @uuid
                    the_message[:to] = @remote_uuid
                    the_message[:body][:thread] = the_message.id().to_s
                    if error_handler.respond_to?(:call)
                        the_message.on(:fail,&error_handler)
                    end
                    the_message.on(:success) do |response|
                        if response.is_a?(::Hash)
                            if response[:result] == true
                                case response[:operation]
                                when "this_portion"
                                    data = response[:payload]
                                    if data.is_a?(::String)
                                        # FIXME: <String>.base64? needs a proper working regex (or go brute force)
                                        # data = Base64::strict_decode64(data)
                                        if data.base64?
                                            data = data.decode64
                                        end
                                        if data.json?
                                            begin
                                                data = ::JSON::parse(data,{:symbolize_names => true})
                                            rescue Exception => the_error
                                                log_error({:error => the_error, :parameters => {:data => data}})
                                            end
                                        end
                                        the_handler.call(data)
                                    else
                                        log_error({:error => Exception.new("Malformed Response Data"), :parameters => {:data => data}})
                                    end
                                when "get_portions"
                                    @pending[(response[:thread])] = the_message
                                    @buffers[(response[:thread])] = []
                                    the_messages = []
                                    (0..(response[:total] - 1)).each do |indexer|
                                        portion_message = new_message({:operation => "get_portion", :thread => (response[:thread]), :index => indexer, :display_path => @display_path})
                                        portion_message[:sender] = @uuid
                                        portion_message[:to] = @remote_uuid
                                        #
                                        portion_message.on(:success) do |reply|
                                            @buffers[(response[:thread])] << reply
                                            if @buffers[(response[:thread])].size == response[:total]
                                                already = []
                                                the_data = ""
                                                until already.size == response[:total] do
                                                    (0..(response[:total] - 1)).each do |referencer|
                                                        unless already.index(referencer)
                                                            the_data = (the_data + (@buffers[(response[:thread])][(referencer)][:payload]))
                                                            already << referencer
                                                            break
                                                        end
                                                    end
                                                end
                                                signal_message = new_message({:operation => "got_portions", :thread => response[:thread], :display_path => @display_path})
                                                signal_message[:sender] = @uuid
                                                signal_message[:to] = @remote_uuid
                                                GxG::CONNECTION.pull(signal_message)
                                                #
                                                @pending.delete(response[:thread])
                                                @buffers.delete(response[:thread])
                                                if the_data.size > 0
                                                    # FIXME: <String>.base64? needs a proper working regex (or go brute force)
                                                    # the_data = Base64::strict_decode64(the_data)
                                                    if the_data.base64?
                                                        the_data = the_data.decode64
                                                    end
                                                    if the_data.json?
                                                        begin
                                                            the_data = ::JSON::parse(the_data,{:symbolize_names => true})
                                                        rescue Exception => the_error
                                                            log_error({:error => the_error, :parameters => {:data => the_data}})
                                                        end
                                                    end
                                                    the_handler.call(the_data)
                                                else
                                                    log_warn("Empty payload from portions.")
                                                end
                                            end
                                        end
                                        #
                                        portion_message.on(:fail) do |reply|
                                            log_warn("Cancelling Transfer: portion #{indexer} of thread #{response[:thread]}.")
                                            @pending.delete(response[:thread])
                                            @buffers.delete(response[:thread])
                                            if error_handler.respond_to?(:call)
                                                error_handler.call(reply)
                                            end
                                        end
                                        #
                                        # GxG::CONNECTION.pull(portion_message)
                                        the_messages << portion_message
                                        #
                                    end
                                    the_messages.each do |a_message|
                                        GxG::CONNECTION.pull(a_message)
                                    end
                                end
                            end
                        end
                    end
                    GxG::CONNECTION.pull(the_message)
                end
            end
            #
            def pull_object(the_specifier=nil,error_handler=nil,&the_handler)
                # Use pull_data({:operation => :get_object, :location => the_specifier})
                if the_specifier && the_handler
                    # GxG::DISPLAY_DETAILS[:object].set_busy(true)
                    self.pull_data({:operation => :get_object, :location => the_specifier},error_handler) do |data|
                        if data.is_a?(::Hash)
                            the_handler.call(::GxG::Database::process_detached_import(data))
                            # GxG::DISPLAY_DETAILS[:object].set_busy(false)
                        end
                    end
                    true
                else
                    false
                end
            end
            #
            def get_permissions(the_specifier=nil,error_handler=nil,&the_handler)
                # See vfs: :action => 'set_permissions', :path => (location), :alterations => [{:credential => nil, :permissions => {...}}], :revocations => [(a-credential)]
                if the_specifier && the_handler
                    # GxG::DISPLAY_DETAILS[:object].set_busy(true)
                    self.pull_data({:operation => :get_permissions, :location => the_specifier},error_handler) do |data|
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
            #
            # Libarary Loading Support:
            def library_pull(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data({:operation => :get_library}.merge!(details),error_handler) do |data|
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
                        self.pull_data({:operation => :format_pull, :criteria => details},error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            # TODO: format_push(data={})
            # Admin:
            def admin(details={}, error_handler=nil, &the_handler)
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data(({:operation => :admin}.merge!(details)),error_handler) do |data|
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
                # Specify either a :location or :name
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        self.pull_data(({:operation => :vfs}.merge!(details)),error_handler) do |data|
                            the_handler.call(data)
                        end
                        true
                    else
                        false
                    end
                end
            end
            #
            # Application Support:
            def app_state_push(details={}, error_handler=nil, &the_handler)
                if details.is_a?(::Hash) && the_handler
                    self.push_data({:operation => :app_state_push, :application => details[:application], :data => details[:data]},error_handler) do |data|
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
                        self.pull_data({:operation => :app_state_pull, :application => details[:application]},error_handler) do |data|
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
                # Specify either a :location or :name
                if self.open?
                    if details.is_a?(::Hash) && the_handler
                        if details[:name]
                            self.pull_data({:operation => :application_open, :restore => (details[:restore] || false), :name => details[:name]},error_handler) do |data|
                                the_handler.call(data)
                            end
                        else
                            self.pull_data({:operation => :application_open, :restore => (details[:restore] || false), :location => details[:location]},error_handler) do |data|
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
                        self.pull_data({:operation => :application_close, :application => details[:application]},error_handler) do |data|
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
                        self.pull_data({:operation => :application_list},error_handler) do |data|
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
                        self.pull_data({:operation => :application_menu},error_handler) do |data|
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
                        self.pull_data({:operation => :entries, :location => details[:location]},error_handler) do |data|
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
                    heartbeat_message = new_message({:operation => "heartbeat", :display_path => @display_path})
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
                        the_message = new_message({:operation => "update_credential", :display_path => @display_path, :payload => content})
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
                    downgrade_message = new_message({:operation => "downgrade_credential", :display_path => @display_path})
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
            def initialize()
                if (`window.location['href']`).include?("https://")
                    @host_prefix = ("https://" + `window.location['host']`)
                else
                    @host_prefix = ("http://" + `window.location['host']`)
                end
                @relative_url = ""
                # Find Relative URL
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
                the_introduction = new_message({:operation => "introduction", :introducing => @uuid.to_s})
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
                                ::GxG::DISPLAY_DETAILS[:object] = ::GxG::Gui::Page.new(@display_path)
                                GxG::DISPATCHER.post_event(:display) do
                                    sleep 1.0
                                    ::GxG::DISPLAY_DETAILS[:object].layout_refresh
                                end
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
                end
                #
                `window.addEventListener('unload', do_unload,false);function do_unload() { Opal.GxG.$eval("GxG::CONNECTION.close"); };`
                #
                self
            end
            #
        end
    end
end
