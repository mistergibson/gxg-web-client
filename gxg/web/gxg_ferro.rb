#
module GxG
    DISPLAY_DETAILS = {:server_status => :running, :logged_in => false, :host_path => "", :use_ssl => false, :connection => nil, :socket => nil, :object => nil, :theme => "default", :query => {}, :article => nil, :mode => :browsing, :mouse_x => 0, :mouse_y => 0, :mousedown => false}
    module Gui
        #
          module Css
            @@CssCache = []
            @@CssRuleProperties = {}
            #
            def self.load_font(font_profile=nil)
                if font_profile.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if font_profile.is_a?(::GxG::Database::PersistedHash)
                        font_profile = font_profile.unpersist()
                    end
                    if font_profile[:resource_type] == "font-face"
                        thefamily = (font_profile[:font_family] || "Unknown")
                        thestyle = (font_profile[:font_style] || "normal")
                        theweight = (font_profile[:font_weight] || 400).to_s
                        if font_profile[:format]
                            fontformat = font_profile[:format].to_s.downcase
                        else
                            case File.extname(font_profile[:source]).downcase
                            when ".ttf", ".otf"
                                fontformat = "truetype"
                            when ".eot"
                                fontformat = "embedded-opentype"
                            when ".svg"
                                fontformat = "svg"
                            when ".woff"
                                fontformat = "woff"
                            when ".woff2"
                                fontformat = "woff2"
                            else
                                fontformat = "unknown"
                            end
                        end
                        if ["sftp:","ftp:/","http:", "https"].include?(font_profile[:source][0..4].downcase)
                            # reach out over the internet for the resource
                            source_url = font_profile[:source]
                        else
                            # search local site at resource path
                            source_url = GxG::DISPLAY_DETAILS[:object].site_asset(font_profile[:source])
                        end
                        #
                        %x{
                            var family = #{thefamily.to_s};
                            var sourceurl = "url('" + #{source_url} + "')";
                            var theformat = "format('" + #{fontformat} + "')";
                            if (theformat == "format('unknown')") {
                                var sourcestring = sourceurl;
                            } else {
                                var sourcestring = (sourceurl + " " + theformat);
                            };
                            var theweight = #{theweight};
                            var thestyle = #{thestyle};
                            var thefont = new FontFace(family, sourceurl, {weight: theweight, style: thestyle});
                            thefont.load().then(function(loaded_face) {
                                document.fonts.add(loaded_face);
                            }).catch(function(error) {
                                alert(error);
                            });
                        }
                        true
                    else
                        log_warn("You attempted to load a non-font resource as a font: #{font_profile.inspect}")
                        false
                    end
                else
                    log_warn("You attempted to load a font with the wrong value: #{font_profile.inspect}")
                    false
                end
            end
            #
            class CSSRule
              # Provide EASY interface to native CSS Rule.
              def initialize(the_native_rule)
                @native_rule = the_native_rule
                @name = (`#{@native_rule}.selectorText` || "").to_s.to_sym
              end
              #
              def native_object()
                @native_rule
              end
              #
              def inspect()
                "<CSSRule: #{@name}>"
              end
              #
              def name()
                @name
              end
              #
              def keys()
                GxG::Gui::Css::valid_properties()
              end
              #
              def [](the_key)
                `#{@native_rule}.style[#{the_key}]`
              end
              #
              def []=(the_key, the_value)
                #
                `#{@native_rule}.style[#{the_key}] = #{(the_value || "")}`
                the_value
              end
              #
              def merge(properties={})
                properties.keys.each do |the_key|
                  self[(the_key)] = properties[(the_key)]
                end
                self
              end
              #
            end
            #
            def self.gxg_style_sheet()
                result = nil
                 sheets = `document.styleSheets.length`.to_i
                 (0..(sheets - 1)).each do |sheet_index|
                     the_sheet = `document.styleSheets[#{sheet_index}]`
                     if the_sheet
                         if `#{the_sheet}.href`.to_s.include?("/themes/page.css")
                             result = the_sheet
                             break
                         end
                     end
                 end
                 result
            end
            #
            def  self.refresh_css_cache()
                the_style_sheet = GxG::Gui::Css::gxg_style_sheet()
                if the_style_sheet
                  new_cache = []
                  begin
                    ruleset = `#{the_style_sheet}.cssRules`
                  rescue Exception => the_error
                    ruleset = `#{the_style_sheet}.rules`
                  end
                  if ruleset
                      rules_count = (`#{ruleset}.length`.to_i)
                      if rules_count > 0
                          end_index = ((`#{ruleset}.length`.to_i) - 1)
                      else
                          end_index = 0
                      end
                      (0..(end_index)).each do |indexer|
                        begin
                          native_rule = `#{the_style_sheet}.cssRules[#{indexer}]`
                        rescue Exception => the_error
                          native_rule = `#{the_style_sheet}.rules[#{indexer}]`
                        end
                        if native_rule
                          new_cache << GxG::Gui::Css::CSSRule.new(native_rule)
                        end
                      end
                  end
                  @@CssCache = new_cache
                end
              true
            end
            #
            def self.valid_properties()
              @@CssRuleProperties.keys
            end
            #
            def self.get_property_name(the_key=nil)
              result = nil
              if the_key.is_a?(::Symbol)
                result = @@CssRuleProperties[(the_key)]
              end
              result
            end
            #
            def self.rules()
              result = []
              @@CssCache.each do |entry|
                result << entry.name
              end
              result
            end
            #
            def self.find_rule(the_rule_selector=nil)
              result = []
              @@CssCache.each do |entry|
                if entry.name == (the_rule_selector.to_s.to_sym)
                  result << entry
                end
              end
              result
            end
            #
            def self.set_rule(the_rule_selector=nil, the_properties={}, options={:merge => true})
              # find existing
              # remove existing
              # create or re-create
              the_style_sheet = GxG::Gui::Css::gxg_style_sheet()
              if the_style_sheet
                found = GxG::Gui::Css::find_rule(the_rule_selector)
                if found.size > 0
                    GxG::Gui::Css::remove_rule(the_rule_selector)
                end
                # create it
                the_site_prefix = ::GxG::CONNECTION.relative_url()
                rule_string = "{ "
                the_properties.keys.each do |property_key|
                    the_value = the_properties[(property_key)].to_s
                    if the_value.include?("url(")
                        end_point = the_value.index(")")
                        the_path = the_value[4..(end_point - 1)]
                        unless the_path.include?("data:") || the_path.include?("http:") || the_path.include?("https:")
                            unless (the_path[(0..(the_site_prefix.size - 1))] == the_site_prefix)
                                the_value = ("url(" + File.expand_path(the_site_prefix + "/" + the_path) + ")")
                            end
                        end
                    end
                    rule_string = rule_string + ("#{property_key.to_s}: #{the_value}; ")
                end
                rule_string = rule_string + " }"
                if `#{the_style_sheet}.insertRule(#{the_rule_selector.to_s + rule_string.to_s},(#{the_style_sheet}.cssRules.length))`.to_i == `(#{the_style_sheet}.cssRules.length - 1)`.to_i
                    begin
                        native_rule = `#{the_style_sheet}.cssRules[(#{the_style_sheet}.cssRules.length - 1)]`
                    rescue Exception => the_error
                        native_rule = `#{the_style_sheet}.rules[(#{the_style_sheet}.cssRules.length - 1)]`
                    end
                    @@CssCache << GxG::Gui::Css::CSSRule.new(native_rule)
                    true
                else
                    log_warn("GxG Style Sheet Rule creation failed..")
                    false
                end
              else
                  log_warn("GxG Style Sheet not found.")
                  false
              end
              #
            end
            #
            def self.remove_rule(the_rule_selector=nil)
                found_indexes = []
                @@CssCache.each_with_index do |entry, index|
                    if entry.name == the_rule_selector.to_s.to_sym || entry.name == the_rule_selector.to_s
                        found_indexes << index
                    end
                end
                found = []
                found_indexes.reverse.each do |the_index|
                    found << @@CssCache.delete_at(the_index)
                end
                if found.size > 0
                    found.each do |the_rule|
                        native_rule = the_rule.native_object()
                        the_sheet = GxG::Gui::Css::gxg_style_sheet()
                        if the_sheet
                            rule_count = `#{the_sheet}.cssRules.length`.to_i
                            if rule_count > 0
                                (0..(rule_count - 1)).to_a.reverse.each do |rule_index|
                                    other_native_rule = `#{the_sheet}.cssRules[#{rule_index}]`
                                    if other_native_rule
                                        if `#{native_rule}.selectorText == #{other_native_rule}.selectorText`
                                            `#{the_sheet}.deleteRule(#{rule_index})`
                                        end
                                    end
                                end
                            end
                        end
                    end
                    true
                else
                    false
                end
            end
            #
          end
          #
        # --------------------------------------------------------------------------------------------------------------------------------------
        module EventHandlers
            # Constants:
            EVENT_TYPES = [
                            "abort",
                            "afterprint",
                            "animatedend",
                            "animationiteration",
                            "animationstart",
                            "beforeprint",
                            "beforeunload",
                            "blur",
                            "canplay",
                            "canplaythrough",
                            "change",
                            "click",
                            "contextmenu",
                            "copy",
                            "cut",
                            "dblclick",
                            "drag",
                            "dragend",
                            "dragcenter",
                            "dragleave",
                            "dragover",
                            "dragstart",
                            "drop",
                            "durationchange",
                            "ended",
                            "error",
                            "focus",
                            "focusin",
                            "focusout",
                            "fullscreenchange",
                            "fullscreenerror",
                            "hashchange",
                            "input",
                            "invalid",
                            "keydown",
                            "keypress",
                            "keyup",
                            "load",
                            "loadeddata",
                            "loadedmetadata",
                            "loadstart",
                            "message",
                            "mousedown",
                            "mouseenter",
                            "mouseleave",
                            "mousemove",
                            "mouseover",
                            "mouseup",
                            "offline",
                            "online",
                            "open",
                            "pagehide",
                            "pageshow",
                            "paste",
                            "play",
                            "playing",
                            "popstate",
                            "progress",
                            "ratechange",
                            "resize",
                            "reset",
                            "scroll",
                            "search",
                            "seeked",
                            "select",
                            "show",
                            "stalled",
                            "storage",
                            "submit",
                            "suspend",
                            "timeupdate",
                            "toggle",
                            "touchcancel",
                            "touchend",
                            "touchmove",
                            "touchstart",
                            "transitionend",
                            "unload",
                            "volumechange",
                            "waiting",
                            "wheel"
                            ]
            #
            EVENT_GENRES = {
                :click => :mouse,
                :contextmenu => :mouse,
                :dblclick => :mouse,
                :mouseenter => :mouse,
                :mouseleave => :mouse,
                :mouseover => :mouse,
                :mouseup => :mouse,
                :mousedown => :mouse,
                :mousemove => :mouse,
                :mouseout => :mouse,
                :keydown => :keyboard,
                :keypress => :keyboard,
                :keyup => :keyboard,
                :touchcancel => :touch,
                :touchmove => :touch,
                :touchstart => :touch,
                :touchend => :touch,
                :animationstart => :animation,
                :animationend => :animation,
                :animationiteration => :animation,
                :animationpause => :animation,
                :animationresume => :animation,
                :animationstop => :animation,
                :input => :input,
                :drag => :drag,
                :dragend => :drag,
                :dragenter => :drag,
                :dragleave => :drag,
                :dragover => :drag,
                :dragstart => :drag,
                :drop => :drag,
                :wheel => :wheel,
                :abort => :ui,
                :beforeunload => :ui,
                :error => :ui,
                :load => :ui,
                :resize => :ui,
                :scroll => :ui,
                :select => :ui,
                :unload => :ui,
                :blur => :focus,
                :focus => :focus,
                :focusin => :focus,
                :focusout => :focus,
                :afterprint => :event,
                :beforeprint => :event,
                :canplay => :event,
                :canplaythrough => :event,
                :change => :event,
                :fullscreenchange => :event,
                :fullscreenerror => :event,
                :invalid => :event,
                :loadeddata => :event,
                :loadedmetadata => :event,
                :message => :event,
                :offline => :event,
                :online => :event,
                :open => :event,
                :close => :event,
                :pause => :event,
                :play => :event,
                :playing => :event,
                :progress => :event,
                :changerate => :event,
                :reset => :event,
                :search => :event,
                :seek => :event,
                :seeking => :event,
                :show => :event,
                :hide => :event,
                :stalled => :event,
                :submit => :event,
                :suspend => :event,
                :timeupdate => :event,
                :toggle => :event,
                :waiting => :event,
                :copy => :clipboard,
                :cut => :clipboard,
                :paste => :clipboard,
                :pagehide => :transition,
                :pageshow => :transition,
                :popstate => :history,
                :loadstart => :progress,
                :storage => :storage,
                :credentialchanged => :ui
                }
            #TODO: look into fully supporting touch screen gleaning functions.
            EVENT_FIELDS = {
                :mouse => [:altKey, :button, :buttons, :clientX, :clientY, :ctrlKey, :metaKey, :movementX, :movementY, :offsetX, :offsetY, :pageX, :pageY, :screenX, :screenY, :shiftKey, :which, :detail, :view, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :keyboard => [:altKey, :charCode, :code, :ctrlKey, :metaKey, :isComposing, :key, :keyCode, :location, :shift, :repeat, :shiftKey, :which, :detail, :view, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :touch => [:altKey, :ctrlKey, :metaKey, :shiftKey, :detail, :view, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :animation => [:animationName, :elapsedTime, :pseudoElement, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :input => [:data, :inputType, :isComposing, :detail, :view, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :drag => [:dataTranser, :altKey, :button, :buttons, :clientX, :clientY, :ctrlKey, :metaKey, :movementX, :movementY, :offsetX, :offsetY, :pageX, :pageY, :screenX, :screenY, :shiftKey, :which, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :wheel => [:deltaX, :deltaY, :deltaZ, :deltaMode, :altKey, :button, :buttons, :clientX, :clientY, :ctrlKey, :metaKey, :movementX, :movementY, :offsetX, :offsetY, :pageX, :pageY, :screenX, :screenY, :shiftKey, :which, :detail, :view, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :ui => [:detail, :view,:bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :focus => [:relatedTarget, :detail, :view, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :event => [:bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :transition => [:persisted, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :history => [:state, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :progress => [:lengthComputable, :loaded, :total, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :storage => [:key, :newValue, :oldValue, :storageArea, :url, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp],
                :clipboard => [:clipboardData, :bubbles, :cancelable, :currentTarget, :defaultPrevented, :eventPhase, :isTrusted, :target, :timeStamp]
                }
             # Internal method on
             def on(the_event_type=nil, captured=false, &block)
                 unless @event_handlers.is_a?(::Hash)
                     @event_handlers = {}
                     @event_listeners = {}
                 end
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
             def set_script(the_script_body="")
                 result = false
                 if the_script_body.size > 0
                     #
                     begin
                         #
                         if the_script_body.base64?
                             the_script_body = the_script_body.decode64
                         end
                         # 
                         instance_eval(the_script_body)
                         result = true
                     rescue Exception => the_error
                         log_error({:error => the_error, :parameters => {:script => the_script_body}})
                     end
                 end
                 result
             end
             #
        end
        # --------------------------------------------------------------------------------------------------------------------------------------
        # Animation Support:
        class Animation
            #
            def initialize(details={}, the_uuid=nil)
                @event_handlers = {}
                 if details.is_any?(::Hash, ::GxG::Database::PersistedHash)
                     if details[:origin]
                         if details[:origin].is_a?(::GxG::Database::PersistedHash)
                             @origin = details[:origin].unpersist
                         else
                             @origin = details[:origin]
                         end
                     else
                         @origin = nil
                     end
                     #
                     unless details[:destination]
                         raise ArgumentError, "You MUST provide a :destination state for the object."
                     end
                     #
                     if details[:destination].is_a?(::GxG::Database::PersistedHash)
                         @destination = details[:destination].unpersist
                     else
                         @destination = details[:destination]
                     end
                     #
                     if details[:options]
                        @options = {}
                         if details[:options].is_a?(::GxG::Database::PersistedHash)
                             the_options = details[:options].unpersist
                         else
                             the_options = details[:options]
                         end
                         callback_map = {:animationstart => :start, :animationend => :complete, :animationiteration => :update, :animationstop => :stop, :animationpause => :pause, :animationresume => :resume}
                         the_options.each_pair do |the_key, the_value|
                             if callback_map.keys.include?(the_key)
                                 if the_value.respond_to?(:call)
                                     # Expansion: compile formatted hashes of script records ??
                                    @event_handlers[(the_key)] = the_value
                                    @options[(the_key)] = the_value
                                 else
                                     log_warn("Attempted to pass an invalid object as an event handler. #{the_key.inspect} --> #{the_value.inspect}")
                                 end
                             else
                                 @options[(the_key)] = the_value
                             end
                         end
                     else
                         @options = nil
                     end
                     #
                     unless details[:targets]
                         raise ArgumentError, "You MUST provide a one or more :targets."
                     end
                     #
                     if details[:targets].is_a?(::GxG::Database::PersistedHash)
                         @target_list = details[:targets].unpersist
                     else
                         @target_list = details[:targets]
                     end
                 end
                @uuid = (the_uuid || ::GxG::uuid_generate).to_s.to_sym
                @targets = nil
                @tweens = []
                #
                self
            end
            #
            def update_targets(data=nil)
                result = false
                if data.is_any?(::Hash, ::GxG::Database::PersistedHash)
                     if data.is_a?(::GxG::Database::PersistedHash)
                         @target_list = data.unpersist
                     else
                         @target_list = data
                     end
                     result = true
                end
                result
            end
            #
            def update_origin(data=nil)
                result = false
                if data.is_any?(::Hash, ::GxG::Database::PersistedHash)
                     if data.is_a?(::GxG::Database::PersistedHash)
                         @origin = data.unpersist
                     else
                         @origin = data
                     end
                     result = true
                end
                result
            end
            #
            def update_destination(data=nil)
                result = false
                if data.is_any?(::Hash, ::GxG::Database::PersistedHash)
                     if data.is_a?(::GxG::Database::PersistedHash)
                         @destination = data.unpersist
                     else
                         @destination = data
                     end
                     result = true
                end
                result
            end
            #
            def update_options(data=nil)
                result = false
                if data.is_any?(::Hash, ::GxG::Database::PersistedHash)
                     if data.is_a?(::GxG::Database::PersistedHash)
                         the_options = data.unpersist
                     else
                         the_options = data
                     end
                     @options = {}
                     callback_map = {:animationstart => :start, :animationend => :complete, :animationiteration => :update, :animationstop => :stop, :animationpause => :pause, :animationresume => :resume}
                     the_options.each_pair do |the_key, the_value|
                         if callback_map.keys.include?(the_key)
                             if the_value.respond_to?(:call)
                                 # Expansion: compile formatted hashes of script records ??
                                @event_handlers[(the_key)] = the_value
                                @options[(the_key)] = the_value
                             else
                                 log_warn("Attempted to pass an invalid object as an event handler. #{the_key.inspect} --> #{the_value.inspect}")
                             end
                         else
                             @options[(the_key)] = the_value
                         end
                     end
                     result = true
                end
                result
            end
            #
            def uuid()
                @uuid
            end
            #
             def on(the_event_type=nil, captured=false,&block)
                 unless @event_handlers.is_a?(::Hash)
                     @event_handlers = {}
                 end
                 if the_event_type.is_any?(::String, ::Symbol)
                     if block.respond_to?(:call)
                         @event_handlers[(the_event_type.to_s.downcase.to_sym)] = block
                     end
                 end
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
                            # See: https://stackoverflow.com/questions/11547672/how-to-stringify-event-object
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
             def set_script(the_script_body="")
                 result = false
                 if the_script_body.size > 0
                     #
                     begin
                         #
                         if the_script_body.base64?
                             the_script_body = the_script_body.decode64
                         end
                         # 
                         instance_eval(the_script_body)
                         result = true
                     rescue Exception => the_error
                         log_error({:error => the_error, :parameters => {:script => the_script_body}})
                     end
                 end
                 result
             end
             #
            def compile()
                result = false
                begin
                    @targets = []
                    native_targets = `[]`
                    @target_list.keys.each do |the_method|
                        if the_method == :class
                            unless @target_list[:class].is_a?(::String)
                                raise Exception, "You MUST provide :class target as a String, not: #{@target_list[:class].class.inspect}"
                            end
                            @target_list[:class].split(" ").each do |the_classname|
                                if the_classname.size > 0
                                    found_list = `document.getElementsByClassName(#{the_classname})`
                                    found_length = `#{found_list}.length`.to_i
                                    if found_length > 0
                                        (0..(found_length - 1)).each do |the_index|
                                            the_element = `#{found_list}.item(#{the_index})`
                                            unless @targets.include?(the_element)
                                                @targets << the_element
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        #
                         if the_method == :objects
                                # provide a list of UUIDs of components to include as targets
                                unless @target_list[:objects].is_a?(::Array)
                                    raise Exception, "You MUST provide :object target list as an Array, not: #{@target_list[:objects].class.inspect}"
                                end
                                @target_list[:objects].each do |the_reference|
                                    found_object = GxG::DISPLAY_DETAILS[:object].find_object(the_reference.to_s.to_sym)
                                    if found_object
                                        element_id = `#{found_object.element}.attributes.getNamedItem('id') || 0`
                                        unless `#{element_id} == 0`
                                            found_element = `document.getElementById(#{element_id})`
                                            if found_element
                                                unless @targets.include?(found_element)
                                                    @targets << found_element
                                                end
                                            end
                                        end
                                    end
                                end
                         end
                        if the_method == :elements
                            # provide a list of native elements to include as targets
                            unless @target_list[:elements].is_a?(::Array)
                                raise Exception, "You MUST provide :elements target list as an Array, not: #{@target_list[:elements].class.inspect}"
                            end
                            @target_list[:elements].each do |the_element|
                                element_id = `#{the_element}.attributes.getNamedItem('id') || 0`
                                unless `#{element_id} == 0`
                                    element_id = `#{element_id}.value`
                                    found_element = `document.getElementById(#{element_id})`
                                    if found_element
                                        unless @targets.include?(found_element)
                                            @targets << found_element
                                        end
                                    end
                                end
                            end
                        end
                        if the_method == :assets
                            # Future expansion
                        end
                    end
                    # DEBUG:
                    unless @targets.size > 0
                        puts "No valid targets resulted."
                    end
                    @targets.each do |the_element|
                        `#{native_targets}.push(#{the_element})`
                    end
                    #
                     if @origin.is_a?(::Hash)
                        if @origin.size > 0
                            from_state = {}
                            @origin.each_pair do |the_key, the_value|
                                # key translations:
                                if the_key == :attribue || the_key == "attribute"
                                    new_key = :attr
                                else
                                    new_key = the_key
                                end
                                #
                                from_state[(new_key)] = the_value
                            end
                        else
                            from_state = nil
                        end
                    else
                        from_state = nil
                    end
                    #
                     if @destination.size > 0
                        to_state = {}
                        @destination.each_pair do |the_key, the_value|
                            # key translations:
                            if the_key == :attribue || the_key == "attribute"
                                new_key = :attr
                            else
                                new_key = the_key
                            end
                            #
                            to_state[(new_key)] = the_value
                        end
                    else
                        raise Exception, "You MUST define a valid :destination state. not: #{@destination.inspect}"
                    end
                    #
                    if @options.is_a?(::Hash)
                        if @options.size > 0
                            options = {}
                            callback_map = {:animationstart => :start, :animationend => :complete, :animationiteration => :update, :animationstop => :stop, :animationpause => :pause, :animationresume => :resume}
                            @options.each_pair do |the_key, the_value|
                                # Key translations:
                                if callback_map.keys.include?(the_key)
                                    # include handlers
                                    new_key = callback_map[(the_key)]
                                    #
                                    if @event_handlers[(the_key)].respond_to?(:call)
                                        # FIXME
                                        # puts "Setting callback for: #{new_key.inspect}"
                                        options[(new_key)] = @event_handlers[(the_key)]
                                    end
                                else
                                    unless [:start_time].include?(the_key)
                                        # TODO: research ALL options and only allow valid options to be set.
                                        options[(the_key)] = the_value
                                    end
                                end
                            end
                        else
                            options = nil
                        end
                    else
                        options = nil
                    end
                    #
                    @tweens = []
                    # FIXME:
                    # puts "Compiling Options: #{options.inspect}"
                    @targets.each do |the_target|
                        if from_state
                            if options
                                @tweens << `KUTE.fromTo(#{the_target}, #{from_state.to_n}, #{to_state.to_n}, #{options.to_n})`
                            else
                                @tweens << `KUTE.fromTo(#{the_target}, #{from_state.to_n}, #{to_state.to_n})`
                            end
                        else
                            if options
                                @tweens << `KUTE.to(#{the_target},#{to_state.to_n}, #{options.to_n})`
                            else
                                @tweens << `KUTE.to(#{the_target},#{to_state.to_n})`
                            end
                        end
                    end
                    #
                    result = true
                rescue Exception => the_error
                    log_error({:error => the_error})
                    @targets = nil
                    @tweens = []
                end
                result
            end
            #
            def start(the_time=nil)
                unless @tweens.size > 0
                    self.compile
                end
                unless the_time.is_a?(::Numeric)
                    the_time = `window.performance.now()`
                end
                if @tweens.size > 0
                    @tweens.each do |the_tween|
                        `#{the_tween}.start(#{the_time})`
                    end
                end
            end
            #
            def stop()
                if @tweens.size > 0
                    @tweens.each do |the_tween|
                        `#{the_tween}.stop()`
                    end
                end
            end
            #
            def pause()
                if @tweens.size > 0
                    @tweens.each do |the_tween|
                        `#{the_tween}.pause()`
                    end
                end
            end
            #
            def resume()
                if @tweens.size > 0
                    @tweens.each do |the_tween|
                        `#{the_tween}.resume()`
                    end
                end
            end
            #
            def included()
                # return a list of all page components included in this animation
                result = []
                if @targets
                    @targets.each do |the_element|
                        element_id = `#{the_element}.attributes.getNamedItem('id') || 0`
                        unless `#{element_id} == 0`
                            element_id = `#{element_id}.value`
                            found_object = GxG::DISPLAY_DETAILS[:object].find_object_by_id(element_id.to_s)
                            if found_object
                                result << found_object
                            end
                        end
                    end
                end
                result
            end
            #
            def each_included(&block)
                if block.respond_to?(:call)
                    self.included.each do |the_object|
                        block.call(the_object)
                    end
                else
                    self.included.each
                end
            end
            # send events to all target components (not their elements)
            def broadcast(the_method=nil, the_parameters=nil)
                self.each_included do |the_object|
                    the_object.send(the_method, the_parameters)
                end
            end
            #
        end
        #
        module AnimationSupport
            #
            def animate(animation_parameters=nil)
                if animation_parameters[:destination].is_any?(::Hash, ::GxG::Database::PersistedHash)
                    the_animation = ::GxG::Gui::Animation.new({:targets => {:elements => [(self.element)]}, :origin => animation_parameters[:origin], :destination => animation_parameters[:destination], :options => animation_parameters[:options]})
                    start_time = `window.performance.now()`
                    if animation_parameters[:options].is_any?(::Hash, ::GxG::Database::PersistedHash)
                        start_time = animation_parameters[:options][:start_time]
                    end
                    # FIXME:
                    # GxG::ANIMATION[:animations][(the_animation.uuid)] = the_animation
                    #
                    the_animation.compile
                    the_animation.start(start_time)
                    true
                else
                    log_warn("Ignoring invalid animation: NO valid :destination state specified (required). not: #{animation_parameters[:destination].inspect}")
                    false
                end
            end
            # ------------------------------------------------------------------------------
            def show(transition_parameters=nil,&block)
                if transition_parameters.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if transition_parameters.is_a?(::GxG::Database::PersistedHash)
                        transition_parameters = transition_parameters.unpersist
                    end
                    #
                    if transition_parameters[:destination].is_a?(::Hash)
                        if transition_parameters[:destination][:opacity].is_a?(::Numeric)
                            if transition_parameters[:origin].is_a?(::Hash)
                                if transition_parameters[:origin][:opacity].is_a?(::Numeric)
                                    self.gxg_merge_style({:opacity => transition_parameters[:origin][:opacity]})
                                else
                                    self.gxg_merge_style({:opacity => 0})
                                end
                            else
                                self.gxg_merge_style({:opacity => 0})
                            end
                        end
                    end
                    self.gxg_set_state(:hidden, false)
                    if block.respond_to?(:call)
                        unless transition_parameters[:options]
                            transition_parameters[:options] = {}
                        end
                        transition_parameters[:options][:animationend] = Proc.new do
                            block.call()
                        end
                    end
                    #
                    self.animate(transition_parameters)
                else
                    self.gxg_set_state(:hidden, false)
                    if block.respond_to?(:call)
                        block.call()
                    end
                end
                # GxG::DISPLAY_DETAILS[:object].layout_refresh
                true
            end
            #
            def hide(transition_parameters=nil,&block)
                if transition_parameters.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if transition_parameters.is_a?(::GxG::Database::PersistedHash)
                        transition_parameters = transition_parameters.unpersist
                    end
                    if block.respond_to?(:call)
                        unless transition_parameters[:options]
                            transition_parameters[:options] = {}
                        end
                        transition_parameters[:options][:animationend] = Proc.new do
                            self.gxg_set_state(:hidden, true)
                            block.call()
                        end
                    else
                        set_state = nil
                        if transition_parameters[:options]
                            if transition_parameters[:options][:animationend].respond_to?(:call)
                                old_complete = transition_parameters[:options][:animationend]
                                set_state = Proc.new do
                                   old_complete.call()
                                    self.gxg_set_state(:hidden, true)
                                end
                            else
                                set_state = Proc.new do
                                    self.gxg_set_state(:hidden, true)
                                end
                            end
                        else
                            transition_parameters[:options] = {}
                            set_state = Proc.new do
                                self.gxg_set_state(:hidden, true)
                            end
                        end
                        if set_state
                            unless transition_parameters[:options].is_a?(::Hash)
                                transition_parameters[:options] = {}
                            end
                            transition_parameters[:options][:animationend] = set_state
                        end
                    end
                    #
                    self.animate(transition_parameters)
                else
                    self.gxg_set_state(:hidden, true)
                    if block.respond_to?(:call)
                        block.call()
                    end
                end
                # GxG::DISPLAY_DETAILS[:object].layout_refresh
                true
            end
            #
        end
        # --------------------------------------------------------------------------------------------------------------------------------------
        module ApplicationSupport
            #
            def find_parent_type(the_type=nil)
                # return the first parent of type: the_type (Class, String, Symbol)
                result = nil
                if the_type.is_any?(::Class, ::String, ::Symbol)
                    if the_type.is_any?(::String, ::Symbol)
                        the_type = GxG::Gui::component_class(the_type.to_s.to_sym)
                    end
                    if the_type.is_a?(::Class)
                        search_queue = [(self)]
                        while search_queue.size > 0 do
                            entry = search_queue.shift
                            if entry
                                if entry.is_a?(the_type)
                                    result = entry
                                    break
                                end
                                search_queue << entry.parent
                            end
                        end
                    end
                end
                result
            end
            # deprecated - switch over to find_parent_type (eventually)
            def viewport()
                # find nearest viewport in object heirarchy.
                self.find_parent_type(::GxG::Gui::ApplicationViewport)
            end
            #
            def tree_node()
                # find nearest :tree_node parent in object heirarchy.
                self.find_parent_type(::GxG::Gui::TreeNode)
            end
            #
            def tree()
                # find nearest :tree parent in object heirarchy.
                self.find_parent_type(::GxG::Gui::Tree)
            end
            #
            def window()
                # find nearest window in object heirarchy.
                self.find_parent_type(::GxG::Gui::Window)
            end
            #
            def find_parent(the_reference=nil)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                search_queue = [(self.parent)]
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            search_queue << entry.parent
                        end
                    end
                end
                result
            end
            #
            def find_child_type(the_type=nil)
                # return the first parent of type: the_type (Class, String, Symbol)
                result = nil
                if the_type.is_any?(::Class, ::String, ::Symbol)
                    if the_type.is_any?(::String, ::Symbol)
                        the_type = GxG::Gui::component_class(the_type.to_s.to_sym)
                    end
                    if the_type.is_a?(::Class)
                        search_queue = self.children.values
                        while search_queue.size > 0 do
                            entry = search_queue.shift
                            if entry
                                if entry.is_a?(the_type)
                                    result = entry
                                    break
                                end
                            end
                        end
                    end
                end
                result
            end
            #
            def find_child(the_reference=nil)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                search_queue = self.children.values
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def build_interior_components(build_list=[])
                # You get ONE @content 'internal_component' (for now).
                build_queue = [{:parent => nil, :record => {:content => build_list}, :element => self}]
                while build_queue.size > 0 do
                    entry = build_queue.shift
                    if entry
                        if entry[:record][:content].size > 0
                            entry[:record][:content].each do |sub_component|
                                element_class = GxG::Gui::component_class(sub_component[:component].to_s.to_sym)
                                if element_class
                                    if sub_component.is_a?(::GxG::Database::PersistedHash)
                                        the_options = sub_component[:options].unpersist()
                                        the_uuid = sub_component.uuid.to_s.to_sym
                                        if the_options[:title]
                                            the_title = the_options.delete(:title)
                                        else
                                            the_title = sub_component.title.to_s
                                        end
                                    else
                                        the_options = sub_component[:options].clone
                                        the_uuid = ::GxG::uuid_generate.to_sym
                                        if the_options[:title]
                                            the_title = the_options.delete(:title)
                                        else
                                            the_title = "Untitled Component #{the_uuid.to_s}"
                                        end
                                    end
                                    #
                                    the_style = the_options.delete(:style)
                                    the_states = (the_options.delete(:states) || {})
                                    the_options[:uuid] = the_uuid
                                    if the_options[:track]
                                        tracking = the_options.delete(:track)
                                    else
                                        tracking = nil
                                    end
                                    if entry[:element] == self
                                        if entry[:element].respond_to?(:original_add_child)
                                            new_entry = {:parent => entry[:element], :record => sub_component, :element => entry[:element].original_add_child((the_uuid), element_class, the_options)}
                                        else
                                            new_entry = {:parent => entry[:element], :record => sub_component, :element => entry[:element].add_child((the_uuid), element_class, the_options)}
                                        end
                                    else
                                        new_entry = {:parent => entry[:element], :record => sub_component, :element => entry[:element].add_child((the_uuid), element_class, the_options)}
                                    end
                                    if the_title == "interior_component"
                                        @content = new_entry[:element]
                                    else
                                        new_entry[:element].set_title(the_title)
                                    end
                                    # Window component tracking:
                                    if tracking
                                        the_window = new_entry[:element].window()
                                        if the_window
                                            the_window.track_deltas(the_uuid,new_entry[:element],tracking)
                                        end
                                    end
                                    # Set states:
                                    unless the_states.keys.include?(:hidden)
                                        the_states[:hidden] = false
                                    end
                                    new_entry[:element].gxg_set_states(the_states)
                                    # process style info:
                                    if the_style.is_a?(::Hash)
                                        new_entry[:element].gxg_set_style(the_style)
                                    end
                                    #
                                    # Set Script if any is provided
                                    if sub_component[:script].size > 0
                                        new_entry[:element].set_script(sub_component[:script].to_s)
                                    end
                                    build_queue << new_entry
                                end
                            end
                        end
                    end
                end
                #
            end
            #
        end
        # --------------------------------------------------------------------------------------------------------------------------------------
        module ThemeSupport
            def page()
                GxG::DISPLAY_DETAILS[:object]
            end
            def theme_icon(image_name=nil)
                GxG::DISPLAY_DETAILS[:object].theme_icon(image_name)
            end
            #
            def theme_background(image_name=nil)
                GxG::DISPLAY_DETAILS[:object].theme_background(image_name)
            end
            #
            def theme_widget(image_name=nil)
                GxG::DISPLAY_DETAILS[:object].theme_widget(image_name)
            end
            #
            def theme_font(font_name=nil)
                GxG::DISPLAY_DETAILS[:object].theme_font(font_name)
            end
            # Asset retrieval support:
            def site_asset(asset_path=nil)
                GxG::DISPLAY_DETAILS[:object].site_asset(asset_path)
            end
        end
        # --------------------------------------------------------------------------------------------------------------------------------------
        # Page objects and components:
         # ### Components
        # Universal to all components and elements: 
        # 
        # Override this method to return a Hash of styles.
        # Hash-key is the CSS style name, hash-value is the CSS style value.
        #    def style;end
         class Component < ::Ferro::Component::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Header < ::Ferro::Component::Header
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Navigator < ::Ferro::Component::Navigation
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Section < ::Ferro::Component::Section
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Article < ::Ferro::Component::Article
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Aside < ::Ferro::Component::Aside
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Footer < ::Ferro::Component::Footer
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         # ### Forms
         #
         class Form < ::Ferro::Form::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
             def form_data()
                result = {}
                search_queue = self.children.values
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if entry.domtype == :input
                            result[(entry.title.to_s.to_sym)] = entry.value()
                        else
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
             end
         end
         #
         class Clickable < ::Ferro::Form::Clickable
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             ## Override this method to define what happens after
             # element has been clicked.
             # def clicked;end
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
         end
         #
         class Fieldset < ::Ferro::Form::Fieldset
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Input < ::Ferro::Form::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
            end
            #
            def uuid()
                @uuid
            end
            #
             # Creates an input element.
             # In the DOM creates a: <input type="?">.
             # Specify option :type to set the location.
             # Use one of these values:
             # :text, :password, :reset, :radio, :checkbox, :color,
             # :date, :datetime-local, :email, :month, :number,
             # :range, :search, :tel, :time, :url, :week.
             # Or leave blank to create a :text input.
            #              def _before_create
            #                @options[:type] = :text
            #                super
            #              end
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
         end
         #
         class TextInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :text
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class PasswordInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :password
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class ResetInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :reset
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class RadioButton < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :radio
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class ColorPicker < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :color
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class DatePicker < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :date
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class DateTimeLocal < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :"datetime-local"
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class EmailInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :email
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class MonthPicker < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :month
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class NumberInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :number
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class RangeInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :range
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class SearchInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :search
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class PhoneInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :tel
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class TimePicker < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :time
            end
            #
            def uuid()
                @uuid
            end
            #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class UrlInput < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :url
            end
            #
            def uuid()
                @uuid
            end
            #
              #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             #
         end
         #
         class WeekPicker < ::GxG::Gui::Input
            #
            def _before_create
                super()
                @domtype = :input
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @options[:type] = :week
            end
            #
            def uuid()
                @uuid
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            #
         end
         #
         class Label < ::Ferro::Form::Label
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class TextArea < ::Ferro::Form::Textarea
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Output < ::Ferro::Form::Output
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class ButtonInput < ::Ferro::Form::Button
            #
            def disable()
                @enabled = false
                self.gxg_set_attribute(:disabled)
            end
            #
            def enable()
                @enabled = true
                self.gxg_clear_attribute(:disabled)
            end
            #
            def enabled?()
                @enabled || false
            end
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @enabled = @options.delete(:enabled)
                unless @enabled == false
                    @enabled = true
                end
                super()
            end
            #
            def _after_create
                if @enabled == true
                    self.enable
                else
                    self.disable
                end
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class SubmitButton < ::Ferro::Form::Submit
            #
            def disable()
                @enabled = false
                self.gxg_set_attribute(:disabled)
            end
            #
            def enable()
                @enabled = true
                self.gxg_clear_attribute(:disabled)
            end
            #
            def enabled?()
                @enabled || false
            end
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @enabled = @options.delete(:enabled)
                unless @enabled == false
                    @enabled = true
                end
                super()
            end
            #
            def _after_create
                if @enabled == true
                    self.enable
                else
                    self.disable
                end
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class ClickBlock < ::Ferro::Form::Block
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             ## Override this method to define what happens after
             # element has been clicked.
             # def clicked;end
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
         end
         #
         class CheckBox < ::Ferro::Form::CheckBox
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
             def is_set?()
                # sleep 0.5
                if (`#{self.element}.checked == true`)
                    true
                else
                    false
                end
             end
             #
             def set(the_state=false)
                if the_state == true
                    `#{self.element}.checked = true`
                else
                    `#{self.element}.checked = false`
                end
                self.is_set?()
             end
             #
         end
         #
         class Selector < ::Ferro::Form::Select
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         # ### Inline Elements
         #
         class Block < ::Ferro::Element::Block
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Text < ::Ferro::Element::Text
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class List < ::Ferro::Element::List
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
             def initialize(the_name,the_class,the_options={})
                #
                @items = []
                # Item: {:icon => "<src>", :icon_width => 32, :icon_height => 32, :label => "", :uuid => "<uuid>"}
                @selection = nil
                @select_responder = nil
                @open_responder = nil
                #
                super(the_name, the_class, the_options)
                self
             end
             #
             def set_selection(uuid=nil)
                @selection = uuid
                self.children.values.each do |the_item|
                    if the_item.gxg_get_attribute('item-uuid') == uuid
                        the_item.select
                    else
                        the_item.unselect
                    end
                end
                uuid
             end
             #
             def selection()
                @selection
             end
             #
             def set_select_responder(&block)
                if block.respond_to?(:call)
                    @select_responder = block
                end
             end
             #
             def invoke_select_responder()
                if @select_responder.respond_to?(:call)
                    @select_responder.call(@selection)
                end
             end
             #
             def set_open_responder(&block)
                if block.respond_to?(:call)
                    @open_responder = block
                end
             end
             #
             def invoke_open_responder()
                if @open_responder.respond_to?(:call)
                    @open_responder.call(@selection)
                end
             end
             #
             #
             def add_list_item(item_details={})
                build_list = []
                #
                if item_details[:row_style].is_a?(::Hash)
                    item_row = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px"}.merge(item_details[:row_style])}, :content=>[], :script=>""}
                else
                    item_row = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px"}}, :content=>[], :script=>""}
                end
                if item_details[:icon]
                    icon_width = (item_details[:icon_width] || 32).to_i
                    icon_height = (item_details[:icon_height] || 32).to_i
                    item_icon = {:component=>"image", :options=>{:src=>(item_details[:icon]), :width=>icon_width, :height=>icon_height, :style => {:clear => "both"}}, :content=>[], :script=>""}
                    item_row[:content] << {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle"}}, :content => [(item_icon)], :script => ""}
                end
                if item_details[:label].to_s.size > 0
                    item_label = {:component=>"text", :options=> {:content => (item_details[:label].to_s), :style => {:padding => "0px 0px 2px 0px", :"font-size" => "16px"}}, :content => [], :script => ""}
                    if item_details[:label_cell_style].is_a?(::Hash)
                        item_row[:content] << {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle"}.merge(item_details[:label_cell_style])}, :content => [(item_label)], :script => ""}
                    else
                        item_row[:content] << {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle"}}, :content => [(item_label)], :script => ""}
                    end
                end
                if item_details[:content].is_any?(::Array, ::GxG::Database::PersistedArray)
                    if item_details[:content].size > 0
                        item_details[:content].each do |the_component|
                            item_row[:content] << {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px"}}, :content => [(the_component)], :script => ""}
                        end
                    end
                end
                item_table = {:component=>"block_table", :options=>{:"item-uuid" => (item_details[:uuid].to_s), :style => {:padding => "0px", :margin => "0px"}}, :content=>[(item_row)], :script=>""}
                item_table[:script] = "
                def select()
                    @selected = true
                    self.gxg_merge_style({:'background-color' => '#87acd5'})
                end
                def unselect()
                    @selected = false
                    self.gxg_merge_style({:'background-color' => '#f2f2f2'})
                end
                on(:dblclick) do |event|
                    parent.set_selection(self.gxg_get_attribute('item-uuid'))
                    parent.invoke_open_responder()
                end
                on(:mouseup) do |event|
                    parent.set_selection(self.gxg_get_attribute('item-uuid'))
                    parent.invoke_select_responder()
                end
                "
                #
                build_list << item_table
                #
                @items << item_details
                self.build_interior_components(build_list)
             end
         end
         #
         class OrderedList < ::Ferro::Element::List
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
                @domtype = "ol"
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class ListItem < ::Ferro::Element::ListItem
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Anchor < ::Ferro::Element::Anchor
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class ExternalLink < ::Ferro::Element::ExternalLink
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Button < ::Ferro::Element::Button
            # TODO: flesh out enable/disable methods for RadioButton and CheckBox as well.
            def disable()
                @enabled = false
                self.gxg_set_attribute(:disabled)
            end
            #
            def enable()
                @enabled = true
                self.gxg_clear_attribute(:disabled)
            end
            #
            def enabled?()
                @enabled || false
            end
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                @enabled = @options.delete(:enabled)
                unless @enabled == false
                    @enabled = true
                end
                super()
            end
            #
            def _after_create
                if @enabled == true
                    self.enable
                else
                    self.disable
                end
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         # ### Misc. Elements
         #
         class Image < ::Ferro::Element::Image
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Video < ::Ferro::Element::Video
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Canvas < ::Ferro::Element::Canvas
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             #
             include GxG::Gui::EventHandlers
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
             #
         end
         #
         class Table < ::Ferro::Component::Base
            #
            def _before_create
                @domtype = :table
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
        end
        #
        class TableHeader < ::Ferro::Component::Base
            def _before_create
                @domtype = :th
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
           #
           include GxG::Gui::EventHandlers
           include GxG::Gui::AnimationSupport
           include GxG::Gui::ApplicationSupport
           include GxG::Gui::ThemeSupport
           #
        end
        #
        class TableRow < ::Ferro::Component::Base
            def _before_create
                @domtype = :tr
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
        end
        #
        class TableCell < ::Ferro::Component::Base
            #
            def _before_create
                @domtype = :td
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
        end
        #
        class BlockTable < ::Ferro::Component::Base
            #
            def _before_create
                @states = {:table => true}
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
        end
        #
        class BlockTableHeader < ::Ferro::Component::Base
            #
           def _before_create
               @states = {:th => true}
               if @options[:uuid]
                   @uuid = @options.delete(:uuid).to_s.to_sym
               end
               super()
           end
           #
           def uuid()
               @uuid
           end
           #
           #
           include GxG::Gui::EventHandlers
           include GxG::Gui::AnimationSupport
           include GxG::Gui::ApplicationSupport
           include GxG::Gui::ThemeSupport
           #
        end
        #
        class BlockTableRow < ::Ferro::Component::Base
            #
            def _before_create
                @states = {:tr => true}
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
        end
        #
        class BlockTableCell < ::Ferro::Component::Base
            def _before_create
                @states = {:td => true}
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
        end
        #
        class Script < ::Ferro::Element::Script
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             #
             include GxG::Gui::EventHandlers
             #
        end
        #
        class Tree < ::Ferro::Component::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
            alias :original_add_child :add_child
            def add_child(name, element_class, options = {})
                if element_class == GxG::Gui::TreeNode
                    if @content
                        @content.add_child(name, element_class, options)
                    end
                else
                    log_warn("Attempted to add a non-TreeNode object - ignoring: #{element_class.inspect}")
                end
            end
            #
            alias :original_children :children
            def children()
                if @content
                    @content.children
                else
                    {}
                end
            end
            #
            def find_child(the_reference=nil, interior=false)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                if interior == true
                    search_queue = self.original_children.values
                else
                    search_queue = self.children.values
                end
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def initialize(the_name,the_class,the_options)
                @content = nil
                @selection = nil
                @processors = {}
                super(the_name, the_class, the_options)
                self
            end
            #
            def cascade()
                #
                self.build_interior_components([{:component=>"list", :options=>{:title => "interior_component", :style => {:"white-space" => "nowrap", :width => "auto", :height => "auto", :"list-style" => "none", :margin => "0px", :padding => "0px"}}, :content=>[], :script=>""}])
                #
            end
            #
            def update_appearance()
                # TODO ??
            end
            # Selection / Processing:
            def set_processor(the_type=nil, &block)
                # :select, :expand, :collapse
                if block.respond_to?(:call)
                    if [:select, :expand, :collapse].include?(the_type.to_s.to_sym)
                        @processors[(the_type.to_s.to_sym)] = block
                    else
                        log_warn("Unsupported processor type: #{the_type.to_s.to_sym.inspect}")
                    end
                end
            end
            #
            def node_at_path(the_path=nil)
                result = nil
                search_queue = self.children.values.clone
                while search_queue.size > 0
                    entry = search_queue.shift
                    if entry.is_a?(GxG::Gui::TreeNode)
                        if entry.node_path() == the_path
                            result = entry
                            break
                        else
                            entry.nodes.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def expand_path(the_path=nil,&block)
                if the_path.is_a?(::String)
                    path_stack = []
                    path_array = the_path.split("/")
                    path_array.each do |entry|
                        if entry.size > 0
                            path_stack << entry
                            the_node = self.node_at_path(('/' + path_stack.join("/")))
                            if the_node.is_a?(GxG::Gui::TreeNode)
                                if the_node.gxg_get_state(:expanded) == false
                                    the_node.expand()
                                    GxG::DISPATCHER.post_event(:display) do
                                        self.expand_path(the_path,&block)
                                    end
                                    break
                                end
                                if the_node.node_path() == the_path
                                    if block.respond_to?(:call)
                                        block.call()
                                    end
                                end
                            else
                                GxG::DISPATCHER.post_event(:display) do
                                    self.expand_path(the_path,&block)
                                end
                                break
                            end
                        end
                    end
                end
                true
            end
            #
            def selection()
                @selection
            end
            #
            def select(the_node=nil)
                if the_node.is_a?(GxG::Gui::TreeNode)
                    if @selection != the_node
                        if @selection
                            @selection.unhighlight()
                        end
                        @selection = the_node
                        @selection.highlight()
                        # TODO: scroll to reveal highlighted node ??
                        if @processors[:select].respond_to?(:call)
                            @processors[:select].call(@selection)
                        end
                    end
                end
            end
            #
            def expand(the_node=nil)
                if the_node.is_a?(GxG::Gui::TreeNode)
                    if @processors[:expand].respond_to?(:call)
                        @processors[:expand].call(the_node)
                    end
                end
            end
            #
            def collapse(the_node=nil)
                if the_node.is_a?(GxG::Gui::TreeNode)
                    if @processors[:collapse].respond_to?(:call)
                        @processors[:collapse].call(the_node)
                    end
                end
            end
         end
         #
         class TreeNode < ::Ferro::Element::ListItem
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                if @data.is_a?(::Hash)
                    if @data[:title]
                        @title = @data[:title]
                    end
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
            alias :original_add_child :add_child
            def add_child(name, element_class, options = {})
                if element_class == GxG::Gui::TreeNode
                    if @content
                        @content.add_child(name, element_class, options)
                    end
                else
                    self.original_add_child(name, element_class, options)
                end
            end
            #
            def nodes()
                if @content
                    @content.children
                else
                    {}
                end
            end
            #
            def node_path()
                the_path = ""
                lineage = [(self)]
                the_parent = self.parent
                while the_parent != nil do
                    if the_parent.is_a?(GxG::Gui::TreeNode)
                        lineage.unshift(the_parent)
                    end
                    the_parent = the_parent.parent
                    if the_parent.is_a?(GxG::Gui::Tree)
                        the_parent = nil
                    end
                end
                lineage.each do |the_node|
                    the_path = the_path + "/#{the_node.title}"
                end
                the_path
            end
            #
            def find_child(the_reference=nil)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                search_queue = self.children.values
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def update_appearance()
                if @appearance.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    #
                    # TODO: update icon and label if different ??
                    #
                    # @icon, @label component objects available.
                    true
                else
                    false
                end
            end
            #
            def data()
                @data
            end
            #
            def appearance()
                @appearance
            end
            #
            def set_appearance(the_record=nil)
                if the_record.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    @appearance = the_record
                    # Look for :label, :icon w/in the hash record w/in the array.
                    self.update_appearance()
                end
            end
            #
            def initialize(the_name,the_class,the_options={})
                @content = nil
                @appearance = {:icon => GxG::DISPLAY_DETAILS[:object].theme_icon("folder.svg"), :label => "Untitled"}
                if the_options.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if the_options.is_a?(::GxG::Database::PersistedHash)
                        the_options = the_options.unpersist
                    else
                        the_options = the_options.clone
                    end
                    # Pass an Hash record containing at LEAST: :title, :type, and :content.
                    @data = (the_options.delete(:data) || {:title => "Untitled", :type => "virtual_directory", :content => {}})
                    # select proper icon for @data[:type] value ?? (do in application!)
                    @appearance[:icon] = (the_options.delete(:icon) || GxG::DISPLAY_DETAILS[:object].theme_icon("folder.svg")).to_s
                    @appearance[:label] = (the_options.delete(:label) || @data[:title]).to_s
                end
                super(the_name, the_class, the_options)
                self
            end
            #
            def cascade()
                #
                node_frame = {:component=>"block_table", :options=>{:nodepath => (self.node_path()), :style => {}}, :content=>[], :script=>""}
                #
                frame_row_one = {:component=>"block_table_row", :options=>{}, :content=>[], :script=>""}
                expander_object_title = "Object #{::GxG::uuid_generate.to_s}"
                expander = {:component=>"image", :options=>{:title => (expander_object_title), :src=>(GxG::DISPLAY_DETAILS[:object].theme_widget("collapse.svg")), :width=>32, :height=>32, :style => {:clear => "both", :'vertical-align' => 'middle'}}, :content=>[], :script=>""}
                expander[:script] = "
                on(:mouseup) do |event|
                    the_node = self.tree_node()
                    if the_node
                        unless the_node.gxg_get_state(:disabled) == true
                            if self.gxg_get_state(:expanded) == true
                                self.gxg_set_attribute(:src, GxG::DISPLAY_DETAILS[:object].theme_widget('collapse.svg'))
                                self.gxg_set_state(:expanded,false)
                                the_node.collapse()
                            else
                                self.gxg_set_attribute(:src, GxG::DISPLAY_DETAILS[:object].theme_widget('expand.svg'))
                                self.gxg_set_state(:expanded,true)
                                the_node.expand()
                            end
                        end
                    end
                end
                "
                node_expander_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :width => "32px", :'vertical-align' => 'middle'}}, :content=>[], :script=>""}
                node_expander_cell[:content] = [(expander)]
                #
                icon_object_title = "Object #{::GxG::uuid_generate.to_s}"
                icon = {:component=>"image", :options=>{:title => (icon_object_title), :src=>@appearance[:icon], :style => {:clear => "both", :width=>"32px", :height=>"32px", :'vertical-align' => 'middle'}}, :content=>[], :script=>""}
                icon[:script] = "
                on(:mouseup) do |event|
                    the_node = self.tree_node()
                    if the_node
                        the_tree = the_node.tree()
                        if the_tree
                            the_tree.select(the_node)
                        end
                    end
                end
                "
                node_icon_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :width => "32px", :'vertical-align' => 'middle'}}, :content=>[], :script=>""}
                node_icon_cell[:content] = [(icon)]
                #
                title_object_title = "Object #{::GxG::uuid_generate.to_s}"
                title = {:component=>'label', :options=>{:title => (title_object_title), :content => @appearance[:label], :style => {:float => "left", :'font-size' => '16px', :'vertical-align' => 'middle', :'text-align' => 'left', :margin => "2px", :padding => "2px"}}, :content=>[], :script=>''}
                title[:script] = "
                on(:mouseup) do |event|
                    the_node = self.tree_node()
                    if the_node
                        the_tree = the_node.tree()
                        if the_tree
                            the_tree.select(the_node)
                        end
                    end
                end
                "
                node_label_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :'vertical-align' => 'middle'}}, :content=>[], :script=>""}
                node_label_cell[:content] = [(title)]
                #
                # frame_row_one[:content] = [(node_indent_cell),(node_expander_cell), (node_icon_cell), (node_label_cell)]
                frame_row_one[:content] = [(node_expander_cell), (node_icon_cell), (node_label_cell)]
                frame_row_one[:script] = "
                on(:mouseenter) do |event|
                    the_node = self.tree_node()
                    if the_node
                        the_tree = the_node.highlight()
                    end
                end
                on(:mouseleave) do |event|
                    the_node = self.tree_node()
                    if the_node
                        the_tree = the_node.unhighlight()
                    end
                end
                "
                #
                sublist_object_title = "Object #{::GxG::uuid_generate.to_s}"
                sublist = {:component=>"list", :options=>{:title => "interior_component", :width => "100%", :height => "100%", :style => {:"list-style" => "none"}}, :content=>[], :script=>""}
                #
                subnodes_frame_cell = {:component=>"block_table_cell", :options=>{}, :content=>[], :script=>""}
                frame_row_two = {:component=>"block_table_row", :options=>{}, :content=>[], :script=>""}
                subnodes_frame_cell[:content] = [(sublist)]
                # frame_row_two[:content] = [(subnodes_indent_cell),(subnodes_frame_cell)]
                frame_row_two[:content] = [(subnodes_frame_cell)]
                #
                node_frame[:content] = [(frame_row_one),(frame_row_two)]
                #
                self.build_interior_components([(node_frame)])
                #
                # Review: content or sublist ??
                # @content = self.find_child(sublist_object_title)
                @expander = self.find_child(expander_object_title)
                @icon = self.find_child(icon_object_title)
                @label = self.find_child(title_object_title)
                #
            end
            # TODO: Add animation / transition effects.
            def highlight(transition_parameters=nil)
                if @label
                    @label.gxg_merge_style({:'background-color' => '#87acd5'})
                end
            end
            #
            def unhighlight(transition_parameters=nil)
                if @label
                    @label.gxg_merge_style({:'background-color' => '#f2f2f2'})
                end
            end
            #
            def expand(transition_parameters=nil)
                @content.show(transition_parameters)
                self.gxg_set_state(:expanded, true)
                if @expander
                    @expander.gxg_set_attribute(:src,GxG::DISPLAY_DETAILS[:object].theme_widget("expand.svg"))
                end
                the_tree = self.tree()
                if the_tree
                    the_tree.expand(self)
                end
            end
            #
            def collapse(transition_parameters=nil)
                @content.hide(transition_parameters)
                self.gxg_set_state(:expanded, false)
                if @expander
                    @expander.gxg_set_attribute(:src,GxG::DISPLAY_DETAILS[:object].theme_widget("collapse.svg"))
                end
                the_tree = self.tree()
                if the_tree
                    the_tree.collapse(self)
                end
            end
            #
            def enable(transition_parameters=nil)
                if transition_parameters.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if transition_parameters.is_a?(::GxG::Database::PersistedHash)
                        transition_parameters = transition_parameters.unpersist
                    end
                else
                    transition_parameters = {:origin => {:opacity => 0.5}, :destination => {:opacity => 1.0}}
                end
                self.children.each_pair do |name, object|
                    unless name == :interior_component
                        object.gxg_set_state(:disabled, false)
                        object.animate(transition_parameters)
                    end
                end
            end
            #
            def disable(transition_parameters=nil)
                if transition_parameters.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if transition_parameters.is_a?(::GxG::Database::PersistedHash)
                        transition_parameters = transition_parameters.unpersist
                    end
                else
                    transition_parameters = {:origin => {:opacity => 1.0}, :destination => {:opacity => 0.5}}
                end
                self.children.each_pair do |name, object|
                    unless name == :interior_component
                        object.animate(transition_parameters)
                        object.gxg_set_state(:disabled, true)
                    end
                end
            end
            #
         end
         #
        class Panel < ::Ferro::Component::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
            #
            def cascade
                super()
                GxG::DISPLAY_DETAILS[:object].layout_refresh
            end
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            # TODO: Add auto-hide/hide/roll up-left-down-right capabilites with animations.
            # ????
        end
        #
        class ApplicationViewport < ::Ferro::Component::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
            #
            def uuid()
                @uuid
            end
            #
            def set_application(the_application)
                @application = the_application
            end
            #
            def application()
                @application
            end
            #
            def find_child(the_reference=nil)
                result = nil
                if the_reference
                    search_queue = [(self)]
                    while search_queue.size > 0 do
                        entry = search_queue.shift
                        if entry
                            if GxG::valid_uuid?(the_reference)
                                if entry.children[(object_source.uuid())]
                                    result = entry.children[(object_source.uuid())]
                                    break
                                else
                                    entry.gxg_each_child do |the_child|
                                        search_queue << the_child
                                    end
                                end
                            else
                                entry.gxg_each_child do |the_child|
                                    if the_child.title == the_reference
                                        result = the_child
                                        break
                                    else
                                        search_queue << the_child
                                    end
                                end
                            end
                        end
                    end
                end
                result
            end
        end
        #
        class Window < ::Ferro::Component::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
            def uuid()
                @uuid
            end
            # Methods to override in window's script
            def before_close(data=nil)
            end
            #
            def close(data=nil)
            end
            #
            def after_close(data=nil)
            end
            #
            def before_open(data=nil)
            end
            #
            def open(data=nil)
            end
            #
            def after_open(data=nil)
            end
            #
            def set_application(the_application)
                @application = the_application
            end
            #
            def application()
                @application
            end
            #
            # Support methods:
            def commit_settings()
                # conform to layout restrictions:
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                # convert to % ??
                top_percent = (@top.to_f / bounds[:page_height].to_f) * 100.0
                left_percent = (@left.to_f / bounds[:page_width].to_f) * 100.0
                height_percent = (self.height.to_f / bounds[:page_height].to_f) * 100.0
                width_percent = (self.width.to_f / bounds[:page_width].to_f) * 100.0
                #
                setting = {}
                #
                setting[:position] = "absolute"
                setting[:display] = "block"
                # setting[:overflow] = "hidden"
                setting[:tabindex] = -1
                setting[:top] = "#{top_percent}%"
                setting[:left] = "#{left_percent}%"
                setting[:height] = "#{height_percent}%"
                setting[:width] = "#{width_percent}%"
                #
                self.gxg_merge_style(setting)
                if @title_object
                    @title_object.parent.gxg_merge_style({:padding => "0px 0px 0px #{((self.width() / 2) - ((@window_title.size / 2) * 8)) - 60}px"})
                end
                if @content
                    @content.gxg_merge_style({:height => "#{self.height - (@title_margin + @menu_margin + @resize_margin)}px", :width => "#{self.width - (@resize_margin * 2)}px"})
                    # update tracking objects
                    @tracking.each_pair do |selector, record|
                        new_style = {}
                        #
                        record[:details].each_pair do |op,value|
                            case op.to_s.to_sym
                            when :width
                                if value.to_s.include?("%")
                                    # convert this % to px value width in new_style
                                    new_style[:width] = (((value.to_s.gsub("%","").to_f / 100.0) * (self.width - (@resize_margin * 2)).to_f).to_i.to_s + "px")
                                else
                                    # assume numeric px value
                                    new_style[:width] = "#{value.to_s}px"
                                end
                            when :height
                                if value.to_s.include?("%")
                                    # convert this % to px value width in new_style
                                    new_style[:height] = (((value.to_s.gsub("%","").to_f / 100.0) * (self.height - (@title_margin + @menu_margin + @resize_margin)).to_f).to_i.to_s + "px")
                                else
                                    # assume numeric px value
                                    new_style[:height] = "#{value.to_s}px"
                                end
                            end
                        end
                        #
                        record[:object].gxg_merge_style(new_style)
                    end
                end
                if @menu_bar
                    @menu_area.gxg_merge_style({:width => "#{self.width - (@resize_margin * 2)}px"})
                    # @menu_bar.gxg_merge_style({:width => "100%"})
                    if @menu_bar.respond_to?(:update_appearance)
                        @menu_bar.update_appearance()
                    end
                end
            end
            #
            def track_deltas(the_reference=nil, the_object=nil, details={})
                if the_reference && the_object && details.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    @tracking[(the_reference)] = {:object => the_object, :details => details}
                    true
                else
                    false
                end
            end
            def untrack_deltas(the_reference=nil)
                if the_reference
                    @tracking.delete(the_reference)
                    true
                else
                    false
                end
            end
            #
            def content()
                @content
            end
            #
            def content_width()
                if @content
                    (`#{@content.element}.getBoundingClientRect().right - #{@content.element}.getBoundingClientRect().left`).to_i
                else
                    0
                end
            end
            #
            def content_height()
                if @content
                    (`#{@content.element}.getBoundingClientRect().bottom - #{@content.element}.getBoundingClientRect().top`).to_i
                else
                    0
                end
            end
            #
            def set_top(the_top=nil)
                if the_top.is_a?(::Numeric)
                    if @bottom - the_top >= 100
                        if the_top >= GxG::DISPLAY_DETAILS[:object].layout_content_area()[:top]
                            @top = the_top
                            self.fit_within_boundaries()
                            commit_settings
                        end
                    end
                end
            end
            #
            def top()
                @top
            end
            #
            def set_left(the_left=nil)
                if the_left.is_a?(::Numeric)
                    if @right - the_left >= 200
                        if the_left >= GxG::DISPLAY_DETAILS[:object].layout_content_area()[:left]
                            @left = the_left
                            self.fit_within_boundaries()
                            commit_settings
                        end
                    end
                end
            end
            #
            def left()
                @left
            end
            #
            def set_right(the_right=nil)
                if the_right.is_a?(::Numeric)
                    if the_right - @left >= 200
                        if the_right <= GxG::DISPLAY_DETAILS[:object].layout_content_area()[:right]
                            @right = the_right
                            self.fit_within_boundaries()
                            commit_settings
                        end
                    end
                end
            end
            #
            def right()
                @right
            end
            #
            def set_bottom(the_bottom=nil)
                if the_bottom.is_a?(::Numeric)
                    if the_bottom - @top >= 100
                        if the_bottom <= GxG::DISPLAY_DETAILS[:object].layout_content_area()[:bottom]
                            @bottom = the_bottom
                            self.fit_within_boundaries()
                            commit_settings
                        end
                    end
                end
            end
            #
            def bottom()
                @bottom
            end
            #
            def set_width(the_width=nil)
                if the_width.is_a?(::Numeric)
                    if the_width >= 200
                        if (@left + the_width) <= GxG::DISPLAY_DETAILS[:object].layout_content_area()[:right]
                            @right = (@left + the_width)
                            self.fit_within_boundaries()
                            commit_settings
                        end
                    end
                end
            end
            #
            def width()
                (@right - @left)
            end
            #
            def set_height(the_height=nil)
                if the_height.is_a?(::Numeric)
                    if the_height >= 100
                        if (@top + the_height) <= GxG::DISPLAY_DETAILS[:object].layout_content_area()[:bottom]
                            @bottom = (@top + the_height)
                            self.fit_within_boundaries()
                            commit_settings
                        end
                    end
                end
            end
            #
            def height()
                (@bottom - @top)
            end
            #
            def set_position(the_x=nil,the_y=nil)
                the_width = self.width
                the_height = self.height
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                if ((bounds[:top])..(bounds[:bottom])).include?(the_y.to_i) && ((bounds[:top])..(bounds[:bottom])).include?((the_y.to_i + the_height))
                    @top = (the_y.to_i)
                end
                if ((bounds[:left])..(bounds[:right])).include?(the_x.to_i) && ((bounds[:left])..(bounds[:right])).include?((the_x.to_i + the_width))
                    @left = (the_x.to_i)
                end
                @bottom = (@top + the_height)
                @right = (@left + the_width)
                self.fit_within_boundaries()
                # commit_settings
                # convert to % ??
                # top_percent = (@top.to_f / bounds[:page_height].to_f) * 100.0
                # left_percent = (@left.to_f / bounds[:page_width].to_f) * 100.0
                # self.gxg_merge_style({:left => "#{left_percent}%", :top => "#{top_percent}%"})
                self.commit_settings
            end
            #
            def set_frame(settings=nil)
                if settings.is_a?(::Hash)
                    @top = (settings[:top] || @top)
                    @left = (settings[:left] || @left)
                    @right = (settings[:right] || @right)
                    @bottom = (settings[:bottom] || @bottom)
                    self.fit_within_boundaries()
                    self.commit_settings
                end
            end
            #
            def position()
                {:x => @left, :y => @top}
            end
            #
            def fit_within_boundaries()
                the_width = self.width
                the_height = self.height
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                if @top < bounds[:top]
                    @top = bounds[:top]
                end
                if @left < bounds[:left]
                    @left = bounds[:left]
                end
                @right = @left + the_width
                @bottom = @top + the_height
                if @bottom > bounds[:bottom]
                    @bottom = bounds[:bottom]
                end
                if @right > bounds[:right]
                    @right = bounds[:right]
                end
            end
            #
            def set_window_title(the_title=nil)
                if @title_object
                    if the_title.is_a?(::String)
                        @window_title = the_title
                        @title_object.set_text(@window_title)
                        @title_object.parent.gxg_merge_style({:padding => "0px 0px 0px #{((self.width() / 2) - ((@window_title.size / 2) * 8)) - 60}px"})
                    end
                end
            end
            #
            def window_title()
                if @title_object
                    @window_title
                else
                    nil
                end
            end
            #
            def special_state()
                @special_state
            end
            #
            def set_special_state(settings=nil)
                if settings.is_a?(::Hash)
                    @special_state = settings
                    @top = (settings[:top] || @top)
                    @left = (settings[:left] || @left)
                    @right = (settings[:right] || @right)
                    @bottom = (settings[:bottom] || @bottom)
                    self.fit_within_boundaries()
                    self.commit_settings
                end
            end
            #
            def clear_special_state(settings=nil)
                @special_state = nil
                if settings.is_a?(::Hash)
                    self.set_frame(settings)
                end
            end
            # Initialization and Setup
            def initialize(the_name,the_class,the_options)
                # FIXME: work around for strange bug in layout_refresh
                ::GxG::DISPLAY_DETAILS[:object].layout_refresh
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                #
                @special_state = nil
                @content = nil
                # Process the_options
                unless the_options.is_a?(::Hash)
                    the_options = {}
                end
                # So, at this point I've decided to use pixels internally, but percentages externally. (interface)
                # You can pass Integer (as Pixels), Float, or String Percentage
                if the_options[:top].is_a?(::String) || the_options[:top].to_s.include?(".")
                    if the_options[:top].is_a?(::String)
                        @top = (bounds[:page_height] * (the_options.delete(:top).gsub("%","").to_f / 100.0))
                    else
                        @top = (bounds[:page_height] * (the_options.delete(:top) / 100.0))
                    end
                else
                    @top = (the_options.delete(:top) || ((`window.innerHeight`.to_i / 2) - 50))
                end
                if the_options[:left].is_a?(::String) || the_options[:left].to_s.include?(".")
                    if the_options[:left].is_a?(::String)
                        @left = (bounds[:page_width] * (the_options.delete(:left).gsub("%","").to_f / 100.0))
                    else
                        @left = (bounds[:page_width] * (the_options.delete(:left) / 100.0))
                    end
                else
                    @left = (the_options.delete(:left) || ((`window.innerWidth`.to_i / 2) - 100))
                end
                if the_options[:right].is_a?(::String) || the_options[:right].to_s.include?(".")
                    if the_options[:right].is_a?(::String)
                        @right = (bounds[:page_width] * (the_options.delete(:right).gsub("%","").to_f / 100.0))
                    else
                        @right = (bounds[:page_width] * (the_options.delete(:right) / 100.0))
                    end
                else
                    @right = (the_options.delete(:right) || ((`window.innerWidth`.to_i / 2) + 100))
                end
                if the_options[:bottom].is_a?(::String) || the_options[:bottom].to_s.include?(".")
                    if the_options[:bottom].is_a?(::String)
                        @bottom = (bounds[:page_height] * (the_options.delete(:bottom).gsub("%","").to_f / 100.0))
                    else
                        @bottom = (bounds[:page_height] * (the_options.delete(:bottom) / 100.0))
                    end
                else
                    @bottom = (the_options.delete(:bottom) || ((`window.innerHeight`.to_i / 2) + 50))
                end
                #
                @window_title = the_options[:window_title] || "Untitled"
                @title_object = nil
                #
                if the_options[:width].is_a?(::String) || the_options[:width].to_s.include?(".")
                    if the_options[:width].is_a?(::String)
                        @right = @left + ((bounds[:right] - bounds[:left]) * (the_options.delete(:width).gsub("%","").to_f / 100.0))
                    else
                        @right = @left + ((bounds[:right] - bounds[:left]) * (the_options.delete(:width) / 100.0))
                    end
                else
                    if the_options[:width].is_a?(::Numeric)
                        @right = (@left + the_options.delete(:width))
                    end
                end
                if the_options[:height].is_a?(::String) || the_options[:height].to_s.include?(".")
                    if the_options[:height].is_a?(::String)
                        @bottom = @top + ((bounds[:bottom] - bounds[:top]) * (the_options.delete(:height).gsub("%","").to_f / 100.0))
                    else
                        @bottom = @top + ((bounds[:bottom] - bounds[:top]) * (the_options.delete(:height) / 100.0))
                    end
                else
                    if the_options[:height].is_a?(::Numeric)
                        @bottom = (@top + the_options.delete(:height))
                    end
                end
                # Bounds check top, left, right, and bottom
                self.fit_within_boundaries()
                #
                @modal = (the_options[:modal] || false)
                @scrolling = the_options.delete(:scroll)
                @title_margin = 24
                if @modal == true
                    @resize = false
                    @resize_margin = 0
                else
                    @resize = (the_options[:resize] || true)
                    @resize_margin = 2
                    @title_margin = 26
                end
                if @modal == true
                    @closebox = false
                    @minimizebox = false
                    @maximizebox = false
                else
                    if the_options[:close] == false
                        @closebox = false
                    else
                        @closebox = (the_options[:close] || :enabled).to_s.to_sym
                    end
                    if the_options[:minimize] == false
                        @minimizebox = false
                    else
                        @minimizebox = (the_options[:minimize] || :enabled).to_s.to_sym
                    end
                    if the_options[:maximize] == false
                        @maximizebox = false
                    else
                        @maximizebox = (the_options[:maximize] || :enabled).to_s.to_sym
                    end
                end
                #
                @tracking = {}
                #
                @menu_reference = the_options.delete(:menu)
                @menu_area = nil
                @menu_bar = nil
                if @menu_reference
                    @menu_margin = 16
                else
                    @menu_margin = 0
                end
                #
                super(the_name,the_class,the_options)
                #
                # self.gxg_set_attribute(:draggable,true)
                #
                self
            end
            #
            def menu_reference()
                @menu_reference
            end
            #
            def menu()
                @menu_bar
            end
            #
            def set_menu(the_menu_source=nil)
                if the_menu_source.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    if @menu_area
                        page.build_components([{:parent => @menu_area.parent, :record => {:content => [(the_menu_source)]}, :element => @menu_area}])
                        #
                        @menu_margin = (`#{@menu_area.element}.getBoundingClientRect().bottom - #{@menu_area.element}.getBoundingClientRect().top`.to_i)
                        #
                        @menu_bar = self.find_child(@menu_reference,true)
                        #
                        if @menu_bar
                            self.commit_settings
                            true
                        else
                            log_warn("Unable to properly initialize window menu #{@menu_reference.inspect} .")
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
            alias :original_add_child :add_child
            def add_child(name, element_class, options = {})
                if @content
                    @content.add_child(name, element_class, options)
                end
            end
            #
            alias :original_children :children
            def children()
                if @content
                    @content.children
                else
                    {}
                end
            end
            #
            def find_child(the_reference=nil, interior=false)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                if interior == true
                    search_queue = self.original_children.values
                else
                    search_queue = self.children.values
                end
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def cascade()
                commit_settings
                #
                build_list = []
                #
                # Define Title Bar
                # FIXME: CSS override of image :src does NOT work -- research.
                # title_object_title = "Object #{::GxG::uuid_generate.to_s}"
                the_title = {:component=>"label", :options=>{:title => "title_object", :content => @window_title, :style => {:width => "100%", :"font-size" => "16px", :"text-align" => "center"}}, :content=>[], :script=>""}
                #
                close_box = {:component=>"image", :options=>{:src => theme_widget("close.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}, :content=>[], :script=>""}
                close_box[:script] = "
                on(:mouseup) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('close.png'))
                        the_window = self.window
                        if the_window
                            if the_window.application
                                the_window.application.window_close({:window => the_window.uuid})
                            else
                                GxG::DISPLAY_DETAILS[:object].window_close(the_window.uuid)
                            end
                        else
                            log_warn('Window Not Found')
                        end
                    end
                end
                on(:mousedown) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('close_mousedown.png'))
                    end
                end
                on(:mouseenter) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('close_mouseenter.png'))
                    end
                end
                on(:mouseleave) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('close.png'))
                    end
                end
                "
                minimize_box = {:component=>"image", :options=>{:src => theme_widget("minimize.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}, :content=>[], :script=>""}
                minimize_box[:script] = "
                on(:mouseup) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('minimize.png'))
                        the_window = self.window
                        if the_window
                            special = the_window.special_state()
                            if special.is_a?(::Hash)
                                if special[:action] == :minimize
                                    GxG::DISPLAY_DETAILS[:object].window_restore(the_window.uuid)
                                else
                                    GxG::DISPLAY_DETAILS[:object].window_minimize(the_window.uuid,{:top => the_window.top, :left => the_window.left, :right => the_window.right, :bottom => the_window.bottom})
                                end
                            else
                                GxG::DISPLAY_DETAILS[:object].window_minimize(the_window.uuid,{:top => the_window.top, :left => the_window.left, :right => the_window.right, :bottom => the_window.bottom})
                            end
                        end
                    end
                end
                on(:mousedown) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('minimize_mousedown.png'))
                    end
                end
                on(:mouseenter) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('minimize_mouseenter.png'))
                    end
                end
                on(:mouseleave) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('minimize.png'))
                    end
                end
                "
                maximize_box = {:component=>"image", :options=>{:src => theme_widget("maximize.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}, :content=>[], :script=>""}
                maximize_box[:script] = "
                on(:mouseup) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('maximize.png'))
                        the_window = self.window
                        if the_window
                            special = the_window.special_state()
                            if special.is_a?(::Hash)
                                if special[:action] == :maximize
                                    GxG::DISPLAY_DETAILS[:object].window_restore(the_window.uuid)
                                else
                                    GxG::DISPLAY_DETAILS[:object].window_maximize(the_window.uuid,{:top => the_window.top, :left => the_window.left, :right => the_window.right, :bottom => the_window.bottom})
                                end
                            else
                                GxG::DISPLAY_DETAILS[:object].window_maximize(the_window.uuid,{:top => the_window.top, :left => the_window.left, :right => the_window.right, :bottom => the_window.bottom})
                            end
                        end
                    end
                end
                on(:mousedown) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('maximize_mousedown.png'))
                    end
                end
                on(:mouseenter) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('maximize_mouseenter.png'))
                    end
                end
                on(:mouseleave) do |event|
                    unless self.gxg_get_state(:disabled) == true
                        self.gxg_set_attribute(:src,theme_widget('maximize.png'))
                    end
                end
                "
                table = {:component=>"block_table", :options=>{:style => {:clear => "both", :height=>"24px", :padding => "0px", :margin => "0px", :"border-radius" => "5px 5px 0px 0px", :"border-bottom" => "1px solid #c2c2c2"}, :states => {:"default-background-color" => true}}, :content=>[], :script=>""}
                row = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent"}}, :content=>[], :script=>""}
                cell_one = {:component=>"block_table_cell", :options=>{:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent"}}, :content=>[], :script=>""}
                cell_two = {:component=>"block_table_cell", :options=>{:style => {:width => "100%",:padding => "0px 0px 0px #{((self.width() / 2) - ((@window_title.size / 2) * 8)) - 60}px", :"vertical-align" => "middle", :margin => "0px", :"background-color" => "transparent"}}, :content=>[], :script=>""}
                cell_three = {:component=>"block_table_cell", :options=>{:style => {:float => "right", :padding => "0px", :"vertical-align" => "middle", :margin => "0px", :"background-color" => "transparent"}}, :content=>[], :script=>""}
                # link pieces
                if @closebox
                    if @closebox == :disabled
                        close_box[:options][:src] = theme_widget("close_disable.png")
                        close_box[:options][:states][:disabled] = true
                    end
                    cell_one[:content] << close_box
                end
                if @minimizebox
                    if @minimizebox == :disabled
                        minimize_box[:options][:src] = theme_widget("minimize_disable.png")
                        minimize_box[:options][:states][:disabled] = true
                    end
                    cell_one[:content] << minimize_box
                end
                if @maximizebox
                    if @maximizebox == :disabled
                        maximize_box[:options][:src] = theme_widget("maximize_disable.png")
                        maximize_box[:options][:states][:disabled] = true
                    end
                    cell_one[:content] << maximize_box
                end
                cell_two[:content] = [(the_title)]
                cell_two[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        #
                        if @window_handle
                            unless @last_mouse_x
                                @last_mouse_x = event[:pageX]
                            end
                            unless @last_mouse_y
                                @last_mouse_y = event[:pageY]
                            end
                            offset_x = (event[:pageX] - @window_handle.left)
                            if event[:pageY] < @window_handle.top
                                offset_y = (@window_handle.top - event[:pageY])
                            else
                                offset_y = (event[:pageY] - @window_handle.top)
                            end
                            new_x = ((event[:pageX] - offset_x) + (event[:pageX] - @last_mouse_x))
                            new_y = ((event[:pageY] - offset_y) + (event[:pageY] - @last_mouse_y))
                            @window_handle.set_position(new_x,new_y)
                            @last_mouse_x = event[:pageX]
                            @last_mouse_y = event[:pageY]
                        end
                    end
                end
                on(:dblclick) do |event|
                    the_window = self.window
                    if the_window
                        special = the_window.special_state()
                        if special.is_a?(::Hash)
                            if special[:action] == :rollup
                                GxG::DISPLAY_DETAILS[:object].window_restore(the_window.uuid)
                            else
                                GxG::DISPLAY_DETAILS[:object].window_rollup(the_window.uuid,{:top => the_window.top, :left => the_window.left, :right => the_window.right, :bottom => the_window.bottom})
                            end
                        else
                            GxG::DISPLAY_DETAILS[:object].window_rollup(the_window.uuid,{:top => the_window.top, :left => the_window.left, :right => the_window.right, :bottom => the_window.bottom})
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousemove) do |event|
                    @window_handle = self.window
                    if ((event[:buttons] & 1) == 1)
                        @mode = :drag
                        do_drag(event)
                    else
                        @mode = :hover
                    end
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                row[:content] = [(cell_one), (cell_two), (cell_three)]
                table[:content] = [(row)]
                #
                build_list << table
                #
                interior_object_title = "Object #{::GxG::uuid_generate.to_s}"
                interior_component = {:component=>"block", :options=>{:title => "interior_component", :style => {:clear => "both", :padding => "0px", :margin => "0px", :border => "0px", :width => "#{(self.width - (@resize_margin * 2))}px", :height => "#{self.height - (@title_margin + @menu_margin + @resize_margin)}px"}, :states => {:"default-background-color" => true}}, :content=>[], :script=>""}
                #
                if @scrolling
                    if @scrolling == true
                        interior_component[:options][:style][:overflow] = "scroll"
                    else
                        if @scrolling == "vertical"
                            interior_component[:options][:style][:"overflow-y"] = "scroll"
                        end
                        if @scrolling == "horizontal"
                            interior_component[:options][:style][:"overflow-x"] = "scroll"
                        end
                    end
                else
                    interior_component[:options][:style][:overflow] = "hidden"
                end
                #
                left_resizer = {:component => "block_table_cell", :options => {:style => {:width => "2px", :cursor => "w-resize"}}, :content => [], :script => ""}
                left_resizer[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        window_handle = self.window
                        if window_handle
                            window_handle.set_left(event[:pageX])
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                right_resizer = {:component => "block_table_cell", :options => {:style => {:width => "2px", :cursor => "e-resize"}}, :content => [], :script => ""}
                right_resizer[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        window_handle = self.window
                        if window_handle
                            window_handle.set_right(event[:pageX] + 1)
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                bottom_resizer = {:component => "block_table_cell", :options => {:style => {:height => "2px", :cursor => "s-resize"}}, :content => [], :script => ""}
                bottom_resizer[:script] = "
                def do_drag(event)
                    window_handle = self.window
                    if window_handle
                        if ((event[:buttons] & 1) == 1)
                            window_handle.set_bottom(event[:pageY] + 4)
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                sw_resizer = {:component => "block_table_cell", :options => {:style => {:width => "2px", :height => "2px", :cursor => "sw-resize"}}, :content => [], :script => ""}
                sw_resizer[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        window_handle = self.window
                        if window_handle
                            window_handle.set_left(event[:pageX] - 2)
                            window_handle.set_bottom(event[:pageY] + 4)
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                se_resizer = {:component => "block_table_cell", :options => {:style => {:width => "2px", :height => "2px", :cursor => "se-resize"}}, :content => [], :script => ""}
                se_resizer[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        window_handle = self.window
                        if window_handle
                            window_handle.set_right(event[:pageX] + 2)
                            window_handle.set_bottom(event[:pageY] + 4)
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                left_menu_resize = {:component => "block_table_cell", :options => {:style => {:width => "2px", :cursor => "w-resize"}}, :content => [], :script => ""}
                left_menu_resize[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        window_handle = self.window
                        if window_handle
                            window_handle.set_left(event[:pageX])
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                right_menu_resize = {:component => "block_table_cell", :options => {:style => {:width => "2px", :cursor => "e-resize"}}, :content => [], :script => ""}
                right_menu_resize[:script] = "
                def do_drag(event)
                    if ((event[:buttons] & 1) == 1)
                        window_handle = self.window
                        if window_handle
                            window_handle.set_right(event[:pageX] + 1)
                        end
                    end
                end
                on(:mouseup) do |event|
                    @mode = :hover
                    the_window = self.window
                    if the_window
                        GxG::DISPLAY_DETAILS[:object].window_bring_to_front(the_window.uuid)
                    end
                end
                on(:mousedown) do |event|
                    @mode = :drag
                    do_drag(event)
                end
                on(:mouseover) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseleave) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                on(:mouseenter) do |event|
                    if @mode == :drag
                        do_drag(event)
                    end
                end
                "
                # menu_object_title = "Object #{::GxG::uuid_generate.to_s}"
                menu_cell = {:component => "block_table_cell", :options => {:title => "menu_area", :style => {:overflow => "hidden", :height=>"16px",:padding => "0px", :margin => "0px"}}, :content => [], :script => ""}
                # menu_row_object_title = "Object #{::GxG::uuid_generate.to_s}"
                menu_row = {:component=>"block_table_row", :options=>{:title => "menu_area_row", :style => {:overflow => "hidden", :clear => "both", :padding => "0px", :width => "100%", :height=>"16px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent", :"border-bottom" => "1px solid #c2c2c2"}}, :content => [(left_menu_resize),(menu_cell),(right_menu_resize)], :script=>""}
                content_area = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :border => "0px"}}, :content => [], :script => ""}
                row_one = {:component => "block_table_row", :options => {}, :content => [], :script => ""}
                row_two = {:component => "block_table_row", :options => {}, :content => [], :script => ""}
                # window_body_title = "Object #{::GxG::uuid_generate.to_s}"
                resizing_areas = {:component => "block_table", :options => {:title => "window_body", :style => {:width => "100%"}, :states => {:"default-background-color" => true}}, :content => [], :script => ""}
                # link pieces
                content_area[:content] = [(interior_component)]
                if @resize
                    row_one[:content] = [(left_resizer),(content_area),(right_resizer)]
                    row_two[:content] = [(sw_resizer),(bottom_resizer),(se_resizer)]
                    if @menu_reference
                        resizing_areas[:content] = [(menu_row),(row_one),(row_two)]
                    else
                        resizing_areas[:content] = [(row_one),(row_two)]
                    end
                else
                    if @menu_reference
                        row_one[:content] = [(content_area)]
                        resizing_areas[:content] = [(menu_row),(row_one)]
                    else
                        row_one[:content] = [(content_area)]
                        resizing_areas[:content] = [(row_one)]
                    end
                end
                #
                build_list << resizing_areas
                #
                self.build_interior_components(build_list)
                #
                # the_object = self.find_child(interior_object_title,true)
                # if the_object
                #     @content = the_object
                # end
                # 
                # the_object = self.find_child(window_body_title,true)
                # if the_object
                #     @window_body = the_object
                # end
                #
                the_object = self.find_child("title_object",true)
                if the_object
                    @title_object = the_object
                end
                #
                the_object = self.find_child("menu_area",true)
                if the_object
                    @menu_area = the_object
                    @menu_margin = (`#{@menu_area.element}.getBoundingClientRect().bottom - #{@menu_area.element}.getBoundingClientRect().top`.to_i)
                    # border-collapse: collapse
                    if @menu_area
                        @menu_area.parent.parent.gxg_merge_style({:"border-collapse" => "collapse"})
                    end
                else
                    # test: log_warn("Unable to establish Menu Area link internally.")
                end
                # FIXME: does not set correct size of content by default (!) (workaround here:)
                # self.set_bottom(self.bottom())
                # (result: no effect)
                # other attempt: (THIS worked!)
                GxG::DISPATCHER.post_event do
                    self.commit_settings
                end
                self
            end
        end
        #
        class DialogBox < ::Ferro::Component::Base
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            include GxG::Gui::EventHandlers
            include GxG::Gui::AnimationSupport
            include GxG::Gui::ApplicationSupport
            include GxG::Gui::ThemeSupport
            #
            def uuid()
                @uuid
            end
            # Methods to override in window's script
            def before_close(data=nil)
                # override in window's script
            end
            #
            def after_close(data=nil)
                # override in window's script
            end
            #
            def before_open(data=nil)
                # override in window's script
            end
            #
            def after_open(data=nil)
                # override in window's script
            end
            #
            def set_application(the_application)
                @application = the_application
            end
            #
            def application()
                @application
            end
            #
            def set_window_title(the_title=nil)
                if @title_object
                    if the_title.is_a?(::String)
                        @window_title = the_title
                        @title_object.set_text(@window_title)
                    end
                end
            end
            #
            def window_title()
                if @title_object
                    @window_title
                else
                    nil
                end
            end
            #
            def set_data(data={})
                @data = data
            end
            #
            def data()
                @data
            end
            #
            def set_responder(block=nil)
                if block.respond_to?(:call)
                    @responder = block
                end
            end
            #
            def respond(data=nil)
                self.page.dialog_close()
                if @responder.respond_to?(:call)
                    @responder.call(data)
                end
            end
            # Geometry details:
            def top()
                @top
            end
            #
            def left()
                @left
            end
            #
            def right()
                @right
            end
            #
            def bottom()
                @bottom
            end
            #
            def width()
                (@right - @left)
            end
            #
            def height()
                (@bottom - @top)
            end
            #
            def position()
                {:x => @left, :y => @top}
            end
            #
            def layer()
                @layer
            end
            #
            # Initialization and Setup
            def initialize(the_name,the_class,the_options)
                # FIXME: work around for strange bug in layout_refresh
                # ::GxG::DISPLAY_DETAILS[:object].layout_refresh
                # bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                #
                @special_state = nil
                @content = nil
                # Process the_options
                unless the_options.is_a?(::Hash)
                    the_options = {}
                end
                # So, at this point I've decided to use pixels internally, but percentages externally. (interface)
                # You can pass Integer (as Pixels), Float, or String Percentage
                the_width = nil
                if the_options[:width].is_a?(::String) || the_options[:width].to_s.include?(".")
                    if the_options[:width].is_a?(::String)
                        the_width = ((`window.innerWidth`.to_f) * (the_options.delete(:width).gsub("%","").to_f / 100.0))
                    else
                        the_width = ((`window.innerWidth`.to_f) * (the_options.delete(:width) / 100.0))
                    end
                else
                    if the_options[:width].is_a?(::Numeric)
                        the_width = the_options.delete(:width).to_f
                    end
                end
                if the_width
                    @left = ((`window.innerWidth`.to_f / 2.0) - (the_width / 2.0))
                    @right = ((`window.innerWidth`.to_f / 2.0) + (the_width / 2.0))
                end
                #
                the_height = nil
                if the_options[:height].is_a?(::String) || the_options[:height].to_s.include?(".")
                    if the_options[:height].is_a?(::String)
                        the_height = ((`window.innerHeight`.to_f) * (the_options.delete(:height).gsub("%","").to_f / 100.0))
                    else
                        the_height = ((`window.innerHeight`.to_f) * (the_options.delete(:height) / 100.0))
                    end
                else
                    if the_options[:height].is_a?(::Numeric)
                        the_height = the_options.delete(:height).to_f
                    end
                end
                if the_height
                    @top = ((`window.innerHeight`.to_f / 2.0) - (the_height / 2.0))
                    @bottom = ((`window.innerHeight`.to_f / 2.0) + (the_height / 2.0))
                end
                #
                if the_options[:top].is_a?(::String) || the_options[:top].to_s.include?(".")
                    if the_options[:top].is_a?(::String)
                        @top = (`window.innerHeight`.to_f * (the_options.delete(:top).gsub("%","").to_f / 100.0))
                    else
                        @top = (`window.innerHeight`.to_f * (the_options.delete(:top) / 100.0))
                    end
                else
                    unless the_height
                        @top = (the_options.delete(:top) || ((`window.innerHeight`.to_i / 2) - 150))
                    end
                end
                if the_options[:left].is_a?(::String) || the_options[:left].to_s.include?(".")
                    if the_options[:left].is_a?(::String)
                        @left = (`window.innerWidth`.to_f * (the_options.delete(:left).gsub("%","").to_f / 100.0))
                    else
                        @left = (`window.innerWidth`.to_f * (the_options.delete(:left) / 100.0))
                    end
                else
                    unless the_width
                        @left = (the_options.delete(:left) || ((`window.innerWidth`.to_i / 2) - 300))
                    end
                end
                if the_options[:right].is_a?(::String) || the_options[:right].to_s.include?(".")
                    if the_options[:right].is_a?(::String)
                        @right = (`window.innerWidth`.to_f * (the_options.delete(:right).gsub("%","").to_f / 100.0))
                    else
                        @right = (`window.innerWidth`.to_f * (the_options.delete(:right) / 100.0))
                    end
                else
                    unless the_width
                        @right = (the_options.delete(:right) || ((`window.innerWidth`.to_i / 2) + 300))
                    end
                end
                if the_options[:bottom].is_a?(::String) || the_options[:bottom].to_s.include?(".")
                    if the_options[:bottom].is_a?(::String)
                        @bottom = (`window.innerHeight`.to_f * (the_options.delete(:bottom).gsub("%","").to_f / 100.0))
                    else
                        @bottom = (`window.innerHeight`.to_f * (the_options.delete(:bottom) / 100.0))
                    end
                else
                    unless the_height
                        @bottom = (the_options.delete(:bottom) || ((`window.innerHeight`.to_i / 2) + 150))
                    end
                end
                #
                @window_title = the_options[:window_title] || "Untitled"
                @title_object = nil
                #
                @opacity = (the_options.delete(:opacity) || 0.8)
                @background_color = (the_options.delete(:"background-color") || "rgba(0,0,0,#{@opacity})")
                @layer = 2000
                #
                @tracking = {}
                @responder = nil
                @data = {}
                #
                super(the_name,the_class,the_options)
                #
                self.gxg_set_attribute(:draggable,false)
                #
                self
            end
            # Slight of hand:
            alias :original_add_child :add_child
            def add_child(name, element_class, options = {})
                if @content
                    @content.add_child(name, element_class, options)
                end
            end
            #
            alias :original_children :children
            def children()
                if @content
                    @content.children
                else
                    {}
                end
            end
            #
            def find_child(the_reference=nil, interior=false)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                if interior == true
                    search_queue = self.original_children.values
                else
                    search_queue = self.children.values
                end
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            # Construction
            def cascade()
                # Initialize Style Settings:
                self.gxg_merge_style({:position => "absolute", :top => "0px", :left => "0px", :width => "100%", :height => "100%", :"background-color" => @background_color, :"z-index" => @layer})
                mouse_event_capture = "
                on(:mouseup,true) do |event|
                end
                on(:mousedown,true) do |event|
                end
                on(:mousemove,true) do |event|
                end
                on(:mouseenter,true) do |event|
                end
                on(:mouseleave,true) do |event|
                end
                "
                self.set_script(mouse_event_capture)
                # Prep build_list
                build_list = []
                #
                modal_frame = {:component=>"block_table", :options=>{:style => {:opacity => 1.0, :clear => "both", :overflow => "hidden", :position => "absolute", :top => "#{@top}px", :left => "#{@left}px", :width => "#{self.width}px", :height=>"#{self.height}px", :padding => "0px", :margin => "0px", :"border-radius" => "5px 5px 5px 5px", :"z-index" => (@layer + 100)}, :states => {:"default-background-color" => true}}, :content=>[], :script=>""}
                title_object_title = "Object #{::GxG::uuid_generate.to_s}"
                the_title = {:component=>"label", :options=>{:title => title_object_title, :content => @window_title, :style => {:opacity => 1.0, :width => "100%", :"font-size" => "16px", :"text-align" => "center"}}, :content=>[], :script=>""}
                title_cell = {:component=>"block_table_cell", :options=>{:style => {:opacity => 1.0, :width => "100%", :padding => "0px 0px 0px #{((self.width() / 2) - ((@window_title.size / 2) * 8))}px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent"}}, :content=>[(the_title)], :script=>""}
                title_row = {:component=>"block_table_row", :options=>{:style => {:opacity => 1.0, :clear => "both", :padding => "0px", :width => "100%", :height=>"24px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "#ffffff", :"border-bottom" => "1px solid #c2c2c2"}}, :content=>[(title_cell)], :script=>""}
                #
                interior_object_title = "Object #{::GxG::uuid_generate.to_s}"
                interior_component = {:component=>"block_table_cell", :options=>{:title => "interior_component", :style => {:opacity => 1.0, :clear => "both", :padding => "0px", :margin => "0px", :border => "0px", :width => "#{self.width}px", :height => "#{self.height}px"}, :states => {:"default-background-color" => true}}, :content=>[], :script=>""}
                content_row = {
                    :component => "block_table_row",
                    :options => {
                        :style => {
                            :opacity => 1.0,
                            :width => "#{self.width}px",
                            :height => "#{self.height - 24}px",
                            :padding => "0px",
                            :margin => "0px",
                            :border => "0px"
                        }
                    },
                    :content => [(interior_component)],
                    :script => ""
                }
                #
                modal_frame[:content] = [(title_row),(content_row)]
                build_list << modal_frame
                #
                self.build_interior_components(build_list)
                #
                # the_object = self.find_child(interior_object_title,true)
                # if the_object
                #     @content = the_object
                # end
                #
                the_object = self.find_child(title_object_title,true)
                if the_object
                    @title_object = the_object
                end
                #
            end
            # Hooks for open/close events
            def open(details={})
                # override in object script
            end
            #
            def close(details={})
                # override in object script
            end
        end
        # Menu Supports
        class MenuItem < ::GxG::Gui::Block
            def _after_create()
                if @enabled == true
                    self.enable
                else
                    self.disable
                end
                super()
            end
            #
            # Structure:
            def opened?()
                false
            end
            #
            def collapse()
                self.unhighlight
                if @the_parent.respond_to?(:collapse)
                    @the_parent.collapse()
                end
            end
            #
            def collapse_down()
                self.unhighlight
            end
            # Visuals:
            def enabled?()
                @enabled
            end
            def enable()
                @enabled = true
                self.gxg_merge_style(:opacity => 1.0)
            end
            def disable()
                @enabled = false
                self.unhighlight
                self.gxg_merge_style(:opacity => 0.5)
            end
            def highlight()
                self.gxg_merge_style({:'background-color' => '#87acd5'})
            end
            def unhighlight()
                self.gxg_merge_style({:'background-color' => '#f2f2f2'})
            end
            def update_appearance()
                # override in object script
            end
            #
            def initialize(the_name,the_class,the_options)
                unless @title
                    @title = the_options.delete(:title)
                end
                @menu = the_options.delete(:menu)
                @the_parent = the_options.delete(:parent)
                @orientation = (the_options.delete(:orientation) || "vertical").to_s.to_sym
                if @orientation == :horizontal
                    @zone = (the_options.delete(:zone) || "top").to_s.to_sym
                else
                    @zone = (the_options.delete(:zone) || "left").to_s.to_sym
                end
                @enabled = the_options.delete(:enabled)
                unless @enabled == false
                    @enabled = true
                end
                # presentation supports:
                @icon = the_options.delete(:icon)
                @icon_width = (the_options.delete(:icon_width) || 32)
                @icon_height = (the_options.delete(:icon_height) || 32)
                @label = the_options.delete(:content)
                @key = the_options.delete(:key)
                # Data payload:
                @data = the_options.delete(:data)
                #
                super(the_name, the_class, the_options)
                #
                # Mouse Events:
                on(:mouseup) do |event|
                    if self.enabled?
                        if @menu
                            self.collapse()
                            @menu.select_item(self)
                        end
                    end
                end
                on(:mouseenter) do |event|
                    if self.enabled?
                        self.highlight
                    end
                end
                on(:mouseleave) do |event|
                    if self.enabled?
                        self.unhighlight
                    end
                end
                self
            end
            # Payload:
            def data()
                @data
            end
            #
            def cascade()
                build_list = []
                #
                spacer = {:component=>"block", :options=>{:style => {:clear => "both", :width=>"32px", :height=>"32px"}}, :content=>[], :script=>""}
                #
                icon = nil
                if @icon
                    icon = {:component=>"image", :options=>{:src=>@icon, :width=>@icon_width, :height=>@icon_height, :style => {:clear => "both"}}, :content=>[], :script=>""}
                end
                #
                label = nil
                if @label
                    label = {:component=>"label", :options=>{:content => @label, :style => {:padding => "0px 0px 2px 0px", :"font-size" => "16px"}}, :content=>[], :script=>""}
                end
                #
                key = nil
                if @key
                    key = {:component=>"label", :options=>{:content => @key, :style => {:"font-size" => "16px"}}, :content=>[], :script=>""}
                end
                # grid structure
                left_spacer_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px"}}, :content=>[(spacer)], :script=>""}
                right_spacer_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "right", :padding => "0px", :margin => "0px"}}, :content=>[(spacer)], :script=>""}
                #
                icon_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(icon)], :script=>""}
                label_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px 0px 0px 5px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(label)], :script=>""}
                key_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "right", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(key)], :script=>""}
                entry_row = {:component=>"block_table_row", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px"}}, :content=>[], :script=>""}
                #
                if @zone == :right
                    entry_row[:content] << left_spacer_cell
                end
                #
                if icon
                    entry_row[:content] << icon_cell
                end
                #
                if label
                    entry_row[:content] << label_cell
                end
                #
                if key
                    entry_row[:content] << key_cell
                end
                #
                if @zone != :right
                    entry_row[:content] << right_spacer_cell
                end
                #
                entry_table = {:component=>"block_table", :options=>{:style => {:padding => "0px", :margin => "0px"}}, :content=>[(entry_row)], :script=>""}
                #
                build_list << entry_table
                #
                self.build_interior_components(build_list)
            end
            #
        end
        #
        class MenuEntry < ::GxG::Gui::Block
            def _after_create()
                if @enabled == true
                    self.enable
                else
                    self.disable
                end
                super()
            end
            #
            def initialize(the_name,the_class,the_options)
                @opened = false
                unless @title
                    @title = the_options.delete(:title)
                end
                @menu = the_options.delete(:menu)
                @the_parent = the_options.delete(:parent)
                @orientation = (the_options.delete(:orientation) || "vertical").to_s.to_sym
                if @orientation == :horizontal
                    @zone = (the_options.delete(:zone) || "top").to_s.to_sym
                else
                    @zone = (the_options.delete(:zone) || "left").to_s.to_sym
                end
                if @the_parent.is_a?(::GxG::Gui::MenuBar)
                    @submenu = false
                else
                    @submenu = true
                end
                @enabled = the_options.delete(:enabled)
                unless @enabled == false
                    @enabled = true
                end
                # presentation supports:
                @icon = the_options.delete(:icon)
                @icon_width = (the_options.delete(:icon_width) || 32)
                @icon_height = (the_options.delete(:icon_height) || 32)
                @label = the_options.delete(:content)
                @label_size = (the_options.delete(:content_size) || 16).to_s.gsub("px","").to_i
                @key = the_options.delete(:key)
                @layer = (the_options.delete(:layer) || 1000)
                @menu_item_width = [200,(@icon_width)].max
                # Review: adjust for border, padding, and margin
                @menu_item_height = 32
                # if @icon
                #     @menu_item_height = [(@label_size),(@icon_height)].max
                # else
                #     @menu_item_height = @label_size + 2
                # end
                #
                super(the_name, the_class, the_options)
                # Create off-entry block body to attach items/etc to.
                the_uuid = GxG::uuid_generate.to_sym
                the_title = "Untitled Component #{the_uuid}"
                @body = GxG::DISPLAY_DETAILS[:object].add_child(the_uuid, ::GxG::Gui::Block, {:uuid => the_uuid})
                @body.set_title(the_title)
                GxG::DISPLAY_DETAILS[:object].register_object(the_title, @body)
                # Set @body base-state
                @body.gxg_set_state(:hidden, true)
                # FIXME: menu background is errantly too short.
                # @body.gxg_set_state(:"default-background-color", true)
                @body.gxg_merge_style({:position => "absolute", :"background-color" => "#f2f2f2", :border => "1px solid #c2c2c2"})
                @body.on(:mouseleave) do |event|
                    hold_open = false
                    search_queue = @body.children.values
                    while search_queue.size > 0 do
                        the_child = search_queue.shift
                        if the_child.is_any?(::GxG::Gui::MenuEntry, ::GxG::Gui::MenuItem)
                            if the_child.opened?
                                hold_open = true
                                break
                            end
                        else
                            the_child.children.values.each do |sub_child|
                                search_queue << sub_child
                            end
                        end
                    end
                    unless hold_open == true
                        @body.hide
                        @opened = false
                    end
                end
                #
                the_uuid = GxG::uuid_generate.to_sym
                the_title = "Untitled Component #{the_uuid}"
                @body_content = @body.add_child(the_uuid, ::GxG::Gui::BlockTable, {:uuid => the_uuid})
                @body_content.set_title(the_title)
                GxG::DISPLAY_DETAILS[:object].register_object(the_title, @body_content)
                # Mouse Events:
                on(:mouseup) do |event|
                    if self.enabled?
                        if @body
                            if @body.gxg_get_state(:hidden) == true
                                self.update_appearance
                                @body.show
                                @opened = true
                            else
                                self.collapse_down
                                @body.hide
                                @opened = false
                            end
                        end
                    end
                end
                on(:mouseenter) do |event|
                    if self.enabled?
                        self.highlight
                    end
                end
                on(:mouseleave) do |event|
                    if self.enabled?
                        self.unhighlight
                    end
                end
                #
                self
            end
            # Slight of hand:
            alias :original_children :children
            def children()
                if @body
                    @body_content.children
                else
                    {}
                end
            end
            #
            alias :original_add_child :add_child
            def add_child(name, element_class, options = {})
                the_object = nil
                if element_class == GxG::Gui::MenuEntry || element_class == GxG::Gui::MenuItem
                    if @body
                        #
                        if @orientation == :horizontal
                            the_row = @body_content.find_child_type(::GxG::Gui::BlockTableRow)
                            unless the_row
                                the_uuid = GxG::uuid_generate.to_sym
                                the_title = "Untitled Component #{the_uuid}"
                                the_row = @body_content.add_child(the_uuid, ::GxG::Gui::BlockTableRow, {:uuid => the_uuid})
                                the_row.set_title(the_title)
                                GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_row)
                            end
                            if the_row
                                the_uuid = GxG::uuid_generate.to_sym
                                the_title = "Untitled Component #{the_uuid}"
                                the_cell = the_row.add_child(the_uuid, ::GxG::Gui::BlockTableCell, {:uuid => the_uuid})
                                the_cell.set_title(the_title)
                                GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_cell)
                                if the_cell
                                    the_object = the_cell.add_child(name, element_class, {:orientation => @orientation, :zone => @zone, :menu => @menu, :parent => self}.merge(options))
                                    # Review: MenuEntry too short issue
                                    self.update_appearance()
                                else
                                    # err - cannot proceed.
                                end
                            else
                                # err - cannot proceed.
                            end
                        else
                            the_uuid = GxG::uuid_generate.to_sym
                            the_title = "Untitled Component #{the_uuid}"
                            the_row = @body_content.add_child(the_uuid, ::GxG::Gui::BlockTableRow, {:uuid => the_uuid})
                            the_row.set_title(the_title)
                            GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_row)
                            if the_row
                                the_uuid = GxG::uuid_generate.to_sym
                                the_title = "Untitled Component #{the_uuid}"
                                the_cell = the_row.add_child(the_uuid, ::GxG::Gui::BlockTableCell, {:uuid => the_uuid})
                                the_cell.set_title(the_title)
                                GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_cell)
                                if the_cell
                                    the_object = the_cell.add_child(name, element_class, {:orientation => @orientation, :zone => @zone, :menu => @menu, :parent => self}.merge(options))
                                    # Review: MenuEntry too short issue
                                    self.update_appearance()
                                else
                                    # err - cannot proceed.
                                end
                            else
                                # err - cannot proceed.
                            end
                        end
                    else
                        # err - cannot proceed
                    end
                else
                    # the_object = self.original_add_child(name, element_class, options)
                    log_warn("MenuEntry only accepts MenuEntry or MenuItem as children, not: #{element_class.inspect} --> Other errors will likely follow.")
                end
                if the_object && @menu
                    @menu.register_entry(the_object)
                end
                the_object
            end
            #
            def entries()
                results = []
                search_pool = self.children.values
                while search_pool.size > 0 do
                    entry = search_pool.shift
                    if entry
                        if entry.is_any?(::GxG::Gui::MenuEntry, ::GxG::Gui::MenuItem)
                            results << entry
                        else
                            entry.children.values.each do |the_child|
                                search_pool << the_child
                            end
                        end
                    end
                end
                results
            end
            # Structure:
            def submenu()
                @submenu
            end
            #
            def opened?()
                @opened
            end
            #
            def set_opened(state=false)
                @opened = state
            end
            #
            def collapse()
                if @body
                    @body.hide
                end
                self.unhighlight
                if @the_parent.respond_to?(:collapse)
                    @the_parent.collapse()
                end
            end
            #
            def collapse_down()
                self.entries.each do |the_child|
                    the_child.collapse_down
                end
                if @body
                    @body.hide
                end
                self.unhighlight
            end
            # Visuals:
            def enabled?()
                @enabled
            end
            def enable()
                @enabled = true
                self.entries.each do |the_child|
                    the_child.enable
                end
                self.gxg_merge_style(:opacity => 1.0)
            end
            def disable()
                @enabled = false
                self.entries.each do |the_child|
                    the_child.disable
                end
                @body.hide
                self.unhighlight
                self.gxg_merge_style(:opacity => 0.5)
            end
            def highlight()
                self.gxg_merge_style({:'background-color' => '#87acd5'})
            end
            def unhighlight()
                self.gxg_merge_style({:'background-color' => '#f2f2f2'})
            end
            def update_appearance()
                # Set @body position according to @orientation and @zone
                rectangle = {:top => 0, :left => 0, :right => 0, :bottom => 0}
                rectangle[:top] = `#{self.element}.getBoundingClientRect().top`.to_i
                rectangle[:left] = `#{self.element}.getBoundingClientRect().left`.to_i
                rectangle[:right] = `#{self.element}.getBoundingClientRect().right`.to_i
                rectangle[:bottom] = `#{self.element}.getBoundingClientRect().bottom`.to_i
                # Review: @menu_item_height * self.entries.size : adjust for border, padding and margin (@menu_item_height * self.entries.size) + border_size ??
                body_settings = {:top => "0px", :left => "0px", :width => "#{@menu_item_width}px", :height => "#{@menu_item_height * self.entries.size}px", :"z-index" => @layer}
                if @submenu == true
                    case @zone
                    when :top, :"top-left", :"top-right"
                        if @orientation == :horizontal
                            body_settings[:top] = "#{(rectangle[:bottom] + 2)}px"
                            body_settings[:left] = "#{rectangle[:left] + @menu_item_width + 2}px"
                        else
                            body_settings[:top] = "#{(rectangle[:bottom] + 2)}px"
                            body_settings[:left] = "#{rectangle[:left] + @menu_item_width + 2}px"
                        end
                    when :left
                        if @orientation == :horizontal
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:right] + 2)}px"
                        else
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:right] + 2)}px"
                        end
                    when :right
                        if @orientation == :horizontal
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:left] - 2 - body_settings[:width])}px"
                        else
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:left] - 2 - body_settings[:width])}px"
                        end
                    when :bottom, :"bottom-left", :"bottom-right"
                        if @orientation == :horizontal
                            body_settings[:top] = "#{(rectangle[:top] - 2 - body_settings[:height])}px"
                            body_settings[:left] = "#{rectangle[:left]}px"
                        else
                            body_settings[:top] = "#{(rectangle[:top] - 2 - body_settings[:height])}px"
                            body_settings[:left] = "#{rectangle[:left]}px"
                        end
                    end
                else
                    case @zone
                    when :top, :"top-left", :"top-right"
                        if @orientation == :horizontal
                            body_settings[:top] = "#{(rectangle[:bottom] + 2)}px"
                            body_settings[:left] = "#{rectangle[:left]}px"
                        else
                            body_settings[:top] = "#{(rectangle[:bottom] + 2)}px"
                            body_settings[:left] = "#{rectangle[:left]}px"
                        end
                    when :left
                        if @orientation == :horizontal
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:right] + 2)}px"
                        else
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:right] + 2)}px"
                        end
                    when :right
                        if @orientation == :horizontal
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:left] - 2 - body_settings[:width])}px"
                        else
                            body_settings[:top] = "#{rectangle[:top]}px"
                            body_settings[:left] = "#{(rectangle[:left] - 2 - body_settings[:width])}px"
                        end
                    when :bottom, :"bottom-left", :"bottom-right"
                        if @orientation == :horizontal
                            body_settings[:top] = "#{(rectangle[:top] - 2 - body_settings[:height])}px"
                            body_settings[:left] = "#{rectangle[:left]}px"
                        else
                            body_settings[:top] = "#{(rectangle[:top] - 2 - body_settings[:height])}px"
                            body_settings[:left] = "#{rectangle[:left]}px"
                        end
                    end
                end
                @body.gxg_merge_style(body_settings)
                #
                self.entries.each do |the_child|
                    the_child.update_appearance
                end
            end
            # Construction:
            def cascade()
                build_list = []
                #
                left_expander = nil
                right_expander = nil
                if @submenu == true
                    case @zone
                    when :top
                        if @orientation == :horizontal
                            right_expander = {:component=>"image", :options=>{:src => self.theme_widget("expand_bottom.svg"), :width=>32, :height=>32, :style => {:clear => "both"}}, :content=>[], :script=>""}
                        else
                            right_expander = {:component=>"image", :options=>{:src => self.theme_widget("expand_right.svg"), :width=>32, :height=>32, :style => {:clear => "both"}}, :content=>[], :script=>""}
                        end
                    when :left, :"top-left", :"bottom-left"
                        right_expander = {:component=>"image", :options=>{:src => self.theme_widget("expand_right.svg"), :width=>32, :height=>32, :style => {:clear => "both"}}, :content=>[], :script=>""}
                    when :right, :"top-right", :"bottom-right"
                        left_expander = {:component=>"image", :options=>{:src => self.theme_widget("expand_left.svg"), :width=>32, :height=>32, :style => {:clear => "both"}}, :content=>[], :script=>""}
                    when :bottom
                        if @orientation == :horizontal
                            right_expander = {:component=>"image", :options=>{:src => self.theme_widget("expand_top.svg"), :width=>32, :height=>32, :style => {:clear => "both"}}, :content=>[], :script=>""}
                        else
                            right_expander = {:component=>"image", :options=>{:src => self.theme_widget("expand_right.svg"), :width=>32, :height=>32, :style => {:clear => "both"}}, :content=>[], :script=>""}
                        end
                    end
                end
                #
                the_icon = nil
                if @icon
                    the_icon = {:component=>"image", :options=>{:src=>@icon, :width=>@icon_width, :height=>@icon_height, :style => {:clear => "both"}}, :content=>[], :script=>""}
                end
                #
                the_label = nil
                if @label
                    the_label = {:component=>"label", :options=>{:content => @label, :style => {:padding => "0px 0px 2px 0px", :"font-size" => "16px"}}, :content=>[], :script=>""}
                end
                #
                the_key = nil
                if @key
                    the_key = {:component=>"label", :options=>{:content => @key, :style => {:padding => "0px 0px 2px 0px", :"font-size" => "16px"}}, :content=>[], :script=>""}
                end
                # grid structure vertical-align:middle;
                left_expander_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px"}}, :content=>[(left_expander)], :script=>""}
                right_expander_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "right", :padding => "0px", :margin => "0px"}}, :content=>[(right_expander)], :script=>""}
                icon_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(the_icon)], :script=>""}
                label_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px 0px 0px 5px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(the_label)], :script=>""}
                key_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "right", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(the_key)], :script=>""}
                entry_row = {:component=>"block_table_row", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px"}}, :content=>[], :script=>""}
                #
                if left_expander
                    entry_row[:content] << left_expander_cell
                end
                #
                if the_icon
                    entry_row[:content] << icon_cell
                end
                #
                if the_label
                    entry_row[:content] << label_cell
                end
                #
                if the_key
                    entry_row[:content] << key_cell
                end
                #
                if right_expander
                    entry_row[:content] << right_expander_cell
                end
                #
                entry_table = {:component=>"block_table", :options=>{:style => {:padding => "0px", :margin => "0px"}}, :content=>[(entry_row)], :script=>""}
                #
                build_list << entry_table
                self.build_interior_components(build_list)
                #
                GxG::DISPATCHER.post_event do
                    self.update_appearance
                end
                #
                true
            end
        end
        #
        class MenuBar < ::GxG::Gui::BlockTable
            def initialize(the_name,the_class,the_options)
                @zone = (the_options.delete(:zone) || "top").to_s.to_sym
                case @zone.clone
                when :top
                    @orientation = (the_options.delete(:orientation) || "horizontal").to_s.to_sym
                when :bottom
                    @orientation = (the_options.delete(:orientation) || "horizontal").to_s.to_sym
                when :left, :"top-left", :"bottom-left"
                    @orientation = (the_options.delete(:orientation) || "vertical").to_s.to_sym
                when :right, :"top-right", :"bottom-right"
                    @orientation = (the_options.delete(:orientation) || "vertical").to_s.to_sym
                else
                    @orientation = (the_options.delete(:orientation) || "horizontal").to_s.to_sym
                end
                @menu_registry = {}
                super(the_name, the_class, the_options)
            end
            #
            def register_entry(the_entry=nil)
                if the_entry.is_any?(::GxG::Gui::MenuEntry, ::GxG::Gui::MenuItem)
                    @menu_registry[(the_entry.uuid)] = the_entry
                    true
                else
                    false
                end
            end
            #
            def unregister_entry(the_reference=nil)
                if the_reference.is_any?(::GxG::Gui::MenuEntry, ::GxG::Gui::MenuItem)
                    @menu_registry.delete(the_reference.uuid)
                    true
                else
                    if the_reference.is_any?(::String, ::Symbol)
                        if GxG::valid_uuid?(the_reference)
                            @menu_registry.delete(the_reference.to_sym)
                            true
                        else
                            @menu_registry.values.each do |the_object|
                                if the_object.title == the_reference
                                    @menu_registry.delete(the_object.uuid)
                                    break
                                end
                            end
                            true
                        end
                    else
                        false
                    end
                end
            end
            #
            def find_entry(the_reference=nil)
                result = nil
                if the_reference.is_any?(::String, ::Symbol)
                    if GxG::valid_uuid?(the_reference)
                        result = @menu_registry[(the_reference.to_sym)]
                    else
                        @menu_registry.values.each do |the_object|
                            if the_object.title == the_reference
                                result = the_object
                                break
                            end
                        end
                    end
                end
                result
            end
            # Slight of hand:
            alias :original_add_child :add_child
            def add_child(name, element_class, options={})
                the_entry = nil
                if element_class == GxG::Gui::MenuEntry
                    if @orientation == :horizontal
                        #
                        the_row = self.find_child_type(::GxG::Gui::BlockTableRow)
                        unless the_row
                            the_uuid = GxG::uuid_generate.to_sym
                            the_title = "Untitled Component #{the_uuid}"
                            the_row = self.original_add_child(the_uuid, ::GxG::Gui::BlockTableRow, {:uuid => the_uuid})
                            the_row.set_title(the_title)
                            GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_row)
                        end
                        if the_row
                            the_uuid = GxG::uuid_generate.to_sym
                            the_title = "Untitled Component #{the_uuid}"
                            the_cell = the_row.add_child(the_uuid, ::GxG::Gui::BlockTableCell, {:uuid => the_uuid})
                            the_cell.set_title(the_title)
                            GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_cell)
                            if the_cell
                                the_entry = the_cell.add_child(name, element_class, {:orientation => @orientation, :zone => @zone, :parent => self, :menu => self}.merge(options))
                                # Review : MenuEntry too short issue
                                the_entry.update_appearance()
                            else
                                # err - cannot proceed.
                            end
                        else
                            # err - cannot proceed.
                        end
                    else
                        the_uuid = GxG::uuid_generate.to_sym
                        the_title = "Untitled Component #{the_uuid}"
                        the_row = self.original_add_child(the_uuid, ::GxG::Gui::BlockTableRow, {:uuid => the_uuid})
                        the_row.set_title(the_title)
                        GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_row)
                        if the_row
                            the_uuid = GxG::uuid_generate.to_sym
                            the_title = "Untitled Component #{the_uuid}"
                            the_cell = the_row.add_child(the_uuid, ::GxG::Gui::BlockTableCell, {:uuid => the_uuid})
                            the_cell.set_title(the_title)
                            GxG::DISPLAY_DETAILS[:object].register_object(the_title, the_cell)
                            if the_cell
                                the_entry = the_cell.add_child(name, element_class, {:orientation => @orientation, :zone => @zone, :parent => self, :menu => self}.merge(options))
                                # Review : MenuEntry too short issue
                                the_entry.update_appearance()
                            else
                                # err - cannot proceed.
                            end
                        else
                            # err - cannot proceed.
                        end
                    end
                else
                    # the_entry = self.original_add_child(name, element_class, options)
                    log_warn("MenuBar only accepts MenuEntry as children, not: #{element_class.inspect} --> Other errors will likely follow.")
                end
                if the_entry
                    self.register_entry(the_entry)
                end
                the_entry
            end
            #
            def entries()
                results = []
                search_pool = self.children.values
                while search_pool.size > 0 do
                    entry = search_pool.shift
                    if entry
                        if entry.is_a?(::GxG::Gui::MenuEntry)
                            results << entry
                        else
                            unless entry.is_a?(::GxG::Gui::MenuItem)
                                entry.children.values.each do |the_child|
                                    search_pool << the_child
                                end
                            end
                        end
                    end
                end
                results
            end
            #
            def collapse_down()
                self.entries.each do |the_child|
                    the_child.collapse_down
                end
            end
            #
            def update_appearance()
                self.entries.each do |the_child|
                    the_child.update_appearance
                end
            end
            #
            def select_item(the_menu_item=nil)
                log_warn("Override this method in object script")
            end
        end
        # Tabbed Regions Support
        class TabSet < ::GxG::Gui::BlockTable
            # OK - basic idea:
            # Row0: tab labels in cells. :mouseup = hide others, show only designated Tab object as body.
            # Row1: Tab content objects
            def initialize(the_name,the_class,the_options)
                # tab show/hide :transitions:
                @transition_show = nil
                @transition_hide = nil
                the_transitions = the_options.delete(:transition)
                if the_transitions.is_a?(::Hash)
                    if the_transitions[:show].is_a?(::Hash)
                        @transition_show = the_transitions[:show]
                    end
                    if the_transitions[:hide].is_a?(::Hash)
                        @transition_hide = the_transitions[:hide]
                    end
                end
                #
                @tabs = {}
                @tab_row = nil
                @content_row = nil
                #
                super(the_name, the_class, the_options)
            end
            # Slight of hand:
            alias :original_add_child :add_child
            def add_child(name, element_class, options={})
                result = nil
                # Only accept ::GxG::Gui::Tab items as children
                if element_class == ::GxG::Gui::Tab
                    if @tab_row && @content_row
                        # LabelCell
                        label_cell_uuid = ::GxG::uuid_generate.to_sym
                        label_cell_title = "Untitled Component #{label_cell_uuid.to_s}"
                        # Re-distribute :width of each label over total width:
                        label_cell = @tab_row.add_child(label_cell_uuid, ::GxG::Gui::BlockTableCell, {:uuid => label_cell_uuid})
                        label_cell.set_title(label_cell_title)
                        # GxG::DISPLAY_DETAILS[:object].register_object(label_cell_title, label_cell) ??
                        # ContentCell
                        content_cell_uuid = ::GxG::uuid_generate.to_sym
                        content_cell_title = "Untitled Component #{content_cell_uuid.to_s}"
                        content_cell = @content_row.add_child(content_cell_uuid, ::GxG::Gui::BlockTableCell, {:uuid => content_cell_uuid})
                        content_cell.set_title(content_cell_title)
                        # GxG::DISPLAY_DETAILS[:object].register_object(content_cell_title, content_cell) ??
                        content_cell.hide
                        # TabItem
                        # Needs: :tabset => obj, :label_cell => obj, :content_cell => obj
                        the_tab_item = label_cell.add_child(name, element_class, (options || {}).merge({:tabset => self, :label_cell => label_cell, :content_cell => content_cell}))
                        if the_tab_item
                            @tabs[(name.to_s.to_sym)] = the_tab_item
                            result = the_tab_item
                            # Review: where else to put this??
                            if @tabs.keys.size > 1
                                total_width = (`#{self.element}.getBoundingClientRect().right`.to_i - `#{self.element}.getBoundingClientRect().left`.to_i).to_f
                                the_width = "#{((total_width / @tabs.keys.size.to_f) / total_width) * 100.0}%"
                            else
                                the_width = "100.0%"
                            end
                            @tabs.values.each do |the_tab|
                                the_tab.width = the_width
                            end
                            # GxG::DISPLAY_DETAILS[:object].register_object(name, the_tab_item) (already done by build_components ??)
                        end
                    end
                    #
                end
                result
            end
            #
            alias :original_children :children
            def children()
                if @tabs
                    @tabs
                else
                    {}
                end
            end
            #
            def find_child(the_reference=nil, interior=false)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                if interior == true
                    search_queue = self.original_children.values
                else
                    search_queue = self.children.values
                end
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def size()
                @tabs.keys.size
            end
            #
            def reference_tab(specifier=nil)
                result = nil
                check = nil
                if GxG::valid_uuid?(specifier)
                    check = :uuid
                else
                    if specifier.is_any?(::String, ::Symbol)
                        check = :reference
                    else
                        if specifier.is_a?(::GxG::Gui::Tab)
                            check = :instance
                        else
                            if specifier.is_a?(::Numeric)
                                check = :index
                            end
                        end
                    end
                end
                case check
                when :uuid
                    @tabs.each_pair do |the_ref, the_instance|
                        if the_instance.uuid.to_s.to_sym == specifier.to_s.to_sym
                            result = @tabs[(the_ref)]
                            break
                        end
                    end
                when :reference
                    result = @tabs[(specifier.to_s.to_sym)]
                when :index
                    result = @tabs[(@tabs.keys[(specifier.to_i)])]
                when :instance
                    @tabs.each_pair do |the_ref, the_instance|
                        if the_instance == specifier
                            result = @tabs[(the_ref)]
                            break
                        end
                    end
                end
                result
            end
            #
            def detach_tab(specifier=nil)
                # This should only be called from a Tab instance.
                result = nil
                check = nil
                if GxG::valid_uuid?(specifier)
                    check = :uuid
                else
                    if specifier.is_any?(::String, ::Symbol)
                        check = :reference
                    else
                        if specifier.is_a?(::GxG::Gui::Tab)
                            check = :instance
                        else
                            if specifier.is_a?(::Numeric)
                                check = :index
                            end
                        end
                    end
                end
                case check
                when :uuid
                    @tabs.each_pair do |the_ref, the_instance|
                        if the_instance.uuid.to_s.to_sym == specifier.to_s.to_sym
                            result = @tabs.delete(the_ref)
                            break
                        end
                    end
                when :reference
                    result = @tabs.delete(specifier.to_s.to_sym)
                when :index
                    result = @tabs.delete(@tabs.keys[(specifier.to_i)])
                when :instance
                    @tabs.each_pair do |the_ref, the_instance|
                        if the_instance == specifier
                            result = @tabs.delete(the_ref)
                            break
                        end
                    end
                end
                result
            end
            #
            def cascade()
                build_list = []
                tab_row_id = "Tabs Row"
                content_row_id = "Content Row"
                #
                tab_row = {:component=>"block_table_row", :options=>{:title => tab_row_id, :style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "32px", :"background-color" => "transparent"}}, :content=>[], :script=>""}
                tab_table = {:component=>"block_table", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "32px", :"background-color" => "transparent"}}, :content=>[(tab_row)], :script=>""}
                tab_area_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle', :"background-color" => "transparent"}}, :content=>[(tab_table)], :script=>""}
                tab_area_row = {:component=>"block_table_row", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "32px", :"background-color" => "transparent"}}, :content=>[(tab_area_cell)], :script=>""}
                #
                content_row = {:component=>"block_table_row", :options=>{:title => content_row_id, :style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "100%"}}, :content=>[], :script=>""}
                content_table = {:component=>"block_table", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "100%"}}, :content=>[(content_row)], :script=>""}
                content_area_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(content_table)], :script=>""}
                content_area_row = {:component=>"block_table_row", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "100%"}}, :content=>[(content_area_cell)], :script=>""}
                #
                build_list << tab_area_row
                build_list << content_area_row
                #
                self.build_interior_components(build_list)
                #
                @tab_row = self.find_child(tab_row_id, true)
                @content_row = self.find_child(content_row_id, true)
                true
            end
            # Selection
            def select_tab(specifier=nil,&block)
                the_tab = self.reference_tab(specifier)
                if the_tab
                    @tabs.values.each do |a_tab|
                        if a_tab.visible? && (a_tab != the_tab)
                            a_tab.hide(@transition_hide) do
                                unless the_tab.visible?
                                    the_tab.show(@transition_show,&block)
                                end
                            end
                        else
                            if a_tab == the_tab
                                unless the_tab.visible?
                                    the_tab.show(@transition_show,&block)
                                end
                            end
                        end
                    end
                end
            end
            #
        end
        #
        class Tab < ::GxG::Gui::BlockTable
            # goes within TabSet only
            def initialize(the_name,the_class,the_options)
                # {:tabset => self, :label_object => label_cell, :content_object => content_cell}
                @tabset = the_options.delete(:tabset)
                @label_area = the_options.delete(:label_cell)
                @content_area = the_options.delete(:content_cell)
                unless (@tabset && @label_area && @content_area)
                    raise Exception, "Improperly initialized Tab object: create by adding to a TabSet."
                end
                if the_options.delete(:closeable) == true
                    @closeable = true
                else
                    @closeable = false
                end
                if the_options.delete(:enabled) == false
                    @enabled = false
                else
                    @enabled = true
                end
                if the_options[:content].is_a?(::String)
                    @label_text = the_options.delete(:content)
                else
                    @label_text = "Untitled"
                end
                @label_object = nil
                @tab_height = 24
                @tab_width = "100%"
                @visible = false
                #
                super(the_name, the_class, the_options)
            end
            #
            def destroy()
                if @tabset
                    if @tabset.detach_tab(self)
                        if @content_area
                            @content_area.hide()
                            @content_area.destroy()
                            @content_area = nil
                        end
                        if @label_area
                            @label_area.hide()
                            @label_area.destroy()
                            @label_area = nil
                        end
                        @tabset = nil
                    end
                end
            end
            #
            alias :original_children :children
            def children()
                if @content_area
                    @content_area.children()
                else
                    {}
                end
            end
            #
            def find_child(the_reference=nil, interior=false)
                result = nil
                if GxG::valid_uuid?(the_reference)
                    uuid_check = true
                else
                    uuid_check = false
                end
                if interior == true
                    search_queue = self.original_children.values
                else
                    search_queue = self.children.values
                end
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if uuid_check
                            if entry.uuid == the_reference
                                result = entry
                                break
                            end
                        else
                            if entry.title == the_reference
                                result = entry
                                break
                            end
                        end
                        unless result
                            entry.children.values.each do |the_child|
                                search_queue << the_child
                            end
                        end
                    end
                end
                result
            end
            #
            def cascade()
                build_list = []
                # Build up Label
                tab_label_row = {:component=>"block_table_row", :options=>{:style => {:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "100%"}}, :content=>[], :script=>""}
                # Close Box
                if @closeable == true
                    close_box = {:component=>"image", :options=>{:src => theme_widget("close.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}, :content=>[], :script=>""}
                    close_box[:script] = "
                    on(:mouseup) do |event|
                        `alert('Closebox Selected')`
                    end
                    on(:mousedown) do |event|
                        unless self.gxg_get_state(:disabled) == true
                            self.gxg_set_attribute(:src,theme_widget('close_mousedown.png'))
                        end
                    end
                    on(:mouseenter) do |event|
                        unless self.gxg_get_state(:disabled) == true
                            self.gxg_set_attribute(:src,theme_widget('close_mouseenter.png'))
                        end
                    end
                    on(:mouseleave) do |event|
                        unless self.gxg_get_state(:disabled) == true
                            self.gxg_set_attribute(:src,theme_widget('close.png'))
                        end
                    end
                    "
                    tab_close_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle'}}, :content=>[(close_box)], :script=>""}
                    tab_label_row[:content] << tab_close_cell
                end
                # Label
                # label_obj_id = ::GxG::uuid_generate()
                the_label = {:component=>"label", :options=>{:title => "Tab Label Object", :content => @label_text, :style => {:width => "100%", :"font-size" => "16px", :"text-align" => "center"}}, :content=>[], :script=>""}
                unless @enabled == true
                    the_label[:options][:style][:"font-color"] = "#c2c2c2"
                end
                the_label[:script] = "
                on(:mouseup) do |event|
                    `alert('Label Selected')`
                end
                "
                tab_label_cell = {:component=>"block_table_cell", :options=>{:style => {:float => "left", :padding => "0px", :margin => "0px", :'vertical-align' => 'middle', :overflow => "hidden"}}, :content=>[(the_label)], :script=>""}
                tab_label_row[:content] << tab_label_cell
                tab_label_row[:script] = "
                on(:mouseup) do |event|
                    `alert('Row Selected')`
                end
                "
                #
                build_list << tab_label_row
                #
                self.gxg_merge_style({:clear => "both", :padding => "0px", :margin => "0px", :width => "100%", :height => "#{@tab_height}px", :"background-color" => "#f2f2f2", :"border-radius" => "5px 5px 0px 0px", :overflow => "hidden", :"border-bottom" => "1px solid #c2c2c2"})
                #
                self.build_interior_components(build_list)
                #
                @label_object = self.find_child("Tab Label Object",true)
                true
            end
            # Visuals:
            def width()
                if @label_area
                    @tab_width
                end
            end
            def width=(the_width=nil)
                if @label_area && the_width
                    # set/get width of @label_area (a cell) to control tab width. ????
                    if the_width.is_a?(::Numeric)
                        the_width = "#{the_width}px"
                    end
                    @tab_width = the_width
                    @label_area.gxg_merge_style({:width => @tab_width})
                end
            end
            #
            def visible?()
                @visible
            end
            #
            def show(transition=nil, &block)
                self.gxg_merge_style({:"border-bottom" => "none"})
                @visible = true
                @content_area.show(transition,&block)
            end
            #
            def hide(transition=nil, &block)
                @content_area.hide(transition) do
                    if block.respond_to?(:call)
                        block.call()
                    end
                    self.gxg_merge_style({:"border-bottom" => "1px solid #c2c2c2"})
                    @visible = false
                end
            end
            # State:
            def enabled?()
                @enabled
            end
            def enable()
                @enabled = true
                @label_object.gxg_merge_style({:"font-color" => "#000000"})
            end
            def disable()
                @enabled = false
                @label_object.gxg_merge_style({:"font-color" => "#c2c2c2"})
            end
            # Selection
            def selected?()
                self.visible?
            end
            def select()
                if @enabled == true
                    @tabset.select_tab(self)
                end
            end
            # Methods to override:
            def before_open(options={})
            end
            def open(options={})
            end
            def after_open(options={})
            end
            def before_close(options={})
            end
            def close(options={})
            end
            def after_close(options={})
            end
            #
        end
        #
         class Variable < ::Ferro::Element::Var
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             # Creates any kind of element depending on option :domtype.
         end
         # ### Compound Items
         #
         class SearchForm < ::Ferro::Combo::Search
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             # # Override this method to specify what happens when
             # submit button is clicked or enter key is pressed.
             #
             # @param [String] value The value of the text input.
             # def submitted(value);end
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
         end
         #
         class PopUpMenu < ::Ferro::Combo::PullDown
            #
            def _before_create
                if @options[:uuid]
                    @uuid = @options.delete(:uuid).to_s.to_sym
                end
                super()
            end
            #
            def uuid()
                @uuid
            end
             # Creates a simple pull-down menu.
             # Specify option :title to set the menu title text.
             # Specify option :items as an Array of Ferro classes.
             # Each class should be something clickable, for instance a
             # FormBlock. These classes will be instanciated by
             # this element.
             include GxG::Gui::AnimationSupport
             include GxG::Gui::ApplicationSupport
             include GxG::Gui::ThemeSupport
         end
         # -----------------------------------------------------------------------------
        COMPONENT_CLASSES = {
            :header => ::GxG::Gui::Header,
            :navigator => ::GxG::Gui::Navigator,
            :section => ::GxG::Gui::Section,
            :article => ::GxG::Gui::Article,
            :aside => ::GxG::Gui::Aside,
            :footer => ::GxG::Gui::Footer,
            :form => ::GxG::Gui::Form,
            :clickable => ::GxG::Gui::Clickable,
            :fieldset => ::GxG::Gui::Fieldset,
            :text_input => ::GxG::Gui::TextInput,
            :password_input => ::GxG::Gui::PasswordInput,
            :reset_input => ::GxG::Gui::ResetInput,
            :radio_button => ::GxG::Gui::RadioButton,
            :color_picker => ::GxG::Gui::ColorPicker,
            :date_picker => ::GxG::Gui::DatePicker,
            :datetime_local => ::GxG::Gui::DateTimeLocal,
            :email_input => ::GxG::Gui::EmailInput,
            :month_picker => ::GxG::Gui::MonthPicker,
            :number_input =>::GxG::Gui::NumberInput,
            :range_input => ::GxG::Gui::RangeInput,
            :search_input => ::GxG::Gui::SearchInput,
            :phone_input => ::GxG::Gui::PhoneInput,
            :time_picker => ::GxG::Gui::TimePicker,
            :url_input => ::GxG::Gui::UrlInput,
            :week_picker => ::GxG::Gui::WeekPicker,
            :label => ::GxG::Gui::Label,
            :text_area => ::GxG::Gui::TextArea,
            :output => ::GxG::Gui::Output,
            :button_input => ::GxG::Gui::ButtonInput,
            :submit_button => ::GxG::Gui::SubmitButton,
            :click_block => ::GxG::Gui::ClickBlock,
            :checkbox => ::GxG::Gui::CheckBox,
            :selector => ::GxG::Gui::Selector,
            :block => ::GxG::Gui::Block,
            :text => ::GxG::Gui::Text,
            :list => ::GxG::Gui::List,
            :ordered_list => ::GxG::Gui::OrderedList,
            :list_item => ::GxG::Gui::ListItem,
            :anchor => ::GxG::Gui::Anchor,
            :external_link => ::GxG::Gui::ExternalLink,
            :button => ::GxG::Gui::Button,
            :image => ::GxG::Gui::Image,
            :video => ::GxG::Gui::Video,
            :canvas => ::GxG::Gui::Canvas,
            :script => ::GxG::Gui::Script,
            :application_viewport => ::GxG::Gui::ApplicationViewport,
            :search_form => ::GxG::Gui::SearchForm,
            :popupmenu => ::GxG::Gui::PopUpMenu,
            :table => ::GxG::Gui::Table,
            :table_header => ::GxG::Gui::TableHeader,
            :table_row => ::GxG::Gui::TableRow,
            :table_cell => ::GxG::Gui::TableCell,
            :block_table => ::GxG::Gui::BlockTable,
            :block_table_header => ::GxG::Gui::BlockTableHeader,
            :block_table_row => ::GxG::Gui::BlockTableRow,
            :block_table_cell => ::GxG::Gui::BlockTableCell,
            :window => ::GxG::Gui::Window,
            :dialog_box => ::GxG::Gui::DialogBox,
            :panel => ::GxG::Gui::Panel,
            :tree => ::GxG::Gui::Tree,
            :tree_node => ::GxG::Gui::TreeNode,
            :menu_bar => ::GxG::Gui::MenuBar,
            :menu_entry => ::GxG::Gui::MenuEntry,
            :menu_item => ::GxG::Gui::MenuItem,
            :tabset => ::GxG::Gui::TabSet,
            :tab => ::GxG::Gui::Tab
        }
        #
        def self.component_class(the_type_specifier=nil)
            result = nil
            if the_type_specifier
                result = GxG::Gui::COMPONENT_CLASSES[(the_type_specifier.to_s.to_sym)]
            end
            result
        end
        #
        def self.class_component(the_class_specifier=nil)
            result = nil
            if the_class_specifier
                found_index = GxG::Gui::COMPONENT_CLASSES.values.index(the_class_specifier)
                if found_index
                    result = GxG::Gui::COMPONENT_CLASSES.keys[(found_index)]
                end
            end
            result
        end
        #
        def self.component_registered?(the_specifier=nil)
            if GxG::Gui::component_class(the_specifier)
                true
            else
                false
            end
        end
        #
        def self.register_component_class(the_specifier=nil, the_constant=nil)
            if the_specifier.is_any?(::String, ::Symbol) && the_constant.is_a?(::Class)
                if GxG::Gui::component_registered(the_specifier.to_s.to_sym)
                    if GxG::Gui::component_class(the_specifier.to_s.to_sym) != the_constant
                        GxG::Gui::COMPONENT_CLASSES[(the_specifier.to_s.to_sym)] = the_constant
                        true
                    else
                        log_warn("Component Class #{the_specifier.to_s.to_sym.inspect} => #{the_constant.inspect} already defined.")
                        false
                    end
                else
                    GxG::Gui::COMPONENT_CLASSES[(the_specifier.to_s.to_sym)] = the_constant
                    true
                end
            else
                false
            end
        end
        # Set the valid component classes for animations:
        class Animation
            # This is intentional - keep this modification (!)
            def self.valid_components()
                ::GxG::Gui::COMPONENT_CLASSES.values
            end
        end
        #
        # --------------------------------------------------------------------------------------------------------------------------------------
        #
        class Page < Ferro::Document
            #
            # Override in your Page Script:
            def run(data=nil)
            end
            #
            include GxG::Gui::EventHandlers
            #
            def element()
                `document.body`
            end
            #
            def find_object_by_id(the_id=nil)
                result = nil
                if the_id.is_a?(::Numeric)
                    the_id = ("_" + the_id.to_i.to_s())
                else
                    the_id = the_id.to_s
                end
                search_queue = [(self)]
                while search_queue.size > 0 do
                    entry = search_queue.shift
                     
                    attrib = `#{entry.element()}.attributes.getNamedItem('id') || 0`
                    unless `#{attrib} == 0`
                        attrib = `#{attrib}.value`
                        if `(#{attrib.to_s} == #{the_id.to_s})`
                            result = entry
                            break
                        end
                    end
                    if entry.respond_to?(:children)
                        entry.children.keys.each do |the_child_key|
                            attrib = `#{entry.children[(the_child_key)].element()}.attributes.getNamedItem('id') || 0`
                            unless `#{attrib} == 0`
                                attrib = `#{attrib}.value`
                                if `(#{attrib.to_s} == #{the_id.to_s})`
                                    result = entry.children[(the_child_key)]
                                    break
                                else
                                    search_queue << entry.children[(the_child_key)]
                                end
                            end
                        end
                    end
                end
                result
            end
            #
             def find_object(object_name=nil)
                 result = nil
                 search_queue = [(self)]
                 while search_queue.size > 0 do
                     entry = search_queue.shift
                     if entry.respond_to?(:children)
                         if entry.children[(object_name)]
                             result = entry.children[(object_name)]
                             break
                         else
                             entry.children.keys.each do |the_child|
                                 search_queue << entry.children[(the_child)]
                             end
                         end
                     end
                 end
                 result
            end
            #
            def find_object_by_title(the_title=nil)
                result = nil
                if GxG::valid_uuid?(the_title)
                    uuid_check = true
                else
                    uuid_check = false
                end
                @title_registry.keys.each do |the_uuid|
                    if uuid_check == true
                        if @title_registry[(the_uuid)].to_s.include?(the_title.to_s)
                            result = self.find_object(the_uuid)
                            break
                        end
                    else
                        if the_title == @title_registry[(the_uuid)]
                            result = self.find_object(the_uuid)
                            break
                        end
                    end
                end
                result
            end
            #
            def register_object(the_title=nil, the_object=nil)
                if the_title && the_object
                    @title_registry[(the_object.uuid)] = the_title.to_s
                    true
                else
                    false
                end
            end
            #
            def unregister_object(the_title=nil)
                if the_title
                    the_object = self.find_object_by_title(the_title)
                    if the_object
                        @title_registry.delete(the_object.uuid)
                    end
                    true
                else
                    false
                end
            end
            #
            def initialize(the_display_path=nil)
                super()
                @busy = false
                @theme = "default"
                # Review : prepend @theme_prefix with the page 'relative_url' value (see GxG::CONNECTION)
                @theme_prefix = (::GxG::CONNECTION.relative_url() + "/themes/default")
                @window_switcher = nil
                @window_registry = {}
                @dialog = nil
                @dialog_queue = []
                @title_registry = {}
                @style_data = {}
                @layout = {:"top-left" => {}, :top => {}, :"top-right" => {}, :right => {}, :"bottom-right" => {}, :bottom => {}, :"bottom-left" => {}, :left => {}}
                @layout_content_area = {:top => 0, :left => 0, :bottom => `window.innerHeight`.to_i, :right => `window.innerWidth`.to_i}
                @uuid = nil
                @display_path = the_display_path
                # Supports windowing:
                on(:mousemove) do |event|
                    if event
                        GxG::DISPLAY_DETAILS[:mouse_x] = event[:pageX]
                        GxG::DISPLAY_DETAILS[:mouse_y] = event[:pageY]
                        GxG::DISPLAY_DETAILS[:mousedown] = ((event[:buttons] & 1) == 1)
                    end
                end
                #
                ::GxG::DISPATCHER.post_event(:display) do
                    if GxG::CONNECTION.open?
                        ::GxG::DISPLAY_DETAILS[:object].start(`window.location.pathname`)
                    end
                end
                #
                self
            end
            #
            def uuid()
                @uuid
            end
            # Busy/Unbusy Supports:
            def busy()
                @busy
            end
            def set_busy(state=false)
                if state == true
                    unless @busy == true
                        busy_overlay = {:component => "block", :options => {:title => "gxg_wait_overlay", :style => {:cursor => "wait", :opacity => 0.01, :"background-color" => "#ffffff", :position => "absolute", :top => "0px", :left => "0px", :width => "100%", :height => "100%", :"z-index" => 9999}}, :content => [], :script => ""}
                        busy_overlay[:script] = "
                        on(:mouseup,true) do |event|
                        end
                        on(:mousedown,true) do |event|
                        end
                        on(:mousemove,true) do |event|
                        end
                        on(:mouseenter,true) do |event|
                        end
                        on(:mouseleave,true) do |event|
                        end
                        "
                        self.build_components([{:parent => nil, :record => {:content => [(busy_overlay)]}, :element => self}])
                        @busy = true
                    end
                else
                    if @busy == true
                        busy_overlay = self.find_object_by_title("gxg_wait_overlay")
                        if busy_overlay
                            self.unregister_object("gxg_wait_overlay")
                            busy_overlay.destroy
                        end
                        @busy = false
                    end
                end
                @busy
            end
            # Theme Supports:
            def site_asset(asset_path=nil)
                if (`window.location['href']`).include?("https://")
                    host_prefix = ("https://" + `window.location['host']`)
                else
                    host_prefix = ("http://" + `window.location['host']`)
                end
                if ::GxG::CONNECTION.relative_url()[0] != "/"
                    host_prefix = (host_prefix + "/")
                end
                if asset_path
                    (host_prefix + File.expand_path((::GxG::CONNECTION.relative_url() + "/" + asset_path.to_s)))
                else
                    ""
                end
            end
            #
            def theme_icon(image_name=nil)
                if image_name
                    (@theme_prefix + "/icons/" + image_name.to_s)
                else
                    ""
                end
            end
            #
            def theme_background(image_name=nil)
                if image_name
                    (@theme_prefix + "/backgrounds/" + image_name.to_s)
                else
                    ""
                end
            end
            #
            def theme_widget(image_name=nil)
                if image_name
                    (@theme_prefix + "/widgets/" + image_name.to_s)
                else
                    ""
                end
            end
            #
            def theme_font(font_name=nil)
                if font_name
                    (@theme_prefix + "/fonts/" + font_name.to_s)
                else
                    ""
                end
            end
            #
            def theme_window_title_layout()
                {:left => [:close, :minimize, :maximize], :center => [:title], :right => []}
            end
            # Layout System Supports:
            def layout_refresh()
                # get rectangle of item -> convert to page % offsets
                # `window.innerHeight`.to_i
                # `window.innerWidth`.to_i
                # <element>.getClientRects()[0].left
                page_width = `window.innerWidth`.to_i
                # Calculating proper page height, See: https://stackoverflow.com/questions/1145850/how-to-get-height-of-entire-document-with-javascript
                body = `document.body`
                html = `document.documentElement`
                page_bottom = 0
                %x{
                    page_bottom = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);
                }
                page_height = [(`window.innerHeight`.to_i),(page_bottom.to_i)].max
                # bounding areas:
                top_bound = 0.0
                left_bound = 0.0
                right_bound = 1.0
                bottom_bound = 1.0
                # Update object percentages
                [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].each do |the_position|
                    @layout[(the_position)].each_pair do |the_uuid,the_record|
                        object = self.find_object(the_uuid)
                        if object
                            rectangle = {:top => 0, :left => 0, :right => 0, :bottom => 0}
                            rectangle[:top] = `#{object.element}.getBoundingClientRect().top`.to_i
                            rectangle[:left] = `#{object.element}.getBoundingClientRect().left`.to_i
                            rectangle[:right] = `#{object.element}.getBoundingClientRect().right`.to_i
                            rectangle[:bottom] = `#{object.element}.getBoundingClientRect().bottom`.to_i
                            percentages = {:top => 0.0, :left => 0.0, :right => 0.0, :bottom => 0.0}
                            percentages[:top] = (rectangle[:top].to_f / page_height.to_f)
                            percentages[:left] = (rectangle[:left].to_f / page_width.to_f)
                            percentages[:right] = (rectangle[:right].to_f / page_width.to_f)
                            percentages[:bottom] = (rectangle[:bottom].to_f / page_height.to_f)
                            @layout[(the_position.to_s.to_sym)][(the_uuid.to_s.to_sym)] = percentages
                        end
                    end
                end
                #
                [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].each do |the_position|
                    @layout[(the_position)].values.each do |the_record|
                        case the_position
                        when :top
                            if the_record[:bottom] > top_bound
                                top_bound = the_record[:bottom]
                            end
                        when :left
                            if the_record[:right] > left_bound
                                left_bound = the_record[:right]
                            end
                        when :right
                            if the_record[:left] < right_bound
                                right_bound = the_record[:left]
                            end
                        when :bottom
                            if the_record[:top] < bottom_bound
                                bottom_bound = the_record[:top]
                            end
                        when :"top-left"
                            if the_record[:bottom] > top_bound
                                top_bound = the_record[:bottom]
                            end
                            if the_record[:right] > left_bound
                                left_bound = the_record[:right]
                            end
                        when :"top-right"
                            if the_record[:bottom] > top_bound
                                top_bound = the_record[:bottom]
                            end
                            if the_record[:left] < right_bound
                                right_bound = the_record[:left]
                            end
                        when :"bottom-right"
                            if the_record[:top] < bottom_bound
                                bottom_bound = the_record[:top]
                            end
                            if the_record[:left] < right_bound
                                right_bound = the_record[:left]
                            end
                        when :"bottom-left"
                            if the_record[:top] < bottom_bound
                                bottom_bound = the_record[:top]
                            end
                            if the_record[:right] > left_bound
                                left_bound = the_record[:right]
                            end
                        end
                    end
                end
                @layout_content_area = {:top => 0, :left => 0, :bottom => page_height, :right => page_width, :page_width => page_width, :page_height => page_height}
                @layout_content_area[:top] = (top_bound * page_height.to_f).to_i
                @layout_content_area[:top_percent] = top_bound * 100.0
                @layout_content_area[:left] = (left_bound * page_width.to_f).to_i
                @layout_content_area[:left_percent] = left_bound * 100.0
                @layout_content_area[:right] = (right_bound * page_width.to_f).to_i
                @layout_content_area[:right_percent] = right_bound * 100.0
                @layout_content_area[:bottom] = (bottom_bound * page_height.to_f).to_i
                @layout_content_area[:bottom_percent] = bottom_bound * 100.0
                true
            end
            #
            def layout_add_item(the_uuid=nil, the_position=nil, refresh=true)
                # store by uuid in position's record
                if [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].include?(the_position.to_s.to_sym)
                    #
                    @layout[(the_position.to_s.to_sym)][(the_uuid.to_s.to_sym)] = {:top => 0.0, :left => 0.0, :right => 0.0, :bottom => 0.0}
                    if refresh
                        self.layout_refresh
                    end
                    #
                    true
                else
                    false
                end
            end
            #
            def layout_remove_item(the_uuid=nil)
                [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].each do |the_position|
                    if @layout[(the_position.to_s.to_sym)][(the_uuid.to_s.to_sym)]
                        @layout[(the_position.to_s.to_sym)].delete((the_uuid.to_s.to_sym))
                        break
                    end
                end
                self.layout_refresh
                #
                true
            end
            #
            def layout_content_area()
                @layout_content_area
            end
            # Window Manager:
            # Dialog Box supports:
            def dialog_open(build_source=nil, the_application=nil, details=nil, &block)
                if build_source.is_any?(::Hash, GxG::Database::PersistedHash)
                    if build_source.is_a?(GxG::Database::PersistedHash)
                        the_uuid = build_source.uuid
                        the_options = build_source[:options].unpersist
                        if the_options[:title]
                            the_title = the_options.delete(:title)
                        else
                            the_title = build_source.title
                        end
                    else
                        the_uuid = GxG::uuid_generate.to_sym
                        the_options = build_source[:options].clone
                        the_title = the_options.delete(:title)
                    end
                    the_style = the_options.delete(:style)
                    the_states = (the_options.delete(:states) || {})
                    new_window = GxG::DISPLAY_DETAILS[:object].add_child(the_uuid, GxG::Gui::DialogBox, the_options)
                    if new_window
                        new_window.set_title(the_title)
                        # Set states:
                        unless the_states.keys.include?(:hidden)
                            the_states[:hidden] = false
                        end
                        new_window.gxg_set_states(the_states)
                        # process style info:
                        if the_style.is_a?(::Hash)
                            new_window.gxg_set_style(the_style)
                        end
                        if the_application.is_a?(::GxG::Application)
                            new_window.set_application(the_application)
                            unless the_application.get_window(the_uuid)
                                the_application.link_window(new_window)
                            end
                        end
                        # Set details if provided
                        if details
                            new_window.set_data(details)
                        end
                        # Set Script if any is provided
                        if build_source[:script].size > 0
                            new_window.set_script(build_source[:script].to_s)
                        end
                        # Set Callback
                        if block.respond_to?(:call)
                            new_window.set_responder(block)
                        end
                        #
                        if @dialog.is_a?(::GxG::Gui::DialogBox)
                            @dialog_queue << new_window
                            self.register_object(the_title, new_window)
                            self.build_components([{:parent => GxG::DISPLAY_DETAILS[:object], :record => build_source, :element => new_window}],the_application)
                            #
                        else
                            @dialog = new_window
                            self.register_object(the_title, new_window)
                            self.build_components([{:parent => GxG::DISPLAY_DETAILS[:object], :record => build_source, :element => new_window}],the_application)
                            new_window.before_open()
                            new_window.open()
                            new_window.show({:origin => {:opacity => 0.0}, :destination => {:opacity => 1.0}})
                            new_window.after_open()
                        end
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def dialog_close(options={})
                if @dialog.is_a?(::GxG::Gui::DialogBox)
                    @dialog.before_close()
                    close_procedure = Proc.new do
                        @dialog.close()
                        @dialog.after_close()
                        @dialog.gxg_every_child do |the_child|
                            if the_child.is_a?(::GxG::Gui::ApplicationViewport)
                                the_application = the_child.application
                                if the_application
                                    the_application.unlink_viewport(the_child.title)
                                end
                            end
                        end
                        self.unregister_object(@dialog.title)
                        @dialog.destroy
                        @dialog = nil
                        if @dialog_queue.size > 0
                            @dialog = @dialog_queue.shift
                            @dialog.before_open
                            @dialog.open
                            @dialog.show({:origin => {:opacity => 0}, :destination => {:opacity => 1}, :options => {:duration => 500}})
                            @dialog.after_open
                        end
                    end
                    if options[:origin] && options[:destination]
                        @dialog.hide(options, &close_procedure)
                    else
                        @dialog.hide({:origin => {:opacity => 1}, :destination => {:opacity => 0}, :options => {:duration => 500}}, &close_procedure)
                    end
                end
                true
            end
            # Choice Dialog
            def open_dialog(the_application=nil, details=nil, &block)
                # details: {:type => :choose, :title => "Some Title", :banner => "Some Text Here"}
                self.layout_refresh()
                # Determine Dialog Details:
                window_title = (details || {:title => "Choose"})[:title].to_s
                banner_text = (details || {:banner => "(Please provide some text here)"})[:banner].to_s
                one_text = (details || {:one => ""})[:one].to_s
                two_text = (details || {:two => ""})[:two].to_s
                three_text = (details || {:three => ""})[:three].to_s
                default_text = (details || {:default => ""})[:default].to_s
                dialog_type = ((details || {:type => :choose})[:type] || :choose)
                # Define bounds: (in px)
                total_width = (self.layout_content_area()[:page_width].to_f * 0.25).to_i
                form_padding = 20
                form_margin = 5
                inner_width = (total_width - ((form_padding + form_margin) * 2))
                total_height = ((form_padding + form_margin) * 2)
                #
                banner_font_size = 16
                if banner_text.to_s.size > 40
                    banner_height = ((banner_text.size.to_f / 40.0) * banner_font_size.to_f).round.to_i
                else
                    banner_height = banner_font_size
                end
                input_font_size = 16
                # Define parts:
                #
                banner = {:component=>"text", :options=> {:content => banner_text, :style => {:"font-size" => "#{banner_font_size}px", :width => "100%"}}, :content => [], :script => ""}
                banner_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "100%",  :height => (banner_height), :"vertical-align" => "middle"}}, :content => [(banner)], :script => ""}
                #
                text_input = {:component=>"text_input", :options=>{:title => "data", :content => default_text, :style => {:"background-color" => "#f2f2f2", :"font-size" => "#{input_font_size}px", :width => "100%"}}, :content=>[], :script=>""}
                text_input_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "100%",  :"vertical-align" => "middle"}}, :content => [(text_input)], :script => ""}
                # Buttons:
                one_btn = {:component=>"button", :options=>{:content => one_text, :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                one_btn[:script] = "
                on(:mouseup) do |event|
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        the_window.respond({:action => :one})
                    end
                end
                "
                one_btn_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "40%",  :"vertical-align" => "middle"}}, :content => [(one_btn)], :script => ""}
                #
                two_btn = {:component=>"button", :options=>{:content => two_text, :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                two_btn[:script] = "
                on(:mouseup) do |event|
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        the_window.respond({:action => :two})
                    end
                end
                "
                two_btn_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "40%",  :"vertical-align" => "middle"}}, :content => [(two_btn)], :script => ""}
                #
                three_btn = {:component=>"button", :options=>{:content => three_text, :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                three_btn[:script] = "
                on(:mouseup) do |event|
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        the_window.respond({:action => :three})
                    end
                end
                "
                three_btn_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "40%",  :"vertical-align" => "middle"}}, :content => [(three_btn)], :script => ""}
                #
                cancel_btn = {:component=>"button", :options=>{:content => "Cancel", :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                cancel_btn[:script] = "
                on(:mouseup) do |event|
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        the_window.respond({:action => :cancel})
                    end
                end
                "
                cancel_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px",  :"vertical-align" => "middle"}}, :content => [(cancel_btn)], :script => ""}
                #
                # Define Containers:
                # Rows:
                row_one = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(banner_cell)], :script=>""}
                row_two = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(text_input_cell)], :script=>""}
                row_three = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[], :script=>""}
                # Tables:
                table_one = {:component=>"block_table", :options=>{:style => {:padding => "5px", :margin => "0px", :width => "100%"}}, :content=>[(row_one)], :script=>""}
                table_two = {:component=>"block_table", :options=>{:style => {:padding => "5px", :margin => "0px", :width => "100%"}}, :content=>[(row_two)], :script=>""}
                table_three = {:component=>"block_table", :options=>{:style => {:padding => "5px", :margin => "0px", :width => "100%"}}, :content=>[(row_three)], :script=>""}
                #
                # Form:
                form = {:component=>"form", :options=>{:style => {:"background-color" => "#f2f2f2", :padding => "#{form_padding}px", :margin => "#{form_margin}px"}}, :content=>[], :script=>""}
                #
                if banner_text.size > 0
                    form[:content] << table_one
                end
                # Build form:
                case dialog_type
                when :choose
                    # no :cancel; :one, :two, and :three buttons
                    if one_text.size > 0
                        row_three[:content] << one_btn_cell
                    end
                    if two_text.size > 0
                        row_three[:content] << two_btn_cell
                    end
                    if three_text.size > 0
                        row_three[:content] << three_btn_cell
                    end
                when :alert
                    # no cancel button
                    action_btn = {:component=>"button", :options=>{:content => "OK", :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                    action_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.respond({:action => :ok})
                        end
                    end
                    "
                    action_btn_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px"}}, :content => [(action_btn)], :script => ""}
                    #
                    row_three[:content] << action_btn_cell
                when :input
                    # text input, cancel and submit buttons
                    row_three[:content] << cancel_cell
                    action_btn = {:component=>"button", :options=>{:content => "OK", :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                    action_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        form = self.find_parent_type(:form)
                        if the_window && form
                            the_window.respond({:action => :ok, :form => form.form_data()})
                        end
                    end
                    "
                    action_btn_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px"}}, :content => [(action_btn)], :script => ""}
                    #
                    row_three[:content] << action_btn_cell
                    #
                    form[:content] << table_two
                end
                form[:content] << table_three
                # Build Dialog
                ### Calculate dialog width & height from content:
                #
                form[:options][:style][:width] = "#{total_width}px"
                ### Set banner height and other settings: ????
                if banner_text.to_s.size > 0
                    form[:content][0][:options][:style][:width] = "#{inner_width}px"
                    form[:content][0][:options][:style][:height] = "#{banner_height}px"
                    form[:content][0][:options][:style][:padding] = "10px 0px 10px 0px"
                    total_height += (banner_height + 20)
                end
                if dialog_type == :input
                    form[:content][1][:options][:style][:width] = "#{inner_width}px"
                    form[:content][1][:options][:style][:height] = "#{input_font_size}px"
                    form[:content][1][:options][:style][:padding] = "10px 0px 10px 0px"
                    total_height += (input_font_size + 20)
                    form[:content][2][:options][:style][:width] = "#{inner_width}px"
                    form[:content][2][:options][:style][:height] = "32px"
                    form[:content][2][:options][:style][:padding] = "10px 0px 10px 0px"
                    total_height += 52
                else
                    # just buttons
                    form[:content][1][:options][:style][:width] = "#{inner_width}px"
                    form[:content][1][:options][:style][:height] = "32px"
                    form[:content][1][:options][:style][:padding] = "10px 0px 10px 0px"
                    total_height += 52
                end
                # Review : cuts buttons off @ bottom on Firefox (shim-fix)
                total_height += 32
                #
                form[:options][:style][:height] = "#{(total_height - ((form_padding + form_margin) * 2))}px"
                ### Calculate button horizontal spacing: inner_width
                case row_three[:content].size
                when 1
                    row_three[:content][0][:options][:style][:padding] = "5px 0px 5px #{((inner_width / 2) - 25)}px"
                when 2
                    row_three[:content][0][:options][:style][:padding] = "5px 0px 5px #{((inner_width / 4) - 12)}px"
                    row_three[:content][1][:options][:style][:padding] = "5px 0px 5px #{((inner_width / 4) - 12)}px"
                when 3
                    row_three[:content][0][:options][:style][:padding] = "5px 0px 5px #{((inner_width / 6) - 6)}px"
                    row_three[:content][1][:options][:style][:padding] = "5px 0px 5px #{((inner_width / 6) - 6)}px"
                    row_three[:content][2][:options][:style][:padding] = "5px 0px 5px #{((inner_width / 6) - 6)}px"
                end
                #
                dialog_source = {:component => "dialog_box", :options => {:window_title => window_title, :states => {:hidden => true}, :width => total_width, :height => total_height}, :script => "", :content => [(form)]}
                dialog_source[:script] = "
                on(:keyup) do |event|
                    if event[:which] == 27
                        self.respond({:action => :cancel})
                    end
                end
                "
                #
                begin
                    # log_info("Opening dialog ...")
                    self.dialog_open(dialog_source, the_application, details, &block)
                    true
                rescue Exception => the_error
                    log_error({:error => the_error, :parameters => {}})
                    false
                end
            end
            # Mini Path Finder:
            def vfs_dialog(the_application=nil, details=nil, &block)
                # details: {:type => :folder, :path => "/path/to/somewhere"}
                # Determine Dialog Type:
                window_title = "Unsupported Dialog Type"
                action_title = "Unsupported"
                dialog_type = (details || {:type => :folder})[:type]
                case dialog_type
                when :save, "save"
                    window_title = "Save As ..."
                    action_title = "Save"
                when :folder, "folder"
                    window_title = "Choose Folder"
                    action_title = "Choose"
                when :object, "object"
                    window_title = "Select Object"
                    action_title = "Select"
                end
                # Path Menu: ????
                # `#{@element}.textContent = 'The_String'` || set_text("The_String")
                menu_bar = {:component => "menu_bar", :options => {:title => "path_menu_bar"}, :content => [], :script => ""}
                menu_bar[:script] = "
                def update_appearance()
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        this_layer = the_window.layer()
                        unless @current_path
                            @current_path = (the_window.data()[:path] || '/')
                        end
                        build_list = []
                        if @current_path == '/'
                            current = ['']
                        else
                            current = @current_path.split('/')
                        end
                        #
                        path_menu = {:component => 'menu_entry', :options => {:title => 'path_menu', :content => File.basename(@current_path), :layer => (this_layer + 100), :menu => self}, :content => [], :script => ''}
                        #
                        neg_index = (current.size * -1)
                        ((neg_index)..-1).to_a.reverse.each_with_index do |the_offset, indexer|
                            subpath = current[(0..(the_offset))].join('/')
                            if subpath == '' || subpath == '/'
                                path_title = '/'
                            else
                                path_title = File.basename(subpath)
                            end
                            path_menu[:content] << {:component => 'menu_item', :options => {:content => path_title, :data => {:path => subpath}}, :content => [], :script => ''}
                        end
                        build_list << path_menu
                        self.children.values.each do |the_child|
                            the_child.destroy
                        end
                        self.build_interior_components(build_list)
                    end
                end
                def path()
                    @current_path
                end
                def path=(the_path=nil)
                    @current_path = (the_path || '/')
                    # self.set_text(File.basename(@current_path))
                    self.update_appearance
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        list = the_window.find_child('subitems')
                        if list
                            list.update_appearance()
                        end
                    end
                end
                #
                def select_item(the_menu_item=nil)
                    if the_menu_item
                        self.path = the_menu_item.data()[:path]
                    end
                end
                "
                menu_bar_cell = {:component => "block_table_cell", :options => {:style => {:border => "1px solid #c2c2c2", :padding => "0px", :margin => "0px", :width => "100%"}}, :content => [(menu_bar)], :script => ""}
                # SubItem List:
                subitems = {:component=>"list", :options=>{:title => "subitems", :style => {:clear => "both", :"list-style" => "none", :padding => "0px", :margin => "0px"}}, :content=>[], :script=>""}
                # Various SubItems scripts (per dialog_type)
                subitems[:script] = "
                def manifest()
                    @manifest
                end
                #
                def update_appearance()
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        dialog_type = (the_window.data()[:type] || :folder)
                        menu_bar = the_window.find_child('path_menu_bar')
                        if menu_bar
                            current_path = (menu_bar.path() || '/')
                        else
                            current_path = '/'
                        end
                        @selection = nil
                        @manifest = {}
                        self.children.values.each do |the_child|
                            the_child.destroy
                        end
                        GxG::CONNECTION.entries({:location => (current_path)}) do |response|
                            if response.is_a?(::Hash)
                                response[:result].each do |the_profile|
                                    item_uuid = ::GxG::uuid_generate()
                                    item_path = (current_path + '/' + the_profile[:title].to_s)
                                    if dialog_type == :folder
                                        if [:virtual_directory, :directory, :persisted_array].include?(the_profile[:type].to_s.to_sym)
                                            @manifest[(item_uuid.to_s.to_sym)] = {:path => item_path, :profile => the_profile}
                                            self.add_list_item({:icon => self.theme_icon('folder.svg'), :label => the_profile[:title].to_s, :uuid => item_uuid.to_s})
                                        end
                                    else
                                        @manifest[(item_uuid.to_s.to_sym)] = {:path => item_path, :profile => the_profile}
                                        case (the_profile[:type].to_s.to_sym)
                                        when :virtual_directory, :directory, :persisted_array
                                            the_icon_path = self.theme_icon('folder.svg')
                                        when :persisted_hash
                                            the_icon_path = self.theme_icon('object.svg')
                                        else
                                            # Review: further qualify file type icons ??
                                            the_icon_path = self.theme_icon('file.svg')
                                        end
                                        self.add_list_item({:icon => the_icon_path, :label => the_profile[:title].to_s, :uuid => item_uuid.to_s})
                                    end
                                end
                            end
                        end
                        #
                    end
                end
                "
                case dialog_type
                when :save
                    subitems[:script] = (subitems[:script] + "\n" + "
                    self.set_select_responder do |the_uuid|
                        if @manifest[(the_uuid.to_s.to_sym)]
                            # nothing
                        end
                    end
                    self.set_open_responder do |the_uuid|
                        if @manifest[(the_uuid.to_s.to_sym)]
                            if [:virtual_directory, :directory, :persisted_array].include?(@manifest[(the_uuid.to_s.to_sym)][:profile][:type].to_s.to_sym)
                                # open folder
                                the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                                if the_window
                                    menu_bar = the_window.find_child('path_menu_bar')
                                    if menu_bar
                                        GxG::DISPATCHER.post_event(:root) do
                                            menu_bar.path = @manifest[(the_uuid.to_s.to_sym)][:path]
                                        end
                                    end
                                end
                            end
                        end
                    end
                    ")
                when :folder
                    subitems[:script] = (subitems[:script] + "\n" + "
                    self.set_select_responder do |the_uuid|
                        if @manifest[(the_uuid.to_s.to_sym)]
                            # nothing
                        end
                    end
                    self.set_open_responder do |the_uuid|
                        if @manifest[(the_uuid.to_s.to_sym)]
                            if [:virtual_directory, :directory, :persisted_array].include?(@manifest[(the_uuid.to_s.to_sym)][:profile][:type].to_s.to_sym)
                                # open folder
                                the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                                if the_window
                                    menu_bar = the_window.find_child('path_menu_bar')
                                    if menu_bar
                                        GxG::DISPATCHER.post_event(:root) do
                                            menu_bar.path = @manifest[(the_uuid.to_s.to_sym)][:path]
                                        end
                                    end
                                end
                            end
                        end
                    end
                    ")
                when :object
                    subitems[:script] = (subitems[:script] + "\n" + "
                    self.set_select_responder do |the_uuid|
                        if @manifest[(the_uuid.to_s.to_sym)]
                            # if object selected enable Select button else disable it.
                            the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                            if the_window
                                action_button = the_window.find_child('action_button')
                                if action_button
                                    if [:file, :persisted_hash].include?(@manifest[(the_uuid.to_s.to_sym)][:profile][:type].to_s.to_sym)
                                        action_button.enable()
                                    else
                                        action_button.disable()
                                    end
                                end
                            end
                        end
                    end
                    self.set_open_responder do |the_uuid|
                        if @manifest[(the_uuid.to_s.to_sym)]
                            if [:virtual_directory, :directory, :persisted_array].include?(@manifest[(the_uuid.to_s.to_sym)][:profile][:type].to_s.to_sym)
                                # open folder
                                # first, disable Select button
                                the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                                if the_window
                                    menu_bar = the_window.find_child('path_menu_bar')
                                    if menu_bar
                                        GxG::DISPATCHER.post_event(:root) do
                                            menu_bar.path = @manifest[(the_uuid.to_s.to_sym)][:profile][:path]
                                        end
                                    end
                                end
                            end
                        end
                    end
                    ")
                end
                #
                subitems_container = {:component=>"block", :options => {:style => {:width => "100%", :height => "192px", :"overflow-y" => "scroll"}}, :content => [(subitems)], :script => ""}
                subitems_cell = {:component => "block_table_cell", :options => {:style => {:border => "1px solid #c2c2c2", :padding => "0px", :margin => "0px", :width => "100%"}}, :content => [(subitems_container)], :script => ""}
                # Save As ... Field
                save_name = {:component=>"text_input", :options=>{:title => "save_name", :style => {:"background-color" => "#f2f2f2", :"font-size" => "16px", :width => "100%"}}, :content=>[], :script=>""}
                save_name_cell = {:component => "block_table_cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content => [(save_name)], :script => ""}
                # Buttons:
                action_btn = {:component=>"submit_button", :options=>{:title => "action_button", :content => action_title, :style => {:padding => "0px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                action_btn[:script] = "
                on(:mouseup) do |event|
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    form = self.find_parent_type(:form)
                    if the_window && form
                        menu_bar = the_window.find_child('path_menu_bar')
                        list = the_window.find_child('subitems')
                        if menu_bar && list
                            if list.selection()
                                result_path = list.manifest()[(list.selection().to_s.to_sym)][:path]
                            else
                                result_path = menu_bar.path()
                            end
                            if the_window.data()[:type].to_s.to_sym == :save
                                result_path = (result_path + '/' + (form.form_data()[:save_name] || 'Untitled.data').to_s)
                            end
                            the_window.respond({:action => the_window.data()[:type].to_s.to_sym, :path => result_path})
                        end
                    end
                end
                ".encode64
                action_cell = {:component => "block_table_cell", :options => {:style => {:padding => "10px 0px 0px 35px", :margin => "0px", :width => "50%"}}, :content => [(action_btn)], :script => ""}
                cancel_btn = {:component=>"button", :options=>{:content => "Cancel", :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                cancel_btn[:script] = "
                on(:mouseup) do |event|
                    the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                    if the_window
                        the_window.respond({:action => :cancel})
                    end
                end
                ".encode64
                cancel_cell = {:component => "block_table_cell", :options => {:style => {:padding => "10px 0px 0px 35px", :margin => "0px", :width => "50%"}}, :content => [(cancel_btn)], :script => ""}
                # Rows:
                row_one = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(menu_bar_cell)], :script=>""}
                row_two = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(subitems_cell)], :script=>""}
                row_three = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(save_name_cell)], :script=>""}
                row_four = {:component=>"block_table_row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(cancel_cell),(action_cell)], :script=>""}
                # Tables:
                table_one = {:component=>"block_table", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "32px"}}, :content=>[(row_one)], :script=>""}
                table_two = {:component=>"block_table", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "192px"}}, :content=>[(row_two)], :script=>""}
                table_three = {:component=>"block_table", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "32px"}}, :content=>[(row_three)], :script=>""}
                table_four = {:component=>"block_table", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "32px"}}, :content=>[(row_four)], :script=>""}
                #
                # Main Build:
                form = {:component=>"form", :options=>{:style => {:"background-color" => "#f2f2f2", :padding => "20px", :margin => "5px", :width => "100%"}}, :content=>[], :script=>""}
                #
                total_height = 330
                form[:content] << table_one
                form[:content] << table_two
                if dialog_type == :save || dialog_type == "save"
                    form[:content] << table_three
                    total_height += 32
                end
                form[:content] << table_four
                viewport = {:component=>"application_viewport", :options=>{:title => "selection_viewport", :style => {:overflow => "hidden", :width => "100%", :height => "100%"}}, :content=>[(form)], :script=>""}
                dialog_source = {:component => "dialog_box", :options => {:window_title => window_title, :states => {:hidden => true}, :width => 350, :height => total_height}, :script => "", :content => [(viewport)]}
                dialog_source[:script] = "
                def after_open()
                    menu_bar = self.find_child('path_menu_bar')
                    if menu_bar
                        menu_bar.path = (self.data()[:path])
                    end
                end
                "
                #
                begin
                    # log_info("Opening dialog ...")
                    self.dialog_open(dialog_source, the_application, details, &block)
                    true
                rescue Exception => the_error
                    log_error({:error => the_error, :parameters => {}})
                    false
                end
            end
            # internal windowing tools:
            def get_window_registration(the_reference=nil)
                if the_reference.is_any?(::String, ::Symbol)
                    # {:window => nil, :layer => 0, :restore => nil}
                    @window_registry[(the_reference)]
                else
                    nil
                end
            end
            #
            def set_window_switcher(the_switcher=nil)
                if the_switcher
                    @window_switcher = the_switcher
                end
            end
            def get_window_switcher()
                @window_switcher
            end
            # z-index management, restore/min/max etc.
            # @window_registry = (@window_registry.sort_by {|uuid,entry| entry[:layer]}).to_h
            # interfacing with others:
            def get_window(the_reference=nil)
                if the_reference.is_any?(::String, ::Symbol)
                    registration = self.get_window_registration(the_reference)
                    if registration
                        registration[:window]
                    else
                        nil
                    end
                else
                    nil
                end
            end
            #
            def window_list()
                result = []
                @window_registry.keys.each do |reference|
                    result << {:uuid => reference, :title => @window_registry[(reference)][:window].title()}
                end
                result
            end
            #
            def window_repack_layers()
                @window_registry = (@window_registry.sort_by {|uuid,entry| entry[:layer]}).to_h
                @window_registry.values.each_with_index do |entry, indexer|
                    entry[:window].gxg_merge_style(:"z-index",(200 + indexer))
                    entry[:layer] = indexer
                end
                true
            end
            #
            def window_top_layer()
                ((@window_registry.collect {|uuid,entry| entry[:layer]}).max || 0)
            end
            #
            def window_back_layer()
                back_layer = (((@window_registry.collect {|uuid,entry| entry[:layer]}).min || 0) - 1)
                if back_layer < 100
                    window_repack_layers
                    back_layer = (((@window_registry.collect {|uuid,entry| entry[:layer]}).min || 0) - 1)
                end
                back_layer
            end
            #
            def window_next_layer()
                next_layer = (((@window_registry.collect {|uuid,entry| entry[:layer]}).max || 0) + 1)
                if next_layer > 99
                    window_repack_layers
                    next_layer = (((@window_registry.collect {|uuid,entry| entry[:layer]}).max || 0) + 1)
                end
                next_layer
            end
            #
            def window_register(the_reference=nil, the_instance=nil)
                if the_reference.is_any?(::String, ::Symbol)
                    if the_instance
                        # {:window => nil, :layer => 0, :restore => nil}
                        front_layer = self.window_next_layer()
                        the_instance.gxg_merge_style(:"z-index",(200 + front_layer))
                        @window_registry[(the_reference)] = {:window => the_instance, :layer => front_layer, :restore => nil}
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_unregister(the_reference=nil)
                if the_reference.is_any?(::String, ::Symbol)
                    @window_registry.delete(the_reference)
                    true
                else
                    false
                end
            end
            #
            def window_open(build_source=nil, the_application=nil)
                if build_source.is_any?(::Hash, GxG::Database::PersistedHash)
                    if build_source.is_a?(GxG::Database::PersistedHash)
                        the_uuid = build_source.uuid
                        the_options = build_source[:options].unpersist
                        if the_options[:title]
                            the_title = the_options.delete(:title)
                        else
                            the_title = build_source.title
                        end
                        the_options[:uuid] = the_uuid
                    else
                        the_uuid = GxG::uuid_generate.to_sym
                        the_options = build_source[:options].clone
                        the_title = the_options.delete(:title)
                        the_options[:uuid] = the_uuid
                    end
                    the_style = the_options.delete(:style)
                    the_states = (the_options.delete(:states) || {})
                    new_window = GxG::DISPLAY_DETAILS[:object].add_child(the_uuid, GxG::Gui::Window, the_options)
                    if new_window
                        new_window.set_title(the_title)
                        # Set states:
                        unless the_states.keys.include?(:hidden)
                            the_states[:hidden] = false
                        end
                        new_window.gxg_set_states(the_states)
                        # process style info:
                        if the_style.is_a?(::Hash)
                            new_window.gxg_set_style(the_style)
                        end
                        if the_application.is_a?(::GxG::Application)
                            new_window.set_application(the_application)
                            unless the_application.get_window(the_uuid)
                                the_application.link_window(new_window)
                            end
                            if new_window.menu_reference()
                                the_menu_source = the_application.search_content(new_window.menu_reference())
                                if the_menu_source.is_any?(::Hash, ::GxG::Database::PersistedHash)
                                    new_window.set_menu(the_menu_source)
                                else
                                    log_warn("Invalid Menu Resource referenced: #{new_window.menu_reference().inspect}")
                                end
                            end
                        end
                        # Set Script if any is provided
                        if build_source[:script].size > 0
                            new_window.set_script(build_source[:script].to_s)
                        end
                        #
                        self.register_object(the_title, new_window)
                        self.window_register(the_uuid,new_window)
                        self.build_components([{:parent => GxG::DISPLAY_DETAILS[:object], :record => build_source, :element => new_window}],the_application)
                        new_window.before_open
                        new_window.open
                        unless the_states[:hidden] == true
                            new_window.show
                        end
                        new_window.after_open
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_close(the_reference=nil, options={})
                if the_reference.is_any?(::String, ::Symbol)
                    registration = self.get_window_registration(the_reference)
                    if registration
                        registration[:window].before_close
                        registration[:window].close
                        registration[:window].hide
                        registration[:window].after_close
                        self.window_unregister(the_reference)
                        self.unregister_object(the_reference)
                        registration[:window].destroy
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_is_in_back?(the_reference=nil)
                the_record = self.get_window_registration(the_reference)
                if the_record
                    bottom_layer = ((@window_registry.collect {|uuid,entry| entry[:layer]}).min || 0)
                    if the_record[:layer] == bottom_layer
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_is_in_front?(the_reference=nil)
                the_record = self.get_window_registration(the_reference)
                if the_record
                    top_layer = ((@window_registry.collect {|uuid,entry| entry[:layer]}).max || 0)
                    if the_record[:layer] == top_layer
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_send_to_back(the_reference=nil)
                the_record = self.get_window_registration(the_reference)
                if the_record
                    unless self.window_is_in_back?(the_reference)
                        back_layer = self.window_back_layer()
                        the_record[:window].gxg_merge_style(:"z-index",(200 + back_layer))
                        the_record[:layer] = back_layer
                    end
                else
                    false
                end
            end
            #
            def window_bring_to_front(the_reference=nil, options={})
                the_record = self.get_window_registration(the_reference)
                if the_record
                    unless the_record[:layer] == self.window_top_layer()
                        front_layer = self.window_next_layer()
                        the_record[:window].gxg_merge_style(:"z-index",(200 + front_layer))
                        the_record[:layer] = front_layer
                    end
                    true
                else
                    false
                end
            end
            # Transition Effect Methods (override for custom effects)
            def next_minimize_slot()
                # slots are allocated from the top / left of the content area:
                cell_width = 200
                cell_height = 24
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                columns = (0..(bounds[:right] - bounds[:left]).step(cell_width).size)
                rows = (0..(bounds[:bottom] - bounds[:top]).step(cell_height).size)
                found = nil
                (0..(rows - 1)).each do |the_row|
                    (0..(columns - 1)).each do |the_column|
                        is_in = false
                        test_rect = {:top => (bounds[:top] + (the_row * cell_height)), :left => (bounds[:left] + (the_column * cell_width)), :right => (bounds[:left] + (the_column * cell_width) + cell_width), :bottom => (bounds[:top] + (the_row * cell_height) + cell_height)}
                        @window_registry.values.each do |the_record|
                            #
                            this_rect = {:top => 0, :left => 0, :right => 0, :bottom => 0}
                            this_rect[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                            this_rect[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                            this_rect[:right] = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                            this_rect[:bottom] = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                            if (this_rect[:top] == test_rect[:top] && this_rect[:left] == test_rect[:left] && this_rect[:right] == test_rect[:right] && this_rect[:bottom] == test_rect[:bottom])
                                is_in = true
                                break
                            end
                            #
                        end
                        unless is_in
                            found = test_rect
                            break
                        end
                    end
                    if found
                        break
                    end
                end
                found
            end
            #
            def minimize_effect(the_record=nil,&block)
                switcher = self.get_window_switcher()
                if switcher
                    origin = {:opacity => 1}
                    origin[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    origin[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    origin_right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    origin_bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    origin[:width] = (origin_right - origin[:left])
                    origin[:height] = (origin_bottom - origin[:top])
                    destination = {:opacity => 0}
                    destination[:top] = `#{switcher.element}.getBoundingClientRect().top`.to_i
                    destination[:left] = `#{switcher.element}.getBoundingClientRect().right`.to_i
                    destination_right = `#{switcher.element}.getBoundingClientRect().right`.to_i
                    destination_bottom = `#{switcher.element}.getBoundingClientRect().top`.to_i
                    destination[:width] = (destination_right - destination[:left])
                    destination[:height] = (destination_bottom - destination[:top])
                    conclude = Proc.new {
                        if block.respond_to?(:call)
                            block.call(true)
                        end
                    }
                else
                    # find a tile spot to land on:
                    the_slot = self.next_minimize_slot()
                    origin = {:opacity => 1}
                    origin[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    origin[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    origin_right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    origin_bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    origin[:width] = (origin_right - origin[:left])
                    origin[:height] = (origin_bottom - origin[:top])
                    destination = {:opacity => 0.5}
                    destination[:top] = the_slot[:top]
                    destination[:left] = the_slot[:left]
                    destination_right = the_slot[:right]
                    destination_bottom = the_slot[:bottom]
                    destination[:width] = (destination_right - destination[:left])
                    destination[:height] = (destination_bottom - destination[:top])
                    conclude = Proc.new {
                        self.window_send_to_back(the_record[:window].uuid)
                        if block.respond_to?(:call)
                            block.call(true)
                        end
                    }
                end
                animate_content = Proc.new {
                    top = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    left = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    the_record[:window].set_frame({:top => top, :left => left, :right => right, :bottom => bottom})
                }
                the_record[:window].animate({:origin => origin, :destination => destination, :options => {:duration => 500, :animationiteration => animate_content, :animationend => conclude}})
                #
                settings = {:action => :minimize, :top => 0, :left => 0, :right => 0, :bottom => 0}
                settings[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                settings[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                settings[:right] = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                settings[:bottom] = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                settings
            end
            #
            def unminimize_effect(the_record=nil,&block)
                switcher = self.get_window_switcher()
                if switcher
                    origin = {:opacity => 0}
                    origin[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    origin[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    origin_right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    origin_bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    origin[:width] = (origin_right - origin[:left])
                    origin[:height] = (origin_bottom - origin[:top])
                    destination = {:opacity => 1}
                    destination[:top] = the_record[:restore][:settings][:top]
                    destination[:left] = the_record[:restore][:settings][:left]
                    destination_right = the_record[:restore][:settings][:right]
                    destination_bottom = the_record[:restore][:settings][:bottom]
                    destination[:width] = (destination_right - destination[:left])
                    destination[:height] = (destination_bottom - destination[:top])
                else
                    #
                    origin = {:opacity => 0.5}
                    origin[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    origin[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    origin_right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    origin_bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    origin[:width] = (origin_right - origin[:left])
                    origin[:height] = (origin_bottom - origin[:top])
                    destination = {:opacity => 1}
                    destination[:top] = the_record[:restore][:settings][:top]
                    destination[:left] = the_record[:restore][:settings][:left]
                    destination_right = the_record[:restore][:settings][:right]
                    destination_bottom = the_record[:restore][:settings][:bottom]
                    destination[:width] = (destination_right - destination[:left])
                    destination[:height] = (destination_bottom - destination[:top])
                end
                animate_content = Proc.new {
                    top = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    left = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    the_record[:window].set_frame({:top => top, :left => left, :right => right, :bottom => bottom})
                }
                conclude = Proc.new {
                    if block.respond_to?(:call)
                        block.call(true)
                    end
                }
                the_record[:window].animate({:origin => origin, :destination => destination, :options => {:duration => 500, :animationiteration => animate_content, :animationend => conclude}})
                #
                true
            end
            #
            def maximize_effect(the_record=nil,&block)
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                origin = {}
                origin[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                origin[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                origin_right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                origin_bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                origin[:width] = (origin_right - origin[:left])
                origin[:height] = (origin_bottom - origin[:top])
                destination = {}
                destination[:top] = bounds[:top]
                destination[:left] = bounds[:left]
                destination[:width] = (bounds[:right] - destination[:left])
                destination[:height] = (bounds[:bottom] - destination[:top])
                # run animation (which alters the state)
                # animationiteration set_frame
                animate_content = Proc.new {
                    top = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    left = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    the_record[:window].set_frame({:top => top, :left => left, :right => right, :bottom => bottom})
                }
                conclude = Proc.new {
                    if block.respond_to?(:call)
                        block.call(true)
                    end
                }
                the_record[:window].animate({:origin => origin, :destination => destination, :options => {:duration => 500, :animationiteration => animate_content, :animationend => conclude}})
                #
                settings = {:action => :maximize, :top => 0, :left => 0, :right => 0, :bottom => 0}
                settings[:top] = bounds[:top]
                settings[:left] = bounds[:left]
                settings[:right] = bounds[:right]
                settings[:bottom] = bounds[:bottom]
                settings
            end
            #
            def unmaximize_effect(the_record=nil,&block)
                origin = {}
                origin[:top] = the_record[:window].top()
                origin[:left] = the_record[:window].left()
                origin_right = the_record[:window].right()
                origin_bottom = the_record[:window].bottom()
                origin[:width] = (origin_right - origin[:left])
                origin[:height] = (origin_bottom - origin[:top])
                destination = {}
                destination[:top] = the_record[:restore][:settings][:top]
                destination[:left] = the_record[:restore][:settings][:left]
                destination_right = the_record[:restore][:settings][:right]
                destination_bottom = the_record[:restore][:settings][:bottom]
                destination[:width] = (destination_right - destination[:left])
                destination[:height] = (destination_bottom - destination[:top])
                # run animation (which alters the state)
                animate_content = Proc.new {
                    top = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                    left = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                    right = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                    bottom = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                    the_record[:window].set_frame({:top => top, :left => left, :right => right, :bottom => bottom})
                }
                conclude = Proc.new {
                    if block.respond_to?(:call)
                        block.call(true)
                    end
                }
                the_record[:window].animate({:origin => origin, :destination => destination, :options => {:duration => 500, :animationiteration => animate_content, :animationend => conclude}})
                true
            end
            #
            def rollup_effect(the_record=nil,&block)
                origin = {}
                the_top = the_record[:window].top()
                origin[:height] = the_record[:window].height()
                destination = {}
                destination[:height] = 24
                # run animation (which alters the state)
                window_body = the_record[:window].find_child("window_body",true)
                if window_body
                    window_body.hide({:origin => {:opacity => 1.0}, :destination => {:opacity => 0.0}}) do
                        the_record[:window].animate({:origin => origin, :destination => destination})
                        if block.respond_to?(:call)
                            block.call(true)
                        end
                    end
                end
                #
                settings = {:action => :rollup, :top => 0, :left => 0, :right => 0, :bottom => 0}
                settings[:top] = `#{the_record[:window].element}.getBoundingClientRect().top`.to_i
                settings[:left] = `#{the_record[:window].element}.getBoundingClientRect().left`.to_i
                settings[:right] = `#{the_record[:window].element}.getBoundingClientRect().right`.to_i
                settings[:bottom] = `#{the_record[:window].element}.getBoundingClientRect().bottom`.to_i
                settings
            end
            #
            def rolldown_effect(the_record=nil,&block)
                origin = {}
                origin[:height] = 24
                destination = {}
                destination[:height] = (the_record[:restore][:settings][:bottom] - the_record[:restore][:settings][:top])
                # run animation (which alters the state)
                conclude = Proc.new {
                    window_body = the_record[:window].find_child("window_body",true)
                    if window_body
                        window_body.show({:origin => {:opacity => 0.0}, :destination => {:opacity => 1.0}}) do
                            the_record[:window].commit_settings
                            if block.respond_to?(:call)
                                block.call(true)
                            end
                        end
                    end
                }
                the_record[:window].animate({:origin => origin, :destination => destination, :options => {:duration => 500, :animationend => conclude}})
                true
            end
            # set/restore window state:
            def window_restoreable?(the_reference=nil)
                the_record = self.get_window_registration(the_reference)
                if the_record
                    if the_record[:restore].is_a?(::Hash)
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_restore(the_reference=nil, options={},&block)
                the_record = self.get_window_registration(the_reference)
                if the_record
                    if the_record[:restore].is_a?(::Hash)
                        # restore from last :action
                        case the_record[:restore][:action]
                        when :minimize
                            self.unminimize_effect(the_record) do
                                the_record[:window].clear_special_state(the_record[:restore][:settings])
                                # clear the restore record
                                the_record[:restore] = nil
                                if block.respond_to?(:call)
                                    block.call(true)
                                end
                            end
                        when :maximize
                            self.unmaximize_effect(the_record) do
                                the_record[:window].clear_special_state(the_record[:restore][:settings])
                                # clear the restore record
                                the_record[:restore] = nil
                                if block.respond_to?(:call)
                                    block.call(true)
                                end
                            end
                        when :rollup
                            self.rolldown_effect(the_record) do
                                the_record[:window].clear_special_state(the_record[:restore][:settings])
                                # clear the restore record
                                the_record[:restore] = nil
                                if block.respond_to?(:call)
                                    block.call(true)
                                end
                            end
                        end
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
            #
            def window_minimize(the_reference=nil, settings={})
                the_record = self.get_window_registration(the_reference)
                if the_record
                    if self.window_restoreable?(the_reference)
                        self.window_restore(the_reference) do
                            settings = {:top => the_record[:window].top, :left => the_record[:window].left, :right => the_record[:window].right, :bottom => the_record[:window].bottom}
                            the_record[:restore] = {:action => :minimize, :settings => settings}
                            the_record[:window].set_special_state(self.minimize_effect(the_record))
                        end
                    else
                        the_record[:restore] = {:action => :minimize, :settings => settings}
                        the_record[:window].set_special_state(self.minimize_effect(the_record))
                    end
                    true
                else
                    false
                end
            end
            #
            def window_maximize(the_reference=nil, settings={})
                the_record = self.get_window_registration(the_reference)
                if the_record
                    if self.window_restoreable?(the_reference)
                        self.window_restore(the_reference) do
                            settings = {:top => the_record[:window].top, :left => the_record[:window].left, :right => the_record[:window].right, :bottom => the_record[:window].bottom}
                            the_record[:restore] = {:action => :maximize, :settings => settings}
                            the_record[:window].set_special_state(self.maximize_effect(the_record))
                            self.window_bring_to_front(the_reference)
                        end
                    else
                        the_record[:restore] = {:action => :maximize, :settings => settings}
                        the_record[:window].set_special_state(self.maximize_effect(the_record))
                        self.window_bring_to_front(the_reference)
                    end
                    true
                else
                    false
                end
            end
            #
            def window_rollup(the_reference=nil, settings={})
                the_record = self.get_window_registration(the_reference)
                if the_record
                    if self.window_restoreable?(the_reference)
                        self.window_restore(the_reference) do
                            settings = {:top => the_record[:window].top, :left => the_record[:window].left, :right => the_record[:window].right, :bottom => the_record[:window].bottom}
                            the_record[:restore] = {:action => :rollup, :settings => settings}
                            the_record[:window].set_special_state(self.rollup_effect(the_record))
                        end
                    else
                        the_record[:restore] = {:action => :rollup, :settings => settings}
                        the_record[:window].set_special_state(self.rollup_effect(the_record))
                    end
                    true
                else
                    false
                end
            end
            #
            # Loading and Building:
            def get_library(the_reference=nil)
                result = nil
            	if the_reference.is_any?(::Hash, ::GxG::Database::PersistedHash)
            		GxG::APPLICATIONS[:libraries].values.each do |the_library|
            			if the_library.title == the_reference[:library].to_s && the_library.type == (the_reference[:type] || the_library.type)
            				if the_reference[:maximum]
            					if ((the_reference[:minimum].to_f)..(the_reference[:maximum].to_f)).include?(the_library.version)
            						result = the_library
            						break
            					end
            				else
            					if the_library.version >= the_reference[:minimum].to_f
            						result = the_library
            						break
            					end
            				end
            			end
            		end
            		found
            	else
            		if GxG::APPLICATIONS[:libraries][(the_reference.to_s.to_sym)]
            			result = GxG::APPLICATIONS[:libraries][(the_reference.to_s.to_sym)]
            		else
            			GxG::APPLICATIONS[:libraries].values.each do |the_library|
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
            def library_loaded?(the_reference=nil)
            	if the_reference.is_any?(::Hash, ::GxG::Database::PersistedHash)
            		found = false
            		GxG::APPLICATIONS[:libraries].values.each do |the_library|
            			if the_library.title == the_reference[:library].to_s && the_library.type == (the_reference[:type] || the_library.type).to_s
            				if the_reference[:maximum]
            					if ((the_reference[:minimum].to_f)..(the_reference[:maximum].to_f)).include?(the_library.version)
            						found = the_library.loaded?()
            						break
            					end
            				else
            					if the_library.version >= the_reference[:minimum].to_f
            						found = the_library.loaded?()
            						break
            					end
            				end
            			end
            		end
            		found
            	else
            		if GxG::APPLICATIONS[:libraries][(the_reference.to_s.to_sym)]
            			true
            		else
            			found = false
            			GxG::APPLICATIONS[:libraries].values.each do |the_library|
            				if the_library.title == the_reference
            					found = the_library.loaded?()
            					break
            				end
            			end
            			found
            		end
            	end
            end
            #
            def load_library(criteria=nil, &block)
            	if criteria.is_any?(::Hash, ::GxG::Database::PersistedHash)
            		# {:library => "lib-name", :manifest => true/false, :dependencies => true/false, :minimum => 0.0, :maximum => 0.0, :loaded => [<UUID>...]}
            		if criteria[:maximum]
            			maximum = criteria[:maximum].to_f
            		else
            			maximum = nil
            		end
            		GxG::CONNECTION.library_pull({:library => criteria[:library].to_s, :type => criteria[:type].to_s, :minimum => (criteria[:minimum] || 0.0).to_f, :maximum => maximum,:dependencies => true, :loaded => GxG::APPLICATIONS[:libraries].keys}) do |response|
            			# process response[:result]
            			if response.is_a?(::Hash)
            				if response[:result].is_a?(::Array)
            					response[:result].each do |the_record|
            						unless GxG::APPLICATIONS[:libraries].keys.include?(the_record[:uuid].to_s.to_sym)
            							definition = the_record[:data]
            							if definition.is_a?(::String)
            								if definition.base64?
            									definition = definition.decode64
            								end
            								if definition.json?
            									definition = ::JSON::parse(definition,{:symbolize_names => true})
            								end
            								if definition.is_a?(::Hash)
            									definition = ::GxG::Database::process_import(definition)
            								end
            								if definition.is_a?(::GxG::Database::PersistedHash)
            									GxG::APPLICATIONS[:libraries][(the_record[:uuid].to_s.to_sym)] = ::GxG::Library.new(definition)
            									if block.respond_to?(:call)
            										block.call(GxG::APPLICATIONS[:libraries][(the_record[:uuid].to_s.to_sym)])
            									end
            								end
            							end
            						end
            					end
            				end
            			end
            		end
            		#
            	end
            end
            #
            def load_libraries(load_queue=[], &block)
            	result = true
            	if load_queue.is_any?(::Array, ::GxG::Database::PersistedArray)
            		load_queue.each do |the_requirement|
            			GxG::DISPLAY_DETAILS[:object].load_library(the_requirement) do |the_library|
            				unless the_library.loaded?
            					log_warn("Unable to load library: #{the_library.title}")
            					result = false
            					break
            				end
            			end
            		end
            		#
            	end
            	if block.respond_to?(:call)
            		block.call(result)
            	end
            	result
            end
            # Application Supports:
            def application_open(specifier={}, parameters={})
                result = false
                if specifier.is_a?(::Hash)
                    error_hander = Proc.new {
                        self.set_busy(false)
                    }
                    self.set_busy(true)
                    GxG::CONNECTION.application_open(specifier,error_hander) do |app_stub|
                        if app_stub.is_a?(::Hash)
                            if app_stub[:result].is_a?(::Hash)
                                GxG::CONNECTION.pull_object(app_stub[:result][:location]) do |source_object|
                                    GxG::APPLICATIONS[:processes][(app_stub[:result][:application].to_s.to_sym)] = GxG::Application.new(app_stub[:result].merge({:source => source_object}))
                                    #
                                    result = GxG::APPLICATIONS[:processes][(app_stub[:result][:application].to_s.to_sym)].run(parameters)
                                    #
                                    self.set_busy(false)
                                end
                            else
                                log_warn('Error opening Application: ' + app_stub.inspect)
                            end
                        else
                            log_warn("Malformed response: #{app_stub.inspect}")
                        end
                    end
                else
                    log_warn("Invalid Argument: #{specifier.inspect}")
                end
                result
            end
            # Theme Supports:
            def load_theme(the_theme="")
                @theme = the_theme
                @theme_prefix = (::GxG::CONNECTION.relative_url() + "/themes/#{the_theme}")
                # 
                ::GxG::CONNECTION.pull_object("/content/themes/#{the_theme}") do |response|
                    GxG::Gui::Css.refresh_css_cache()
                    # Set CSS Rules:
                    if response.is_any?(::Hash, ::GxG::Database::PersistedHash)
                        if response.is_a?(::GxG::Database::PersistedHash)
                            response = response.unpersist()
                        end
                        if response[:resources].is_a?(::Array)
                            # Load Font and other Resources: response[:resources] (Array of Hashes)
                            # Font Resource Profile: {
                            #     :resource_type => "font-face",
                            #     :font_family => "Varela",
                            #     :font_style => "normal",
                            #     :font_weight => 400,
                            #     :format => "truetype",
                            #     :source => "http://fonts.gstatic.com/s/varela/v10/DPEtYwqExx0AWHX5Ax4B.ttf"
                            # }
                            response[:resources].each do |the_resource_profile|
                                if the_resource_profile.is_a?(::Hash)
                                    if the_resource_profile[:resource_type] == "font-face"
                                        ::GxG::Gui::Css::load_font(the_resource_profile)
                                    end
                                    # expand for other resource types
                                end
                            end
                        end
                        if response[:rules].is_a?(::Hash)
                            response[:rules].keys.each do |the_css_key|
                                GxG::Gui::Css.set_rule(the_css_key, response[:rules][(the_css_key)])
                            end
                        end
                    end
                    #
                end
            end
            # Component Building:
            def build_components(build_queue=[], the_application=nil)
                result = false
                if build_queue.is_any?(::Array, ::GxG::Database::PersistedArray)
                    while build_queue.size > 0 do
                        entry = build_queue.shift
                        if entry.is_any?(::Hash, ::GxG::Database::PersistedHash)
                            # Build out object based upon the record
                            if entry[:element].is_a?(::GxG::Gui::Page)
                                if entry[:record][:page_title]
                                    `document.title = #{entry[:record][:page_title].to_s}`
                                    # TODO: set meta data
                                    # Set classes for page:
                                    if entry[:record][:class].to_s.size > 0
                                        `document.body.setAttribute("class",#{entry[:record][:class].to_s})`
                                    end
                                    # Set Script if any is provided
                                    if entry[:record][:script].size > 0
                                        entry[:element].set_script(entry[:record][:script].to_s)
                                    end
                                end
                            else
                                # All other components / elements
                            end
                            # Queue up sub-components for construction
                            if entry[:record][:content].size > 0
                                entry[:record][:content].each do |sub_component|
                                    # puts "Building: #{sub_component.inspect}"
                                    case sub_component[:component].to_s.downcase.to_sym
                                    when :animation
                                        # store the animation in GxG::ANIMATION[:animations] hash (by uuid)
                                        if sub_component.is_a?(::GxG::Database::PersistedHash)
                                            the_uuid = sub_component.uuid.to_s.to_sym
                                            the_options = sub_component[:options].unpersist()
                                            unless the_options[:title].is_a?(::String)
                                                the_options[:title] = sub_component.title.to_s
                                            end
                                        else
                                            the_uuid = ::GxG::uuid_generate.to_s.to_sym
                                            the_options = sub_component[:options].clone
                                            unless the_options[:title].is_a?(::String)
                                                the_options[:title] = "Untitled Animation #{the_uuid.to_s}"
                                            end
                                        end
                                        GxG::ANIMATION[:animations][(the_uuid)] = GxG::Gui::Animation.new(the_options,the_uuid)
                                        if sub_component[:script].size > 0
                                            GxG::ANIMATION[:animations][(the_uuid)].set_script(sub_component[:script].to_s)
                                        end
                                        # store the animation assets in GxG::ANIMATION[:assets] hash (by uuid) (later)
                                        if sub_component[:content].size > 0
                                            sub_component[:content].each do |the_asset|
                                                # Expansion ??
                                            end
                                        end
                                    else
                                        #
                                        element_class = GxG::Gui::component_class(sub_component[:component].to_s.to_sym)
                                        if element_class
                                            if sub_component.is_a?(::GxG::Database::PersistedHash)
                                                the_options = sub_component[:options].unpersist()
                                                the_uuid = sub_component.uuid.to_s.to_sym
                                                if the_options[:title]
                                                    the_title = the_options.delete(:title)
                                                else
                                                    the_title = sub_component.title.to_s
                                                end
                                            else
                                                the_options = sub_component[:options].clone
                                                the_uuid = ::GxG::uuid_generate.to_sym
                                                if the_options[:title]
                                                    the_title = the_options.delete(:title)
                                                else
                                                    the_title = "Untitled Component #{the_uuid.to_s}"
                                                end
                                            end
                                            #
                                            the_style = the_options.delete(:style)
                                            the_states = (the_options.delete(:states) || {})
                                            app_location = the_options.delete(:location)
                                            app_name = the_options.delete(:name)
                                            if the_options[:track]
                                                tracking = the_options.delete(:track)
                                            else
                                                tracking = nil
                                            end
                                            #
                                            new_entry = {:parent => entry[:element], :record => sub_component, :element => entry[:element].add_child((the_uuid), element_class, the_options.merge!({:uuid => the_uuid}))}
                                            new_entry[:element].set_title(the_title)
                                            #
                                            self.register_object(the_title, new_entry[:element])
                                            # Window component tracking:
                                            if tracking
                                                the_window = new_entry[:element].window()
                                                if the_window
                                                    the_window.track_deltas(the_uuid,new_entry[:element],tracking)
                                                end
                                            end
                                            #
                                            # Set Layout info if any:
                                            if the_options[:zone]
                                                self.layout_add_item(the_uuid, the_options[:zone].to_s.to_sym, false)
                                            end
                                            # Set states:
                                            unless the_states.keys.include?(:hidden)
                                                the_states[:hidden] = false
                                            end
                                            new_entry[:element].gxg_set_states(the_states)
                                            # process style info:
                                            if the_style.is_a?(::Hash)
                                                new_entry[:element].gxg_set_style(the_style)
                                            end
                                            # linking
                                            if sub_component[:component].to_s.to_sym == :window
                                                if the_application.is_a?(::GxG::Application)
                                                    new_entry[:element].set_application(the_application)
                                                    unless the_application.get_window(the_uuid)
                                                        the_application.link_window(new_entry[:element])
                                                    end
                                                    if new_entry[:element].menu_reference()
                                                        the_menu_source = the_application.search_content(new_entry[:element].menu_reference())
                                                        if the_menu_source.is_any?(::Hash, ::GxG::Database::PersistedHash)
                                                            new_entry[:element].set_menu(the_menu_source)
                                                        else
                                                            log_warn("Invalid Menu Resource referenced: #{new_entry[:element].menu_reference().inspect}")
                                                        end
                                                    end
                                                end
                                                self.window_register(the_uuid, new_entry[:element])
                                            end
                                            if sub_component[:component].to_s.to_sym == :dialog_box
                                                if the_application.is_a?(::GxG::Application)
                                                    new_entry[:element].set_application(the_application)
                                                    unless the_application.get_window(the_uuid)
                                                        the_application.link_window(new_entry[:element])
                                                    end
                                                end
                                                # DialogBoxes are NOT registered with the windowing system!
                                            end
                                            if sub_component[:component].to_s.to_sym == :application_viewport
                                                #
                                                if the_application.is_a?(::GxG::Application)
                                                    new_entry[:element].set_application(the_application)
                                                    unless the_application.get_viewport(the_uuid)
                                                        the_application.link_viewport(new_entry[:element])
                                                    end
                                                else
                                                    if app_location.is_a?(::String) || app_name.is_a?(::String)
                                                        #
                                                        allocated = false
                                                        GxG::APPLICATIONS[:processes].keys.each do |the_app_key|
                                                            # FIXME: if an app is not :unique there is no garanteeing the load order will
                                                            # match the page's :application_viewport load order. So mismatched page viewports can result.
                                                            # That is: they may end up in reversed page/screen positions due to app assignment ordinal.
                                                            if GxG::APPLICATIONS[:processes][(the_app_key)].location == app_location || GxG::APPLICATIONS[:processes][(the_app_key)].title == app_name
                                                                #
                                                                unless GxG::APPLICATIONS[:processes][(the_app_key)].get_viewport(the_uuid)
                                                                    #
                                                                    new_entry[:element].set_application(GxG::APPLICATIONS[:processes][(the_app_key)])
                                                                    GxG::APPLICATIONS[:processes][(the_app_key)].link_viewport(new_entry[:element])
                                                                    allocated = true
                                                                    break
                                                                end
                                                            end
                                                        end
                                                        unless allocated == true
                                                            if app_location
                                                                specifier = {:location => app_location, :restore => true}
                                                            end
                                                            if app_name
                                                                specifier = {:name => app_name, :restore => true}
                                                            end
                                                            # Look for existing / loaded app to link viewport to
                                                            # if exists, link, if not: app_open and link
                                                            link_app = nil
                                                            GxG::APPLICATIONS[:processes].values.each do |application|
                                                                if specifier[:location]
                                                                    if specifier[:location] == application.location
                                                                        link_app = application
                                                                        break
                                                                    end
                                                                else
                                                                    if specifier[:name]
                                                                        if specifier[:name] == File.basename(application.location)
                                                                            link_app = application
                                                                            break
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                            if link_app
                                                                new_entry[:element].set_application(link_app)
                                                                link_app.link_viewport(new_entry[:element])
                                                            else
                                                                GxG::CONNECTION.application_open(specifier) do |app_stub|
                                                                    if app_stub[:result].is_a?(::Hash)
                                                                        GxG::CONNECTION.pull_object(app_stub[:result][:location]) do |source_object|
                                                                            GxG::APPLICATIONS[:processes][(app_stub[:result][:application].to_s.to_sym)] = GxG::Application.new(app_stub[:result].merge({:source => source_object, :viewport => new_entry[:element]}))
                                                                            new_entry[:element].set_application(GxG::APPLICATIONS[:processes][(app_stub[:result][:application].to_s.to_sym)])
                                                                            GxG::APPLICATIONS[:processes][(app_stub[:result][:application].to_s.to_sym)].link_viewport(new_entry[:element])
                                                                            #
                                                                        end
                                                                    else
                                                                        log_warn("Failure retrieving: #{specifier.inspect} --> #{app_stub.inspect}")
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    else
                                                        log_warn("Neither :location nor :name are specified!")
                                                    end
                                                    #
                                                end
                                            end
                                            # Set Script if any is provided
                                            if sub_component[:script].size > 0
                                                new_entry[:element].set_script(sub_component[:script].to_s)
                                            end
                                            #
                                            build_queue << new_entry
                                        end
                                        #
                                    end
                                end
                            end
                            #
                        end
                    end
                    result = true
                end
                result
            end
            #
            def load(page_profile=nil)
                # Build out page with page_profile
                if page_profile.is_any?(::Hash, ::GxG::Database::PersistedHash)
                    @title_registry = {}
                    @title_registry[(page_profile.uuid().to_s.to_sym)] = page_profile.title()
                    # Load CSS Theme
                    if page_profile[:theme].to_s.size > 0
                        self.load_theme(page_profile[:theme].to_s)
                    else
                        self.load_theme("default")
                    end
                    # Build a list of viewport application references
                    viewport_apps = []
                    page_profile[:content].search do |value, selector, container|
                        if selector == :location
                            viewport_apps << container[(selector)].to_s
                        end
                    end
                    # Restore prior-session applications: state-only, run @ tail end.
                    GxG::APPLICATIONS[:prefetch] = true
                    app_prefetched = []
                    skipped_apps = 0
                    list_failure = Proc.new do |response|
                        log_warn("Application List Failure: #{response.inspect}")
                        GxG::APPLICATIONS[:prefetch] = false
                    end
                    GxG::CONNECTION.application_list(list_failure) do |list_response|
                        if list_response[:result].is_a?(::Array)
                            if list_response[:result].size > 0
                                GxG::APPLICATIONS[:prefetch] = true
                                list_response[:result].each do |entry|
                                    # entry: {:application => <ProcessUUID>, :credentialed => false, :unique => true, :location => "/Path/to/app"}
                                    GxG::CONNECTION.pull_object(entry[:location]) do |source_object|
                                        if GxG::DISPLAY_DETAILS[:logged_in] == true
                                            app_prefetched << entry[:application].to_s.to_sym
                                            GxG::APPLICATIONS[:processes][(entry[:application].to_s.to_sym)] = GxG::Application.new(entry.merge({:source => source_object}))
                                        else
                                            if source_object[:credentialed] == true
                                                skipped_apps += 1
                                            else
                                                app_prefetched << entry[:application].to_s.to_sym
                                                GxG::APPLICATIONS[:processes][(entry[:application].to_s.to_sym)] = GxG::Application.new(entry.merge({:source => source_object}))
                                            end
                                        end
                                        if (GxG::APPLICATIONS[:processes].size + skipped_apps) == list_response[:result].size
                                            self.build_components([{:parent => nil, :record => page_profile, :element => self}])
                                        else
                                            GxG::APPLICATIONS[:prefetch] = true
                                        end
                                    end                                   
                                end
                            else
                                # Load Page and Components
                                self.build_components([{:parent => nil, :record => page_profile, :element => self}])
                            end
                        end
                    end
                    prefetch_timer = nil
                    prefetch_timer = GxG::DISPATCHER.add_periodic_timer({:interval => 0.5}) do
                        if GxG::APPLICATIONS[:prefetch] == true
                            loaded_apps = 0
                            GxG::APPLICATIONS[:processes].values.each do |the_app|
                                if viewport_apps.include?(the_app.location.to_s)
                                    loaded_apps += 1
                                end
                            end
                            if loaded_apps == viewport_apps.size
                                GxG::APPLICATIONS[:prefetch] = false
                            end
                        else
                            self.set_busy true
                            #
                            GxG::APPLICATIONS[:processes].values.each do |the_app|
                                if app_prefetched.include?(the_app.process_uuid)
                                    the_app.run({:restore => true})
                                else
                                    the_app.run()
                                end
                            end
                            GxG::DISPATCHER.cancel_timer(prefetch_timer)
                            self.set_busy false
                        end
                    end
                    #
                end
            end
            #
            def start(navigate_to="")
                request_path = navigate_to[(::GxG::CONNECTION.relative_url().size)..-1]
                if request_path == "/"
                    request_path = "/index"
                end
                ::GxG::DISPLAY_DETAILS[:host_path] = request_path
                # Load Page Content
                ::GxG::CONNECTION.pull_object("/content/pages#{request_path}") do |response|
                    self.load(response)
                    self.layout_refresh
                end
            end
            #
            def stop()
                #
            end
            #
        end
        #
    end
end
#
