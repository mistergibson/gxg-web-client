module GxG
    # ----------------------------------------------------------------------------------------------------
    class Application
        def initialize(settings={})
            # @process = server-side process uuid
            @process = settings[:application]
            # receives a :source PersistedHash defining the application internals.
            @definition = settings[:source]
            @title = "Untitled"
            # @state is persisted as state-data on the server when altered.
            @state = (settings[:state] || {})
            # Gui component if any:
            @viewports = {}
            if settings[:viewport].is_a?(::GxG::Gui::ApplicationViewport)
                @viewports[(settings[:viewport].uuid.to_s.to_sym)] = settings[:viewport]
            end
            if settings[:viewports].is_a?(::Array)
                settings[:viewports].each do |the_viewport|
                    if the_viewport.is_a?(::GxG::Gui::ApplicationViewport)
                        @viewports[(the_viewport.uuid.to_s.to_sym)] = the_viewport
                    end
                end
            end
            @windows = {}
            if settings[:window].is_a?(::GxG::Gui::Window)
                @windows[(settings[:window].uuid.to_s.to_sym)] = settings[:window]
            end
            if settings[:windows].is_a?(::Array)
                settings[:windows].each do |the_window|
                    if the_window.is_a?(::GxG::Gui::Window)
                        @windows[(the_window.uuid.to_s.to_sym)] = the_window
                    end
                end
            end
            @libraries = {}
            # Event Supports:
            @event_handlers = {}
            @event_listeners = {}
            # Runtime flags:
            @credentialed = (settings[:credentialed] || false)
            @unique = (settings[:unique] || true)
            # Application location:
            @location = settings[:location]
            # Internal Heap:
            @heap = {}
            # ### Compile Source
            if @definition.is_a?(::String)
                if @definition.base64?
                    @definition = @definition.decode64
                end
                if @definition.json?
                    begin
                        @definition = ::JSON::parse(@definition,{:symbolize_names => true})
                        @definition = ::GxG::Database::process_import(@definition)
                    rescue Exception => the_error
                        log_error({:error => the_error, :parameters => {:definition => @definition}})
                    end
                else
                    # error - malformed source.
                end
            end
            if @definition.is_a?(::GxG::Database::DetachedHash)
                @title = @definition.title
                # Question: should I overwrite the potentially passed settings options?
                the_opts = @definition[:options].unpersist
                if the_opts[:credentialed] == true
                    @credentialed = true
                else
                    @credentialed = false
                end
                if the_opts[:unique] == true
                    @unique = true
                else
                    @unique = false
                end
            end
            # Load Libraries
            # You can use ruby or javascript for the :native code portion which will be added to the page body.
            # you can then also set a wrapper library script on the library for smooth integration.
            # use get_library(uuid/title) to access the library in order to call methods.
            if @definition.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
            	# libarary requirement format: {:library => "", :type => "", :minimum => 0.0, :maximum => nil}
                load_list = []
                if @definition[:requirements].is_any?(::GxG::Database::DetachedArray, ::GxG::Database::PersistedArray)
                    @definition[:requirements].each do |the_requirement|
                        unless GxG::DISPLAY_DETAILS[:object].library_loaded?(the_requirement)
                            load_list << the_requirement
                        end
                    end
                end
            	GxG::DISPLAY_DETAILS[:object].load_libraries(load_list) do |all_loaded|
                    if all_loaded == true
                        # Link to libraries required:
                        if @definition[:requirements].is_a?(::GxG::Database::PersistedArray)
                            @definition[:requirements].each do |the_requirement|
                                the_library = GxG::DISPLAY_DETAILS[:object].get_library(the_requirement)
                                if the_library
                                    @libraries[(the_library.uuid)] = the_library
                                end
                            end
                        end
            			# Set Script:
                		if @definition[:script].size > 0
                    		if @definition[:script].base64?
                        		instance_eval(@definition[:script].to_s.decode64)
                    		else
                        		instance_eval(@definition[:script].to_s)
                    		end
                		end
            		else
            			log_warn("Library load error - not processing main application script for #{@definition.title}.")
            		end
            	end
            end
            #
            self
        end
        #
        def get_resource(the_reference=nil)
            result = nil
            if @definition
            	@definition[:content].each do |the_object|
                    if (the_object.title == the_reference || the_object.uuid == the_refrence.to_s.to_sym)
                        result = the_object
                        break
                    end
            	end
            end
            result
        end
        #
        def require_resource(the_reference=nil)
            # call self.require_resource("script-name") to load content.script-name
            result = false
            if @definition
                # content source record format: {:component => "script", :type => "text/ruby", :script => ""}
                the_script = self.get_resource(the_reference)
                if the_script
                    if the_script[:component].to_s == "script" && the_script[:type].to_s == "text/ruby"
                        if the_script[:script].size > 0
                            if the_script[:script].base64?
                                instance_eval(the_script[:script].to_s.decode64)
                            else
                                instance_eval(the_script[:script].to_s)
                            end
            				result = true
                        end
                    end
                end
            end
            result
        end
        #
        def title()
            @title
        end
        #
        def credentialed()
            @credentialed
        end
        #
        def unique()
            @unique
        end
        #
        def location()
            @location
        end
        # Libraries:
        def libraries()
            @libraries
        end
        #
        def state_data()
            @state
        end
        #
        def state_pull()
            GxG::CONNECTION.app_state_pull({:application => @process.to_s}) do |response|
                if response.is_a?(::Hash)
                    if response[:result].is_a?(::Hash)
                        @state = response[:result]
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
        end
        #
        def state_push()
            GxG::CONNECTION.app_state_push({:application => @process.to_s, :data => @state}) do |response|
                if response.is_a?(::Hash)
                    if response[:result] == true
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
        end
        #
        def get_library(the_reference=nil)
            result = nil
            if the_reference.is_any?(::String, ::Symbol)
                result = @libraries[(the_reference.to_s.to_sym)]
                unless result
                    @libraries.values.each do |the_library|
                        if the_library.title == the_reference
                            result = the_library
                            break
                        end
                    end
                end
            end
            result
        end
        #
        # Viewport Supports:
        def link_viewport(the_viewport=nil)
            if the_viewport.is_a?(::GxG::Gui::ApplicationViewport)
                @viewports[(the_viewport.uuid.to_s.to_sym)] = the_viewport
                true
            else
                false
            end
        end
        #
        def unlink_viewport(the_reference=nil)
            if the_reference.is_any?(::String, ::Symbol)
                if @viewports[(the_reference.to_s.to_sym)]
                    @viewports.delete((the_reference.to_s.to_sym))
                else
                    @viewports.values.each do |the_viewport|
                        if the_viewport.title == the_reference
                            @viewports.delete(the_viewport.uuid)
                            break
                        end
                    end
                end                
                true
            else
                false
            end
        end
        #
        def viewports()
            @viewports
        end
        #
        def get_viewport(the_reference=nil)
            result = nil
            if the_reference.is_any?(::String, ::Symbol)
                result = @viewports[(the_reference.to_s.to_sym)]
                unless result
                    @viewports.values.each do |the_viewport|
                        if the_viewport.title == the_reference
                            result = the_viewport
                            break
                        end
                    end
                end
            end
            result
        end
        #
        # Window Supports:
        def link_window(the_window=nil)
            if the_window.is_a?(::GxG::Gui::Window)
                @windows[(the_window.uuid.to_s.to_sym)] = the_window
                # Review: add link to window object to application ??
                true
            else
                false
            end
        end
        #
        def unlink_window(the_reference=nil)
            if the_reference.is_any?(::String, ::Symbol)
                if @windows[(the_reference.to_s.to_sym)]
                    @windows.delete((the_reference.to_s.to_sym))
                else
                    @windows.values.each do |the_window|
                        if the_window.title == the_reference
                            @windows.delete(the_window.uuid)
                            break
                        end
                    end
                end                
                true
            else
                false
            end
        end
        #
        def windows()
            @windows
        end
        #
        def get_window(the_reference=nil)
            result = nil
            if the_reference.is_any?(::String, ::Symbol)
                result = @windows[(the_reference.to_s.to_sym)]
                unless result
                    @windows.values.each do |the_window|
                        if the_window.title == the_reference
                            result = the_window
                            break
                        end
                    end
                end
            end
            result
        end
        #
        def process_uuid()
            @process
        end
        #
        def source_uuid()
            if @definition.is_a?(::GxG::Database::DetachedHash)
                @definition.uuid()
            else
                nil
            end
        end
        #
        def search_resources(the_reference=nil)
            result = nil
            if the_reference.is_any?(::String, ::Symbol)
                if @definition
                    @definition[:content].search do |item,selector,container|
                        if item.is_a?(::GxG::Database::DetachedHash)
                            if the_reference.to_s.to_sym == item.uuid().to_s.to_sym || the_reference.to_s == item.title().to_s
                                result = item
                                break
                            end
                        end
                    end
                end
            end
            result
        end
        # Event Supports:
        ## Internal method on
        def on(the_event_type=nil, captured=false, &block)
            if the_event_type.is_any?(::String, ::Symbol)
                if block.respond_to?(:call)
                    @event_handlers[(the_event_type.to_s.downcase.to_sym)] = block
                    @event_listeners[(the_event_type.to_s.downcase.to_sym)] = `#{self.method(:event_handler).to_proc}`
                    `#{self.element}.addEventListener(#{the_event_type.to_s.downcase}, #{@event_listeners[(the_event_type.to_s.downcase.to_sym)]}, #{captured})`
                end
            end
        end
        #
        def remove_listener(the_event_type=nil)
           if @event_handlers[(the_event_type.to_s.downcase.to_sym)] && @event_listeners[(the_event_type.to_s.downcase.to_sym)]
               `#{self.element}.removeEventListener(#{the_event_type.to_s.downcase},#{@event_listeners[(the_event_type.to_s.downcase.to_sym)]});`
               @event_handlers.delete(the_event_type.to_s.downcase.to_sym)
               @event_listeners.delete(the_event_type.to_s.downcase.to_sym)
           end
           true
        end
        #
        def event_handler(the_event)
           # format the event record for travel in the system.
           # See: https://www.w3schools.com/jsref/dom_obj_event.asp
           # Setup event type groupings to glean appropriate details from the event.
           the_type = `#{the_event}.type`.to_s.downcase.to_sym
           event_record = {}
           if @event_handlers[(the_type)]
               genre = (GxG::Gui::EventHandlers::EVENT_GENRES[(the_type)] || :event)
               if genre
                   fields = GxG::Gui::EventHandlers::EVENT_FIELDS[(genre)]
                   if fields
                       #
                       %x{
                           serializer = function thisOne (e) {
                               if (e) {
                                   var o = {
                                   eventName: e.toString(),
                                   altKey: e.altKey,
                                   bubbles: e.bubbles,
                                   button: e.button,
                                   buttons: e.buttons,
                                   cancelBubble: e.cancelBubble,
                                   cancelable: e.cancelable,
                                   clientX: e.clientX,
                                   clientY: e.clientY,
                                   composed: e.composed,
                                   ctrlKey: e.ctrlKey,
                                   currentTarget: e.currentTarget ? e.currentTarget.outerHTML : null,
                                   defaultPrevented: e.defaultPrevented,
                                   detail: e.detail,
                                   eventPhase: e.eventPhase,
                                   fromElement: e.fromElement ? e.fromElement.outerHTML : null,
                                   isTrusted: e.isTrusted,
                                   layerX: e.layerX,
                                   layerY: e.layerY,
                                   metaKey: e.metaKey,
                                   movementX: e.movementX,
                                   movementY: e.movementY,
                                   offsetX: e.offsetX,
                                   offsetY: e.offsetY,
                                   pageX: e.pageX,
                                   pageY: e.pageY,
                                   relatedTarget: e.relatedTarget ? e.relatedTarget.outerHTML : null,
                                   returnValue: e.returnValue,
                                   screenX: e.screenX,
                                   screenY: e.screenY,
                                   shiftKey: e.shiftKey,
                                   sourceCapabilities: e.sourceCapabilities ? e.sourceCapabilities.toString() : null,
                                   target: e.target ? e.target.outerHTML : null,
                                   timeStamp: e.timeStamp,
                                   toElement: e.toElement ? e.toElement.outerHTML : null,
                                   type: e.type,
                                   view: e.view ? e.view.toString() : null,
                                   which: e.which,
                                   x: e.x,
                                   y: e.y
                                   };
                                   return o;
                               };
                           };
                           event_record = JSON.stringify(serializer(#{the_event}));
                       }
                       event_record = ::JSON::parse(event_record.to_s, {:symbolize_names => true})
                       # puts "Got: #{event_record.inspect}"
                   end
               end
               #
               @event_handlers[(the_type)].call(event_record)
               #
            end
        end
        #
        def menu_item_select(data=nil)
            # override this in your object script.
            # data will contain the entire menu object settings.
        end
        #
        def run(data={})
            # override this in your object script.
            if data.is_a?(::Hash)
                if data[:restore] == true
                    self.state_pull
                end
            end
        end
        #
        def exitready?(data={})
            # override this in your object script.
            :ready
        end
        # 
        def before_exit(data={})
            # override this in your object script.
            true
        end
        def exit(data={})
            # override this in your object script.
            # GxG::APPLICATIONS[:processes]
            GxG::CONNECTION.application_close({:application => @process}) do |response|
                if response.is_a?(::Hash)
                    if response[:result] == true
                        GxG::APPLICATIONS[:processes].delete(@process)
                    else
                        log_warn("Could not close application #{@process.inspect} : #{response.inspect}")
                    end
                else
                    log_warn("Malformed response: #{response.inspect}")
                end
            end
            true
        end
        #
        def window_close(details={})
            # override this in your object script.
            if details.is_a?(::Hash)
                if GxG::valid_uuid?(details[:window])
                    the_window = GxG::DISPLAY_DETAILS[:object].get_window(details[:window])
                    if the_window
                        # TODO: re-think documents and such.
                        # Document data needs saving first ??
                        @viewports.keys.each do |the_reference|
                            the_viewport = the_window.find_child(the_reference)
                            if the_viewport
                                the_viewport.set_application(nil)
                                self.unlink_viewport(the_reference)
                            end
                        end
                        self.unlink_window(the_window.uuid)
                        GxG::DISPLAY_DETAILS[:object].window_close(the_window.uuid)
                        unless @windows.size > 0
                            self.exit()
                        end
                    end
                else
                    log_warn("Invalid Argument passed: #{details.inspect}")
                end
            end
        end
        #
        # Viewport Management:
        def viewport_clear(the_reference=nil)
            viewport = self.get_viewport(the_reference)
            if viewport
                viewport.gxg_each_child do |the_item|
                    unless the_item == viewport
                        the_item.destroy
                    end
                end
                true
            else
                false
            end
        end
        #
    end
end