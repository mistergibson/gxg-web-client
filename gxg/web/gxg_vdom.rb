module GxG
    module Gui
        module Vdom
          @@CssCache = []
          @@CssRuleProperties = {}
          #
          def self.load_font(font_profile=nil)
              if font_profile.is_any?(::Hash, ::GxG::Database::DetachedHash,  ::GxG::Database::DetachedHash)
                  if font_profile.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
                      font_profile = font_profile.unpersist()
                  end
                  if font_profile[:resource_type] == "font-face"
                      thefamily = (font_profile[:font_family] || "Unknown").to_s
                      thestyle = (font_profile[:font_style] || "normal").to_s
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
                          source_url = ::GxG::CONNECTION.relative_url().to_s + font_profile[:source]
                          # source_url = GxG::DISPLAY_DETAILS[:object].site_asset(font_profile[:source])
                      end
                    #   puts "Source: #{source_url.inspect}"
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
              GxG::Gui::Vdom::valid_properties()
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
          def self.style_sheet()
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
              the_style_sheet = GxG::Gui::Vdom::style_sheet()
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
                        new_cache << GxG::Gui::Vdom::CSSRule.new(native_rule)
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
          def self.rule_names()
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
          def self.clear_rules()
            list = ::GxG::Gui::Vdom::rule_names()
            list.each do |the_rule_name|
                unless the_rule_name == :".hidden"
                    ::GxG::Gui::Vdom::remove_rule(the_rule_name)
                end
            end
            true
          end
          #
          def self.set_rule(the_rule_selector=nil, the_properties={}, options={:merge => true})
            # find existing
            # remove existing
            # create or re-create
            the_style_sheet = GxG::Gui::Vdom::style_sheet()
            if the_style_sheet
              found = GxG::Gui::Vdom::find_rule(the_rule_selector)
              if found.size > 0
                  GxG::Gui::Vdom::remove_rule(the_rule_selector)
              end
              # create it
              the_site_prefix = ::GxG::CONNECTION.relative_url()
              rule_string = "{ "
              the_properties.keys.each do |property_key|
                  the_value = the_properties[(property_key)].to_s
                  if the_value.include?("url(")
                      end_point = the_value.index(")")
                      the_path = the_value[4..(end_point - 1)]
                      if the_path[0] == "'" || the_path[0] == '"'
                        the_path = the_path[1..-1]
                      end
                      if the_path[-1] == "'" || the_path[-1] == '"'
                        the_path = the_path[0..-2]
                      end
                      unless the_path.include?("data:") || the_path.include?("http:") || the_path.include?("https:")
                          unless (the_path[(0..(the_site_prefix.size - 1))] == the_site_prefix)
                              the_value = ("url('" + File.expand_path(the_site_prefix + "/" + the_path) + "')").gsub("//","/")
                          end
                      end
                  end
                  rule_string = rule_string + ("#{property_key.to_s}: #{the_value.to_s}; ")
              end
              rule_string = rule_string + " }"
              if `#{the_style_sheet}.insertRule(#{the_rule_selector.to_s + rule_string.to_s},(#{the_style_sheet}.cssRules.length))`.to_i == `(#{the_style_sheet}.cssRules.length - 1)`.to_i
                  begin
                      native_rule = `#{the_style_sheet}.cssRules[(#{the_style_sheet}.cssRules.length - 1)]`
                  rescue Exception => the_error
                      native_rule = `#{the_style_sheet}.rules[(#{the_style_sheet}.cssRules.length - 1)]`
                  end
                  @@CssCache << GxG::Gui::Vdom::CSSRule.new(native_rule)
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
                      the_sheet = GxG::Gui::Vdom::style_sheet()
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
          # Derivitive of Ferro Virtual Dom gem (greatly simplified)
          # --------------------------------------------------------------------------------------------------------------------------------------
          module ElementMethods
              # Internal Methods:
              def _before_create;end
              def before_create;end
              # ## Calls the factory to create the DOM element.
              def create
                if @domtype
                    @element = factory.create_element(self, @domtype, @parent, @options)
                end
              end
              #
              def _after_create
                self.update_classes
                _stylize
              end
              #
              def after_create;end
              # Override this method to return a Hash of styles.
              # Hash-key is the CSS style name, hash-value is the CSS style value.
              def style
                @style ||= {}
              end
              def _stylize
                styles = style
          
                if styles.class == Hash
                  set_attribute(
                    'style',
                    styles.map { |k, v| "#{k}:#{v};" }.join
                  )
                end
              end
              # Override this method to continue the MOM creation process.
              def cascade;end
              # ## Creation
              def creation
                _before_create
                before_create
                create
                _after_create
                after_create
                _stylize
                cascade
              end
              # Add a child element.
              #
              # @param [String] name A unique name for the element that is not
              #   in RESERVED_NAMES
              # @param [String] element_class Ruby class name for the new element
              # @param [Hash] options Options to pass to the element. Any option key
              #   that is not recognized is set as an attribute on the DOM element.
              #   Recognized keys are:
              #     prepend Prepend the new element before this DOM element
              #     content Add the value of content as a textnode to the DOM element
              def add_child(options={})
                new_child = nil
                if options[:component].to_s.downcase.to_sym == :unknown
                    raise "Unknown Component Type"
                else
                    element_class = GxG::Gui::component_class(options[:component].to_s.downcase.to_sym)
                    if element_class.is_a?(::Class)
                        new_child = element_class.new(self,options)
                        @children[(new_child.title.to_s.to_sym)] = new_child
                        # Register Object with Page
                        ::GxG::DISPLAY_DETAILS[:object].register_object(new_child.title, new_child)
                    else
                        raise "Unknown Component Type"
                    end
                end
                new_child
              end
              #
              def each_child(&block)
                @children.values.each do |the_child|
                    block.call(the_child)
                end
              end
              # Recursively iterate all child elements
              def all_descendants(&block)
                @process_queue = @children.values.clone
                while @process_queue.size > 0 do
                    entry = @process_queue.shift
                    if entry
                        block.call(entry)
                        if entry.children.values.size > 0
                            entry.each_child do |the_child|
                                @process_queue << the_child
                            end
                        end
                    end
                end
              end
              # Remove all child entries.
              def forget_children
                clearing_queue = @children.values
                while clearning_queue.size > 0
                    entry = clearing_queue.shift
                    if entry
                        entry.children.values.each do |the_child|
                            clearing_queue << the_child
                        end
                        page.unregister_object(entry.title.to_s)
                    end
                end
                @children = {}
              end
              #
              # Remove a specific child entry.
              def forget_child(the_title)
                page.unregister_object(the_title)
                @children.delete(the_title.to_s.to_sym)
              end
              # Remove a DOM element.
              def destroy
                self.every_child do |the_child|
                    the_child.remove_listeners
                    page.unregister_object(the_child.title.to_s)
                end
                self.remove_listeners
                parent.forget_child(@title.to_s)
                `#{parent.element}.removeChild(#{element})`
                true
              end
          
              # Getter for children.
              def method_missing(method_name, *args, &block)
                if @children.has_key?(method_name)
                  @children[method_name]
                else
                  super
                end
              end
              # ### Element identity
              # Get the id of the elements corresponding DOM element
              #
              # @return [String] The id
              def dom_id
                # "_#{self.object_id}"
                self.uuid.to_s
              end
              #
              def title()
                  @title
              end
              #
            #   def title=(the_title=nil)
            #       if the_title.is_any?(::String, ::Symbol)
            #           @title = the_title
            #       end
            #   end
              #
              # ### Universal Element Style, Class, and Attribute Methods:
              def update_classes()
                  new_classes = ""
                  class_list = `#{@element}.className`.split(" ")
                  class_list.each_with_index do |the_classname, indexer|
                      unless @states.keys.include?(the_classname.to_s.to_sym)
                        new_classes = (new_classes + the_classname)
                        unless the_classname == class_list.last
                            new_classes = (new_classes + " ")
                        end
                      end
                  end
                  if @states.keys.size > 0
                    new_classes = (new_classes + " ")
                  end
                  @states.each_pair do |the_state, the_value|
                      if the_value == true
                        new_classes = (new_classes + the_state.to_s)
                        unless @states.keys.last == the_state
                            new_classes = (new_classes + " ")
                        end
                      else
                          # `#{@element}.classList.remove(#{the_state.to_s})`
                      end
                  end
                  `#{@element}.className = #{new_classes.to_s}`
                  true
              end
              # Delete a key from the elements options hash. Will be renamed
              # to option_delete.
              #
              # @param [key] key Key of the option hash to be removed
              # @param [value] default Optional value to use if option value is nil
              # @return [value] Return the current option value or value of
              #   default parameter
              def option_replace(key, default = nil)
                value = @options[key] || default
                @options.delete(key) if @options.has_key?(key)
                value
              end
              #
              def set_state(the_state, the_value=false)
                  if the_value == true
                      @states[(the_state.to_s.to_sym)] = true
                  else
                      @states[(the_state.to_s.to_sym)] = false
                  end
                  self.update_classes
              end
              #
              def set_states(the_state_list={})
                  the_state_list.each_pair do |the_state, the_value|
                      if the_value == true
                          @states[(the_state.to_s.to_sym)] = true
                      else
                          @states[(the_state.to_s.to_sym)] = false
                      end
                  end
                  self.update_classes
              end
              #
              def get_state(the_state)
                  (@states[(the_state.to_s.to_sym)] || false)
              end
              #
              def get_states()
                  @states
              end
              #
              def toggle_state(the_state)
                  self.set_state(the_state,(! self.get_state(the_state)))
              end
              # Determine if the state is active
              #
              # @param [String] state The state name
              # @return [Boolean] The state value
              def state_active?(the_state)
                  @states.keys.include?(the_state.to_s.to_sym)
              end
              # @param [Array] states An array of state names to add to the
              #   element. All disabled (false) state initially.
              def add_states(states)
                states.each do |state|
                  add_state(state)
                end
              end            
              # Add a state to the element. A state toggles a CSS class with the
              # same (dasherized) name as the state.
              # If the state is thruthy (not nil or true) the CSS class is added
              # to the element. Otherwise the CSS class is removed.
              #
              # @param [String] state The state name to add to the element
              # @param [value] value The initial enabled/disabled state value
              def add_state(state, value = false)
                  self.set_state(state,value)
              end
              # Get the current html value of the element
              #
              # @return [String] The html value
              def value
                `#{@element}.innerHTML`
              end
          
              # Get the current text content of the element
              #
              # @return [String] The text value
              def get_text
                `#{@element}.textContent`
              end
          
              # Set the current html value of the element
              # Useful for input elements
              #
              # @param [String] The new value
              def value=(value)
                `#{@element}.value = #{value}`
              end
          
              # Set the current text content of the element
              #
              # @param [String] value The new text value
              def set_text(value)
                # https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent
                `#{@element}.textContent = #{value}`
              end
              # Set the current html content of the element. Use with caution if
              # the html content is not trusted, it may be invalid or contain scripts.
              #
              # @param [String] raw_html The new html value
              def html(raw_html)
                `#{@element}.innerHTML = #{raw_html}`
              end
              #
              #
              def set_style(the_style={})
                  new_style = ""
                  if the_style.is_a?(::Hash)
                      the_style.each_pair do |property,value|
                          new_style = (new_style + "#{property.to_s}: " + "#{value.to_s};")
                      end
                      `#{@element}.setAttribute("style", #{new_style}); `
                      true
                  else
                      false
                  end
              end
              #
              def merge_style(the_style={})
                  if the_style.is_a?(::Hash)
                      the_style.each_pair do |property,value|
                          `#{element}.style[#{property}]=#{value.to_s}`
                      end
                      true
                  else
                      false
                  end
              end
              #
              def set_bg_color(the_color=0)
                  self.merge_style({:"background-color" => "##{the_color.to_s}"})
              end
              #
              def get_attribute(the_attribute=nil)
                  result = ""
                  if the_attribute
                      the_element = self.element
                      the_value = nil
                      # Boolean Attributes: if attribute exists, can be a boolean.
                      # if present returns "true" if null (since it exists), else other value
                      %x{
                          if (the_element.getAttributeNames().includes(the_attribute)) {
                              if (the_element.getAttribute(the_attribute) != null) {
                                  the_value = the_element.getAttribute(the_attribute);
                              } else {
                                  the_value = true;
                              };
                          };
                      }
                      result = the_value.to_s
                  end
                  result
              end
              #
              def set_attribute(the_attribute=nil, the_value=nil)
                  result = false
                  if the_attribute
                      if the_value
                          result = `#{self.element}.setAttribute(#{the_attribute},#{the_value})`
                      else
                          # Boolean attribute
                          result = `#{self.element}.setAttribute(#{the_attribute},null)`
                      end
                  end
                  result
              end
              #
              def clear_attribute(the_attribute=nil)
                  result = false
                  if the_attribute
                      `#{self.element}.removeAttribute(#{the_attribute})`
                      result = true
                  end
                  result
              end
              def each_child(&block)
                  if block.respond_to?(:call)
                      @children.values.each do |the_child|
                          block.call(the_child)
                      end
                  else
                      @children.values.each
                  end
              end
              #
              def every_child(&block)
                child_manifest = []
                build_queue = [(self)]
                while build_queue.size > 0 do
                    entry = build_queue.shift
                    if entry
                        if entry.children.keys.size > 0
                            entry.children.values.each do |the_child|
                                child_manifest << the_child
                                if the_child.children.keys.size > 0
                                    build_queue << the_child
                                end
                            end
                        end
                    end
                end
                if block.respond_to?(:call)
                    child_manifest.each do |the_child|
                        block.call(the_child)
                    end
                else
                    child_manifest.values.each
                end
              end
              # ### Finding Objects
              def find_child(the_reference=nil)
                  result = nil
                  search_queue = self.children.values
                  while search_queue.size > 0 do
                      entry = search_queue.shift
                      if entry
                        if entry.uuid == the_reference || entry.title == the_reference || entry.component == the_reference || entry.class == the_reference || entry.domtype == the_reference
                          result = entry
                          break
                        end
                        #
                      end
                  end
                  result
              end
              #
              def find_descendant(the_reference=nil)
                result = nil
                search_queue = self.children.values
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                      if entry.uuid == the_reference || entry.title == the_reference || entry.component == the_reference || entry.class == the_reference || entry.domtype == the_reference
                        result = entry
                        break
                      end
                      #
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
              def find_descendants(the_reference=nil)
                result = []
                search_queue = self.children.values
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                      if entry.uuid == the_reference || entry.title == the_reference || entry.component == the_reference || entry.class == the_reference || entry.domtype == the_reference
                        result << entry
                      end
                      #
                      entry.children.values.each do |the_child|
                        search_queue << the_child
                      end
                    end
                end
                result
              end
              #
              def find_ancestor(the_reference=nil)
                result = nil
                search_queue = [(self.parent)]
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if entry.uuid == the_reference || entry.title == the_reference || entry.component == the_reference || entry.class == the_reference || entry.domtype == the_reference
                            result = entry
                            break
                        else
                            unless entry.component == :page
                                search_queue << entry.parent
                            end
                        end                        
                    end
                end
                result
              end
              #
              def find_ancestors(the_reference=nil)
                result = []
                search_queue = [(self.parent)]
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if entry.uuid == the_reference || entry.title == the_reference || entry.component == the_reference || entry.class == the_reference || entry.domtype == the_reference
                            result << entry
                        end
                        unless entry.component == :page
                            search_queue << entry.parent
                        end      
                    end
                end
                result
              end
              #
          end
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
                result = false
                  unless @event_handlers.is_a?(::Hash)
                      @event_handlers = {}
                      @event_listeners = {}
                  end
                  if the_event_type.is_any?(::String, ::Symbol)
                      if block.respond_to?(:call)
                          @event_handlers[(the_event_type.to_s.downcase.to_sym)] = block
                          @event_listeners[(the_event_type.to_s.downcase.to_sym)] = `#{self.method(:event_handler).to_proc}`
                          `#{self.element}.addEventListener(#{the_event_type.to_s.downcase}, #{@event_listeners[(the_event_type.to_s.downcase.to_sym)]}, #{captured})`
                          result = true
                      end
                  end
                  result
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
              def remove_listeners()
                @event_handlers.keys.clone.each do |the_event_type|
                  self.remove_listener(the_event_type)
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
                  genre = (GxG::Gui::Vdom::EventHandlers::EVENT_GENRES[(the_type)] || :event)
                  if genre
                      fields = GxG::Gui::Vdom::EventHandlers::EVENT_FIELDS[(genre)]
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
              def set_script(the_script_body="", alternate_target=nil)
                  result = false
                  if the_script_body.size > 0
                      #
                      begin
                          #
                          if the_script_body.base64?
                              the_script_body = the_script_body.decode64
                          end
                          #
                          if alternate_target
                            alternate_target.remove_listeners()
                            alternate_target.instance_eval(the_script_body)
                          else
                            self.remove_listeners()
                            instance_eval(the_script_body)
                          end
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
          class Animation
            include GxG::Gui::Vdom::EventHandlers
              #
              def initialize(details={}, the_uuid=nil)
                  @event_handlers = {}
                  @event_listeners = {}
                    if details.is_any?(::Hash, ::GxG::Database::DetachedHash)
                        if details[:origin]
                            if details[:origin].is_a?(::GxG::Database::DetachedHash)
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
                        if details[:destination].is_a?(::GxG::Database::DetachedHash)
                            @destination = details[:destination].unpersist
                        else
                            @destination = details[:destination]
                        end
                        #
                        if details[:options]
                          @options = {}
                            if details[:options].is_a?(::GxG::Database::DetachedHash)
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
                        if details[:targets].is_a?(::GxG::Database::DetachedHash)
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
                  if data.is_any?(::Hash, ::GxG::Database::DetachedHash)
                        if data.is_a?(::GxG::Database::DetachedHash)
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
                  if data.is_any?(::Hash, ::GxG::Database::DetachedHash)
                        if data.is_a?(::GxG::Database::DetachedHash)
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
                  if data.is_any?(::Hash, ::GxG::Database::DetachedHash)
                        if data.is_a?(::GxG::Database::DetachedHash)
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
                  if data.is_any?(::Hash, ::GxG::Database::DetachedHash)
                        if data.is_a?(::GxG::Database::DetachedHash)
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
                              found_object = GxG::DISPLAY_DETAILS[:object].find_child(element_id.to_s)
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
          # --------------------------------------------------------------------------------------------------------------------------------------
          module AnimationSupport
              #
              def animate(animation_parameters=nil)
                  if animation_parameters[:destination].is_any?(::Hash, ::GxG::Database::DetachedHash)
                      the_animation = ::GxG::Gui::Vdom::Animation.new({:targets => {:elements => [(self.element)]}, :origin => animation_parameters[:origin], :destination => animation_parameters[:destination], :options => animation_parameters[:options]})
                      start_time = `window.performance.now()`
                      if animation_parameters[:options].is_any?(::Hash, ::GxG::Database::DetachedHash)
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
                  if transition_parameters.is_any?(::Hash, ::GxG::Database::DetachedHash)
                      if transition_parameters.is_a?(::GxG::Database::DetachedHash)
                          transition_parameters = transition_parameters.unpersist
                      end
                      #
                      if transition_parameters[:destination].is_a?(::Hash)
                          if transition_parameters[:destination][:opacity].is_a?(::Numeric)
                              if transition_parameters[:origin].is_a?(::Hash)
                                  if transition_parameters[:origin][:opacity].is_a?(::Numeric)
                                      self.merge_style({:opacity => transition_parameters[:origin][:opacity]})
                                  else
                                      self.merge_style({:opacity => 0})
                                  end
                              else
                                  self.merge_style({:opacity => 0})
                              end
                          end
                      end
                      self.set_state(:hidden, false)
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
                      self.set_state(:hidden, false)
                      if block.respond_to?(:call)
                          block.call()
                      end
                  end
                  # GxG::DISPLAY_DETAILS[:object].layout_refresh
                  ::GxG::Gui::layout_refresh
                  true
              end
              #
              def hide(transition_parameters=nil,&block)
                  if transition_parameters.is_any?(::Hash, ::GxG::Database::DetachedHash)
                      if transition_parameters.is_a?(::GxG::Database::DetachedHash)
                          transition_parameters = transition_parameters.unpersist
                      end
                      if block.respond_to?(:call)
                          unless transition_parameters[:options]
                              transition_parameters[:options] = {}
                          end
                          transition_parameters[:options][:animationend] = Proc.new do
                              self.set_state(:hidden, true)
                              block.call()
                          end
                      else
                          set_state = nil
                          if transition_parameters[:options]
                              if transition_parameters[:options][:animationend].respond_to?(:call)
                                  old_complete = transition_parameters[:options][:animationend]
                                  set_state = Proc.new do
                                      old_complete.call()
                                      self.set_state(:hidden, true)
                                  end
                              else
                                  set_state = Proc.new do
                                      self.set_state(:hidden, true)
                                  end
                              end
                          else
                              transition_parameters[:options] = {}
                              set_state = Proc.new do
                                  self.set_state(:hidden, true)
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
                      self.set_state(:hidden, true)
                      if block.respond_to?(:call)
                          block.call()
                      end
                  end
                  # GxG::DISPLAY_DETAILS[:object].layout_refresh
                  ::GxG::Gui::layout_refresh
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
              #
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
              def find_peer(the_reference=nil)
                self.parent.find_child(the_reference)
              end
              #
          end
          # --------------------------------------------------------------------------------------------------------------------------------------
          module ThemeSupport
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
          #
          # Create DOM elements.
          class Factory
        
          attr_reader :body
      
          # Creates the factory. Do not create a factory directly, instead
          # call the 'factory' method that is available in all Ferro classes
          #
          # @param [Object] target The Ruby class instance
          # @param [Compositor] compositor A style-compositor object or nil
          def initialize(target)
            @body = `document.body`
            %x{
                while (document.body.firstChild) {
                    document.body.removeChild(document.body.firstChild);
                };
            }
            # composite_classes(target, @body, false)
          end
      
          # Create a DOM element.
          #
          # @param [Object] target The Ruby class instance
          # @param [String] type Type op DOM element to create
          # @param [String] parent The Ruby parent element
          # @param [Hash] options Options to pass to the element.
          #   See FerroElementary::add_child
          # @return [String] the DOM element
          def create_element(target, type, parent, options = {})
            # Create element
            if type == :body
                element = `document.body`
            else
                element = `document.createElement(#{type})`
            end
      
            # Add element to DOM
            unless type == :body
                if options[:prepend] == true
                  `#{parent.element}.insertBefore(#{element}, #{options[:prepend].element})`
                else
                  `#{parent.element}.appendChild(#{element})`
                end
            end
      
            # if !@compositor
            #   # Add ruby class to the node
            `#{element}.classList.add(#{dasherize(target.class.name)})`
      
            #   # Add ruby superclass to the node to allow for more generic styling
            #   if target.class.superclass != BaseElement
            #     `#{element}.classList.add(#{dasherize(target.class.superclass.name)})`
            #   end
            # else
            #   # Add classes defined by compositor
            #   composite_classes(target, element, target.class.superclass != BaseElement)
            # end
      
            # Set ruby object_id as default element id
            if !options.has_key?(:id)
              `#{element}.id = #{target.uuid.to_s}`
            end
      
            # Set attributes
            # Review : alter to support set_attribute toolbox and Foundation
            options.each do |name, value|
              case name
              when :prepend
                nil
              when :content
                `#{element}.appendChild(document.createTextNode(#{value}))`
              else
                `#{element}.setAttribute(#{name}, #{value})`
              end
            end
      
            element
          end
      
          # Convert a Ruby classname to a dasherized name for use with CSS.
          #
          # @param [String] class_name The Ruby class name
          # @return [String] CSS class name
          def dasherize(class_name)
              the_name = class_name.gsub("::","-").downcase.gsub("_","-")
              if the_name[0] == "-"
                  the_name = the_name[(1..-1)]
              end
              the_name
          end          
          # Convert a CSS classname to a camelized Ruby class name.
          #
          # @param [String] class_name CSS class name
          # @return [String] A Ruby class name
          def camelize(class_name)
              return class_name if class_name !~ /-/
              class_name.gsub(/(?:-|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.strip
          end        
          # Convert a state-name to a list of CSS class names.
          #
          # @param [String] class_name Ruby class name
          # @param [String] state State name
          # @return [String] A list of CSS class names
          #   def composite_state(class_name, state)
          #     if @compositor
          #       list = @compositor.css_classes_for("#{class_name}::#{state}")
          #       return list if !list.empty?
          #     end
      
          #     [ dasherize(state) ]
          #   end
        
          # Internal method
          # Composite CSS classes from Ruby class name
          # def composite_classes(target, element, add_superclass)
          # if @compositor
          #     composite_for(target.class.name, element)
      
          #     if add_superclass
          #     composite_for(target.class.superclass.name, element)
          #     end
          # end
          # end
        
          # Internal method
          #   def composite_for(classname, element)
          #     @compositor.css_classes_for(classname).each do |name|
          #       `#{element}.classList.add(#{name})`
          #     end
          #   end
          end
          # End Factory
          class BaseElement

              include GxG::Gui::Vdom::ElementMethods
              include GxG::Gui::Vdom::EventHandlers
              include GxG::Gui::Vdom::AnimationSupport
              include GxG::Gui::Vdom::ApplicationSupport
              include GxG::Gui::Vdom::ThemeSupport

              attr_reader :uuid, :title, :component, :parent, :children, :element, :domtype, :settings
            def set_settings(the_settings=nil)
                @settings = the_settings
            end
            alias :settings= :set_settings
              # Create the element and continue the creation
              # process (casading).
              # Ferro elements should not be instanciated directly. Instead the
              # parent element should call the add_child method.
              #
              # @param [String] parent The parent Ruby element
              # @param [Hash] options Any options for the creation process
              def initialize(parent, options = {})
                if options.is_a?(GxG::Database::DetachedHash)
                    @uuid = options.uuid.to_s.to_sym
                    @title = options.title.to_s
                else
                    @uuid = (options[:uuid] || ::GxG::uuid_generate()).to_s.to_sym
                    @title = (options[:title] || "Untitled Component #{@uuid.to_s}").to_s
                end
                @component = (options[:component] || :unknown).to_s.downcase.to_sym
                @parent   = parent
                @settings = options[:settings]
                @children = {}
                @element  = nil
                @domtype  = :div
                # ### CSS states
                @states = {}
                @states[(@component.to_s.gsub(".","-").to_sym)] = true
                if options[:options].is_a?(::Hash, GxG::Database::DetachedHash)
                    if options[:options][:states].is_a?(::Array, GxG::Database::DetachedArray)
                        options[:options][:states].each do |the_state|
                            @states[(the_state.to_s.to_sym)] = true
                        end
                    end
                end
                # ### Style
                @style = {}
                if options[:options].is_a?(::Hash, GxG::Database::DetachedHash)
                    if options[:options][:style].is_a?(::Hash, GxG::Database::DetachedHash)
                        @style = options[:options][:style]
                    end
                end
                # ### Other Attributes
                @options = {}
                if options[:options].is_a?(::Hash, GxG::Database::DetachedHash)
                    options[:options].each_pair do |the_option, the_value|
                        unless [:"background-color", :icon, :label, :data, :content, :uuid, :title, :opacity, :window_title, :menu, :top, :right, :bottom, :left, :height, :width, :close, :minimize, :maximize, :resize, :scroll, :modal, :track, :states, :style].include?(the_option.to_s.to_sym)
                            @options[(the_option.to_s.to_sym)] = the_value.to_s
                        end
                    end
                end
                # Event Stuff
                @event_handlers = {}
                @event_listeners = {}
                #
                creation
                #
                if options[:options].is_a?(::Hash, GxG::Database::DetachedHash)
                    if options[:content].is_a?(::String)
                        self.set_text(options[:content])
                    end
                end
                # Review : return self ??
                self
              end
              #
              def parent()
                @parent
              end
              # Searches the element hierarchy upwards until the root element is found.
              def root
                result = nil
                search_queue = [(@parent)]
                while search_queue.size > 0 do
                    entry = search_queue.shift
                    if entry
                        if entry.component == :page
                            result = entry
                            break
                        else
                            search_queue << entry.parent()
                        end
                    end
                end
                result
              end
              # Searches the element hierarchy upwards until the factory is found
              def factory
                self.root.factory
              end
              #
                def build(content_manifest=nil, options={})
                    page.build_components(self, content_manifest, options)
                end
              #
          end
          # End BaseElement
          class BaseInputElement < ::GxG::Gui::Vdom::BaseElement
            def _before_create
              super()
              @domtype = :input
              @options[:type] ||= :text
              if @options[:content]
                @options[:value] = @options.delete(:content)
              end
              @disabled = @options[:disabled] || false
            end
            # Getter method for input value.
            def value
              `#{@element}.value`
            end
            # Setter method for input value.
            def value=(value)
              `#{@element}.value = #{value}`
            end
            #
            def _after_create
              super()
              if @disabled
                disable
              end
            end
            # Disable this input.
            def disable
              set_attribute(:disabled, "disabled")
            end
            # Enable this input.
            def enable
              clear_attribute(:disabled)
            end
          end
          # End BaseInputElement
          class BaseClickableElement < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
              super()
            #   on(:click) do |event|
            #     `document.activeElement.blur()`
            #   end
            end
            # Review : alter default click behavior ?? Requires setting on(:click);`document.activeElement.blur()`;end sequence.
          end
          # End BaseClickableElement
          #
          # This is the entry point for any Ferro application.
          # It represents the top level object of the
          # Master Object Model (MOM).
          # There should be only one class that inhertits
          # from FerroDocument in an application.
          # This class attaches itself to the DOM
          # `document.body` object.
          # Any existing child nodes of `document.body` are removed.
            class Page
                include GxG::Gui::Vdom::ElementMethods
                include GxG::Gui::Vdom::EventHandlers
                include GxG::Gui::Vdom::AnimationSupport
                include GxG::Gui::Vdom::ApplicationSupport
                include GxG::Gui::Vdom::ThemeSupport
                # Universal attribute readers:
                attr_reader :uuid, :title, :component, :parent, :children, :domtype, :settings
                def set_settings(the_settings=nil)
                    @settings = the_settings
                end
                alias :settings= :set_settings
                # Page-specific attribute readers (if not covered by a method):
                # ### Loading Libraries
                def get_library(the_reference=nil)
                    result = nil
                    if the_reference.is_any?(::Hash, ::GxG::Database::DetachedHash)
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
                    if the_reference.is_any?(::Hash, ::GxG::Database::DetachedHash)
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
                    if criteria.is_any?(::Hash, ::GxG::Database::DetachedHash)
                        # {:library => "lib-name", :manifest => true/false, :dependencies => true/false, :minimum => 0.0, :maximum => 0.0, :loaded => [<UUID>...]}
                        if criteria[:maximum]
                            maximum = criteria[:maximum].to_f
                        else
                            maximum = nil
                        end
                        GxG::CONNECTION.library_pull({:library => criteria[:library].to_s, :type => (criteria[:type] || "text/ruby").to_s, :minimum => (criteria[:minimum] || 0.0).to_f, :maximum => maximum,:dependencies => true, :loaded => GxG::APPLICATIONS[:libraries].keys}) do |response|
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
                                                if definition.is_a?(::GxG::Database::DetachedHash)
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
                    if load_queue.is_any?(::Array, ::GxG::Database::DetachedArray)
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
                # ### Application Supports:
                def application_open(specifier={}, parameters={})
                    result = false
                    if specifier.is_a?(::Hash)
                        error_hander = Proc.new {
                            # self.set_busy(false)
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
                # ### Theme Supports:
                def site_asset(asset_path=nil)
                    if (`window.location['href']`).include?("https://")
                        host_prefix = ("https://" + `window.location['host']`)
                    else
                        host_prefix = ("http://" + `window.location['host']`)
                    end
                    if ::GxG::CONNECTION.relative_url().to_s[0] != "/"
                        host_prefix = (host_prefix + "/")
                    end
                    if asset_path
                        (host_prefix + File.expand_path((::GxG::CONNECTION.relative_url().to_s + "/" + asset_path.to_s)))
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
                # ### Component Building
                def build_components(root_object=nil, content_manifest=nil, options={})
                    result = false
                    #
                    unless root_object
                        root_object = ::GxG::DISPLAY_DETAILS[:object]
                    end
                    #
                    if root_object && content_manifest.is_any?(::Array,  ::GxG::Database::DetachedArray)
                        build_queue = [{:parent => root_object, :content => content_manifest}]
                        while build_queue.size > 0 do
                            record = build_queue.shift
                            if record
                                record[:content].each do |the_entry|
                                    new_object = record[:parent].add_child(the_entry)
                                    if the_entry[:content].size > 0
                                        build_queue << {:parent => new_object, :content => the_entry[:content]}
                                    end
                                    # Embed new object settings
                                    # new_object.set_settings(the_entry[:settings])
                                    # Link viewport to provided application
                                    if the_entry[:component].to_s.downcase.to_sym == :application_viewport && options[:application]
                                        new_object.set_application(options[:application])
                                        unless options[:application].get_viewport(new_object.uuid)
                                            options[:application].link_viewport(new_object)
                                        end
                                    end
                                    # Link window to provided application
                                    if the_entry[:component].to_s.downcase.to_sym == :window && options[:application]
                                        options[:application].link_window(new_object)
                                        new_object.set_application(options[:application])
                                    end
                                    # Link dialog_box to provided application
                                    if the_entry[:component].to_s.downcase.to_sym == :dialog_box && options[:application]
                                        new_object.set_application(options[:application])
                                    end
                                    # Window Content Tracking
                                    if record[:parent].is_a?(::GxG::Gui::Window)
                                        if the_entry[:options][:track]
                                            record[:parent].track_deltas(new_object.uuid, new_object, the_entry[:options][:track])
                                        end
                                    end
                                end
                            end
                        end
                        result = true
                    end
                    #
                    result
                end
                #
                def build(content_manifest=nil, options={})
                    self.build_components(self, content_manifest, options)
                end
                # ### Page Building
                def build_page(page_definition=nil)
                    # ### Example page_definition :
                    # page_format = {
                    #     :component => "page",
                    #     :requirements => [],
                    #     :auto_start => [],
                    #     :settings => {:page_title => "Untitled Page", :theme => "default", :accesskey => "", :contenteditable => false, :dir => "ltr", :draggable => false, :dropzone => "", :lang => "en", :spellcheck => false, :translate => "no"},
                    #     :options => {:style => {}, :states => ["page"], :tabindex => 0},
                    #     :script => "",
                    #     :content => []
                    # }
                    #
                    if page_definition.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
                        # ### Universal component attributes:
                        @element = `document.body`
                        @settings = page_definition[:settings]
                        @theme_prefix = (::GxG::CONNECTION.relative_url() + "/themes/#{(@settings[:theme] || 'default')}")
                        @uuid = page_definition.uuid.to_s.to_sym
                        `#{@element}.id = #{@uuid.to_s}`
                        @title = @settings[:page_title].to_s
                        `document.title = #{@title.to_s}`
                        @component = :"org.gxg.gui.page"
                        @parent = self
                        @children = {}
                        @domtype = :body
                        # ### CSS states
                        @states = {:"org-gxg-gui-page" => true}
                        if page_definition[:options].is_any?(::Hash, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
                            if page_definition[:options][:states].is_any?(::Array, ::GxG::Database::PersistedArray, ::GxG::Database::DetachedArray)
                                page_definition[:options][:states].each do |the_state|
                                    @states[(the_state.to_s.to_sym)] = true
                                end
                            end
                        end
                        # ### Style
                        @style = {}
                        if page_definition[:options].is_any?(::Hash, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
                            if page_definition[:options][:style].is_any?(::Hash, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
                                @style = page_definition[:options][:style]
                            end
                        end
                        # ### Other Attributes
                        @options = {}
                        if page_definition[:options].is_any?(::Hash, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedHash)
                            page_definition[:options].each_pair do |the_option, the_value|
                                unless [:"background-color", :data, :icon, :label, :content, :uuid, :title, :opacity, :window_title, :menu, :top, :right, :bottom, :left, :height, :width, :close, :minimize, :maximize, :resize, :scroll, :modal, :track, :states, :style].include?(the_option.to_s.to_sym)
                                    @options[(the_option.to_s.to_sym)] = the_value.to_s
                                end
                            end
                        end
                        # ### Event Stuff
                        @event_handlers = {}
                        @event_listeners = {}
                        # ### Commit Base Page Build
                        creation
                        # ### Set Script if any
                        if page_definition[:script].is_a?(::String)
                            if page_definition[:script].size > 0
                                self.set_script(page_definition[:script])
                            end
                        end
                        # ### Commit Component Builds
                        self.build_components(self, page_definition[:content])
                        #
                    end
                end
                # Create the document and start the creation process (casading).
                def initialize(page_definition=nil)
                    ::GxG::DISPLAY_DETAILS[:object] = self
                    ::GxG::DISPLAY_DETAILS[:object].on :onbeforeunload do |event|
                        ::GxG::DISPLAY_DETAILS[:socket].close
                        # ::GxG::CONNECTION.close
                    end
                    ::GxG::DISPLAY_DETAILS[:object].on :beforeunload do |event|
                        ::GxG::DISPLAY_DETAILS[:socket].close
                        # ::GxG::CONNECTION.close
                    end
                    ::GxG::DISPLAY_DETAILS[:object].on :onunload do |event|
                        ::GxG::DISPLAY_DETAILS[:socket].close
                        # ::GxG::CONNECTION.close
                    end
                    @theme_prefix = (::GxG::CONNECTION.relative_url() + "/themes/#{::GxG::DISPLAY_DETAILS[:theme]}")
                    @settings = nil
                    @busy = false
                    @window_switcher = nil
                    @window_registry = {}
                    @dialog = nil
                    @dialog_queue = []
                    @title_registry = {}
                    self.build_page(page_definition)
                    # Page-specific attributes:
                    # Review : go over object formats again and then lay out additional instance vars.
                    #
                    self
                end
                # ### Object Registration and Search
                def find_object_by_dom_id(the_id=nil)
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
                def find_object_by(the_title=nil)
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
                        the_object = self.find_object_by(the_title)
                        if the_object
                            if the_object.is_a?(::GxG::Gui::ApplicationViewport)
                                the_object.detach()
                            end
                            @title_registry.delete(the_object.uuid)
                        end
                        true
                    else
                        false
                    end
                end
                # Returns the one and only instance of the factory.
                def factory
                    @factory ||= GxG::Gui::Vdom::Factory.new(self)
                end
                # Returns the DOM element.
                def element()
                    factory.body
                end
                def parent()
                    self
                end
                # The document class is the root element.
                def root()
                    self
                end
                #
                # ### Display Helpers
                def domclear()
                    %x{
                        while (document.body.firstChild) {
                            document.body.removeChild(document.body.firstChild);
                        };
                    }
                    true
                end
                #
                def clear()
                    self.all_descendants do |the_child|
                        the_child.remove_listeners()
                    end
                    self.remove_listeners()
                    self.each_child do |the_child|
                        the_child.destroy()
                    end
                    the_attributes = `document.body.getAttributeNames()`
                    the_attributes.each do |the_attribute|
                        self.clear_attribute(the_attribute)
                    end
                    true
                end
                #
            end
            # End Page
            def self.load_page(page_object=nil)
                if ::GxG::DISPLAY_DETAILS[:object].is_any?(::GxG::Gui::Page, ::GxG::Gui::Vdom::Page)
                    ::GxG::DISPLAY_DETAILS[:object].clear()
                    ::GxG::Gui::Vdom::clear_rules()
                    ::GxG::Gui::Vdom::refresh_css_cache()
                    #                    
                end
                # Load current theme CSS rules
                the_theme = (page_object[:settings][:theme] || "default")
                ::GxG::CONNECTION.pull_object("/Public/www/content/themes/#{the_theme}") do |response|
                    if response.is_a?(::Array)
                        #    puts "Response (Theme Load): #{response.inspect}"
                        # Resources
                        response[0][:resources].each do |resource_profile|
                            if resource_profile[:resource_type] == "font-face"
                                ::GxG::Gui::Vdom::load_font(resource_profile)
                            end
                        end
                        # Rules
                        # puts "set css rules"
                        response[0][:rules].each_pair do |rule_name, rule_properties|
                            ::GxG::Gui::Vdom::set_rule(rule_name, rule_properties)
                        end
                        # Build Page
                        # puts "build page"
                        if ::GxG::DISPLAY_DETAILS[:object].is_any?(::GxG::Gui::Page, ::GxG::Gui::Vdom::Page)
                            ::GxG::DISPLAY_DETAILS[:object].build_page(page_object)
                        else
                            ::GxG::DISPLAY_DETAILS[:object] = ::GxG::Gui::Page.new(page_object)
                        end
                        # self.layout_refresh
                        ::GxG::Gui::layout_refresh
                    else
                        log_error({:error => Exception.new("Invalid theme object as response.")})
                    end
                end
                # Load Libraries
                # puts "load libraries"
                if page_object[:requirements].is_any?(::Array, ::GxG::Database::DetachedArray, ::GxG::Database::PersistedArray)
                    if page_object[:requirements].size > 0
                        self.load_libraries(page_object[:requirements])
                    end
                end
                # Load Applications
                # puts "launch applications"
                if page_object[:auto_start].is_any?(::Array, ::GxG::Database::DetachedArray, ::GxG::Database::PersistedArray)
                    if page_object[:auto_start].size > 0
                        page_object[:auto_start].each do |the_requirement|
                            self.application_open({:name => the_requirement[:name], :restore => true})
                        end
                    end
                end
                #
                true
            end
            #
            def self.navigate_to(the_location="")
                # ### Fetch page content and set build options
                #
                if ::GxG::CONNECTION.relative_url().to_s.size > 0
                    request_path = the_location[(::GxG::CONNECTION.relative_url().size)..-1]
                else
                    request_path = the_location
                end
                if request_path == "/" || request_path == ""
                    request_path = "/index"
                end
                unless request_path[0] == "/"
                    request_path = ("/" + request_path)
                end
                ::GxG::DISPLAY_DETAILS[:host_path] = request_path
                if GxG::PAGES[(request_path)]
                    GxG::Gui::Vdom::load_page(GxG::PAGES[(request_path)])
                else
                    error_handler = Proc.new { |error|
                        log_error error.inspect
                    }
                    # Load Page Content
                    ::GxG::CONNECTION.pull_object("/Public/www/content/pages#{request_path}",error_handler) do |response|
                        puts "Response (Page Load): #{response.inspect}"
                        if response.is_any?(::Array)
                            GxG::PAGES[(request_path)] = response[0]
                            GxG::Gui::Vdom::load_page(GxG::PAGES[(request_path)])
                        else
                            log_error({:error => Exception.new("Invalid page object as response.")})
                        end
                        # self.layout_refresh
                        ::GxG::Gui::layout_refresh
                    end
                end
                #
            end
        end
    end
end