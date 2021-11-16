# page format: {:uuid=>"9f7b8942-82ee-4695-8a61-d95f15f5dba3", :type=>:structure, :ufs=>:"org.gxg.gui.page", :title=>"Page", :version=>0.0, :mime_types=>"", :content=>{:component_type=>"page", :publish_path=>"", :background_uuid=>"", :menubar_uuid=>"", :attributes=>{}, :classes=>"", :style=>{}, :browsing=>{:draggable=>{}, :droppable=>{}, :resizable=>{}, :selectable=>{}, :sortable=>{}, :tool_tip=>{}, :alt_text=>""}, :authoring=>{:draggable=>{}, :droppable=>{}, :resizable=>{}, :selectable=>{}, :sortable=>{}, :tool_tip=>{}, :alt_text=>""}, :options=>{}, :value=>nil, :script=>"", :sub_components=>[]}}
#
# component format: {:uuid=>:"c44d8b14-1a97-4c6f-b07a-6999ca310241", :type=>:structure, :ufs=>:"org.gxg.gui.component", :title=>"Gui Component", :version=>0.0, :mime_types=>[], :content=>{:component_type=>"unspecified", :attributes=>{}, :classes=>"", :style=>{}, :browsing=>{:draggable=>{}, :droppable=>{}, :resizable=>{}, :selectable=>{}, :sortable=>{}, :tool_tip=>{}, :alt_text=>""}, :authoring=>{:draggable=>{}, :droppable=>{}, :resizable=>{}, :selectable=>{}, :sortable=>{}, :tool_tip=>{}, :alt_text=>""}, :options=>{}, :value=>nil, :script=>"", :sub_components=>[]}}
#{
#  :component_type => "page",
#  :publish_path => "",
#  :background_uuid => "",
#  :menubar_uuid => "",
#  :attributes => {},
#  :classes => "",
#  :style => {},
#  :browsing => {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""},
#  :authoring => {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""},
#  :options => {},
#  :value => nil,
#  :script => "",
#  :sub_components => []
#}
module GxG
  DISPLAY_DETAILS = {:host_path => "", :use_ssl => false, :connection => nil, :object => nil, :mode => :browsing}
  module Css
    @@CssCache = []
    @@CssRuleProperties = {}
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
        GxG::Css::valid_properties()
      end
      #
      def [](the_key)
        result = nil
        csskey = @@CssRuleProperties[(the_key)]
        if csskey
          result = `#{@native_rule}.style[#{csskey}]`
        end
        result
      end
      #
      def []=(the_key, the_value)
        #
        csskey = @@CssRuleProperties[(the_key)]
        if csskey
          `#{@native_rule}.style[#{csskey}] = #{(the_value || "")}`
        else
          # ignore invalid keys
        end
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
    def  self.refresh_css_cache()
      sheets = `document.styleSheets.length`.to_i
      if sheets > 0
        new_cache = []
        (0..(sheets - 1)).each do |sheet_index|
          begin
            ruleset = `document.styleSheets[#{sheet_index}].cssRules`
          rescue Exception => the_error
            ruleset = `document.styleSheets[#{sheet_index}].rules`
          end
          if ruleset
            rules = (`#{ruleset}.length`.to_i)
            if rules > 0
              (0..(rules - 1)).each do |rule_index|
                begin
                  native_rule = `document.styleSheets[#{sheet_index}].cssRules[#{rule_index}]`
                rescue Exception => the_error
                  native_rule = `document.styleSheets[#{sheet_index}].rules[#{rule_index}]`
                end
                if native_rule
                  new_cache << GxG::Css::CSSRule.new(native_rule)
                  if @@CssRuleProperties.size == 0
                    `Object.keys(#{native_rule}.style)`.each do |the_property_label|
                      if the_property_label
                        if ["0", "1", "3", "4", "5", "6", "7", "8", "9"].include?(the_property_label[0])
                          the_key = the_property_label.to_sym
                        else
                          key_text = (the_property_label[0].capitalize + the_property_label[1..-1]).split_camelcase
                          if key_text.is_a?(String)
                            key_text = [(key_text)]
                          end
                          the_key = key_text.join("-").downcase.to_sym
                        end
                        unless @@CssRuleProperties.keys.include?(the_key)
                          @@CssRuleProperties[(the_key)] = the_property_label.to_s
                        end
                      end
                    end
                  end
                  #
                end
              end
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
      # overwrite or merge (options)
      # create if non-existent
      found = GxG::Css::find_rule(the_rule_selector)
      if found.size > 0
        found.each do |the_rule_entry|
          the_rule = the_rule_entry.values[0]
          if options[:overwrite] == true
            @@CssRuleProperties.keys.each do |clear_key|
              unless the_properties.keys.include?(clear_key)
                `#{the_rule.native_object()}.style[#{@@CssRuleProperties[(clear_key)]}] = ""`
              end
            end
          end
          the_properties.keys.each do |the_key|
            csskey = @@CssRuleProperties[(the_key)]
            if csskey
              `#{the_rule.native_object()}.style[#{csskey}] = #{the_properties[(the_key)]}`
            else
              # ignore invalid keys
            end
          end
        end
      else
        # create it
        rule_body = {}
        the_properties.keys.each do |property_key|
          csskey = @@CssRuleProperties[(property_key)]
          if csskey
            rule_body[(csskey)] = the_properties[(property_key)]
          end
        end
        sheet_index = (`document.styleSheets.length`.to_i - 1)
        rules = `document.styleSheets[#{sheet_index}].cssRules`
        until rules do
          sheet_index -= 1
          if sheet_index < 0
            rules = nil
            break
          end
          rules = `document.styleSheets[#{sheet_index}].cssRules`
        end
        if rules
          #
          rule_index = (`#{rules}.length`.to_i - 1)
          response_code = `document.styleSheets[#{sheet_index}].addRule(#{the_rule_selector},"",#{rule_index})`.to_i
          if response_code == -1
            begin
              native_rule = `document.styleSheets[#{sheet_index}].cssRules[#{rule_index}]`
            rescue Exception => the_error
              native_rule = `document.styleSheets[#{sheet_index}].rules[#{rule_index}]`
            end
            the_properties.keys.each do |property_key|
              csskey = @@CssRuleProperties[(property_key)]
              if csskey
                `#{native_rule}.style[#{csskey}] = #{the_properties[(property_key)]}`
              end
            end
            @@CssCache << GxG::Css::CSSRule.new(native_rule)
          end
        end
      end
      true
    end
    #
    def self.remove_rule(the_rule_selector=nil)
      found_indexes = []
      @@CssCache.each_with_index do |entry, index|
        if entry.name == the_rule_selector.to_s.to_sym
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
          the_sheet = `#{native_rule}.parentStyleSheet`
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
  module Graphics
    class WebGL
      #
    end
    #
    class Svg
      #
    end
    #
    class Canvas
      #
    end
  end
  #
  module Gui
    #
    class Display
      # There is typically only one of these instantiated.
      # url('data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
      def self.valid_properties()
        GxG::Css::valid_properties()
      end
      #
      def initialize(settings={})
        if GxG::DISPLAY_DETAILS[:object].is_a?(GxG::Gui::Display)
          raise Exception, "Display has already been constructed."
        else
          @uuid = (settings[:uuid] || GxG::uuid_generate)
          @remote_uuid = nil
          @channel = nil
          @update_queue = []
          @document = ::Document
          @dom_object = ::Element.find('body')
          #
          @attributes = {}
          @classes = ""
          @style = {}
          @browsing = {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""}
          @authoring = {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""}
          @options = {}
          @value = nil
          #
          @update_timer = post_event_periodic(0.333) do
            self.transmit_update()
          end
          GxG::DISPLAY_DETAILS[:object] = self
          GxG::register(self)
          GxG::Css::refresh_css_cache()
        end
        self
      end
      #
      def uuid()
        @uuid
      end
      #
      def set_remote_uuid(the_uuid=nil)
        if the_uuid
          @remote_uuid = the_uuid
        end
      end
      #
      def dom_object()
        @dom_object
      end
      #
      def establish_dom_link()
        # No-op : already establish
      end
      #
      def channel()
        @channel
      end
      #
      def set_channel(the_channel=nil)
        @channel = the_channel
      end
      #
      def export_display(local_export=false)
        # Export entire key-frame of display state data.
        # build up export db pairs:
        export_db = []
        link_db = [(self)]
        while link_db.size > 0 do
          entry = link_db.shift
          parent = GxG::parent_of(entry)
          if parent
            new_record = {:uuid => entry.uuid.to_s, :parent_uuid => parent.uuid.to_s, :type => nil, :attributes => {}, :classes => "", :style => {}, :browsing => {}, :authoring => {}, :options => {}, :value => nil, :content => []}
            new_record[:type] = GxG::Gui::GuiComponent::class_to_key(entry.class).to_s
          else
            if local_export == true
              new_record = {:uuid => @uuid.to_s, :parent_uuid => nil, :type => "display", :attributes => {}, :classes => "", :style => {}, :browsing => {}, :authoring => {}, :options => {}, :value => nil, :content => []}
            else
              new_record = {:uuid => @remote_uuid.to_s, :parent_uuid => nil, :type => "display", :attributes => {}, :classes => "", :style => {}, :browsing => {}, :authoring => {}, :options => {}, :value => nil, :content => []}
            end
          end
          new_record[:attributes] = entry.get_attributes()
          new_record[:classes] = entry.get_classes()
          new_record[:style] = entry.get_style()
          new_record[:browsing] = entry.get_features()
          new_record[:authoring] = entry.get_authoring_features()
          new_record[:options] = entry.get_options()
          new_record[:value] = entry.get_value()
          export_db << {:object => entry, :record => new_record}
          GxG::children_of(entry).each do |the_child|
            link_db << the_child
          end
        end
        object_record = Proc.new do |the_object|
          found = nil
          export_db.each do |export_record|
            if the_object.object_id == export_record[:object].object_id
              found = export_record
              break
            end
          end
          found
        end
        # Assemble export contents of records
        link_db = [(self)]
        while link_db.size > 0 do
          # {:uuid => "<the-uuid>", :parent_uuid => "<the-uuid>", :type => "<the-type-specifier>", :classes => "", :style => {}, :features => {}, :value => nil, :content => []}
          entry = link_db.shift
          the_record = object_record.call(entry)
          if the_record
            GxG::children_of(entry).each do |the_child|
              child_record = object_record.call(the_child)
              the_record[:record][:content] << child_record[:record]
              link_db << the_child
            end
          end
          #
        end
        (export_db[0] || {})[:record]
      end
      #
      def import_display(import_records={})
        result = false
        if import_records.size > 0
          old_list = GxG::register_uuid_list()
          retain_list = [(@uuid.to_sym)]
          import_db = []
          link_db = [(import_records)]
          while link_db.size > 0 do
            entry = link_db.shift
            # do a format check on the record?
            if (entry[:uuid] && entry[:type] && entry[:attributes] && entry[:classes] && entry[:style]  && entry[:browsing] && entry[:authoring] && entry[:options] && entry[:content])
              entry[:object] = GxG::object_by_uuid(entry[:uuid].to_sym)
              unless entry[:object]
                # create object
                parent = nil
                if entry[:parent_uuid]
                  parent = GxG::object_by_uuid(entry[:parent_uuid].to_sym)
                end
                the_class = GxG::Gui::GuiComponent::key_to_class(entry[:type].to_sym)
                unless the_class == GxG::Gui::Display
                  entry[:object] = the_class.new({:uuid => entry[:uuid].to_sym, :parent => (parent || self)})
                end
              end
              if entry[:object]
                retain_list << entry[:object].uuid.to_sym
              end
              import_db << entry
              entry[:content].each do |the_record|
                link_db << the_record
              end
            else
              raise ArgumentError, "Malformed import record."
            end
          end
          # Set object internal data.
          while import_db.size > 0 do
            entry = import_db.shift
            if entry
              entry[:object].set_attributes(entry[:attributes])
              entry[:object].set_classes(entry[:classes])
              entry[:object].set_style(entry[:style])
              entry[:object].set_features(entry[:browsing])
              entry[:object].set_authoring_features(entry[:authoring])
              entry[:object].set_options(entry[:options])
              entry[:object].set_value(entry[:value])
            end
          end
          # Render new state information to the DOM.
          post_event(:display) do
            self.render_dom
          end
          # Eliminate objects NOT included in this key-frame importation.
          old_list.each do |the_key|
            unless retain_list.include?(the_key)
              # unregister the_key object_by_uuid
              old_object = GxG::object_by_uuid(the_key)
              unless old_object.is_a?(::GxG::Gui::Display)
                if GxG::unregister(the_key) && old_object
                  # de-activate object
                  old_object.deactivate()
                end
              end
            end
          end
          result = true
        end
        result
      end
      # Server synchronization methods:
      def transmit_keyframe()
        keyframe = self.export_display()
        if keyframe.is_a?(::Hash)
          gxg_message = new_message
          gxg_message[:sender] = @uuid
          gxg_message[:to] = @remote_uuid
          gxg_message[:body] = {:method => "import_display", :parameters => keyframe}
          @channel.remote_call(gxg_message)
        end
      end
      #
      def transmit_update()
        if @update_queue.size > 0
          gxg_message = new_message
          gxg_message[:sender] = @uuid
          gxg_message[:to] = @remote_uuid
          gxg_message[:body] = {:method => "receive_update", :parameters => {:operation => "update", :records => @update_queue}}
          @channel.remote_call(gxg_message)
          @update_queue = []
        end
      end
      #
      def transmit_event(the_event_frame=nil)
        if the_event_frame.is_any?(::Hash, ::Array)
          gxg_message = new_message
          gxg_message[:sender] = @uuid
          gxg_message[:to] = @remote_uuid
          gxg_message[:body] = {:method => "receive_update", :parameters => {:operation => "pass_event", :events => the_event_frame}}
          @channel.remote_call(gxg_message)
        end
      end
      #
      def receive_update(operation_frame={})
        if operation_frame.is_a?(::Hash)
          case operation_frame[:operation]
          when "update"
            if operation_frame[:records].is_a?(::Array)
              operation_frame[:records].each do |the_delta|
                dom_sync = true
                the_object = GxG::object_by_uuid(the_delta[:uuid].to_sym)
                if the_object
                  if the_delta[:attributes].is_a?(::Hash)
                    the_object.set_attributes(the_delta[:attributes])
                  end
                  if the_delta[:classes]
                    the_object.set_classes(the_delta[:classes])
                  end
                  if the_delta[:style].is_a?(::Hash)
                    the_object.set_style(the_delta[:style])
                  end
                  if the_delta[:browsing].is_a?(::Hash)
                    the_object.set_features(the_delta[:browsing])
                  end
                  if the_delta[:authoring].is_a?(::Hash)
                    the_object.set_authoring_features(the_delta[:authoring])
                  end
                  if the_delta[:options].is_a?(::Hash)
                    # Options only come FROM the server (One-Way)
                    if the_delta[:options][:visibility]
                      dom_sync = false
                      case the_delta[:options][:visibility]
                      when "show"
                        the_object.show()
                      when "hide"
                        the_object.hide()
                      when "toggle"
                        the_object.toggle_visibility()
                      end
                    else
                      the_object.set_options(the_delta[:options])
                    end
                  end
                  if the_delta[:value]
                    the_object.set_value(the_delta[:value])
                  end
                  if dom_sync == true
                    the_object.sync_to_dom()
                  end
                else
                  puts "No Object for #{the_delta[:uuid]}"
                end
              end
            end
          when "remove"
            if operation_frame[:operation][:manifest].is_a?(::Array)
              operation_frame[:operation][:manifest].each do |the_uuid|
                the_object = GxG::object_by_uuid(the_uuid.to_sym)
                if the_object
                  the_object.deactivate()
                  GxG::unregister(the_uuid.to_sym)
                end
              end
            end
          end
        end
      end
      #
      def post_update(the_delta=nil)
        if the_delta.is_a?(::Hash)
          @update_queue << the_delta
        end
      end
      #
      def process_event(the_frame=nil)
        if the_frame.is_a?(::Hash)
          record = {:type => the_frame[:event].type.to_s, :details => {}}
          # ???
          # puts "#{the_frame[:event].public_methods.sort.inspect}"
          # common details
          record[:details][:page_x] = the_frame[:event].page_x
          record[:details][:page_y] = the_frame[:event].page_y
          record[:details][:which] = the_frame[:event].which
          record[:details][:meta_key] = the_frame[:event].meta_key
          record[:details][:alt_key] = the_frame[:event].alt_key
          record[:details][:shift_key] = the_frame[:event].shift_key
          record[:details][:control_key] = the_frame[:event].ctrl_key
          if the_frame[:data]
            record[:details][:data] = the_frame[:data]
          else
            record[:details][:data] = nil
          end
          # type-specific details
          the_frame[:event] = record
          #
          self.transmit_event(the_frame)
        end
      end
      # State setting methods:
      def get_attributes()
        @attributes
      end
      #
      def set_attributes(data={})
        @attributes = data
      end
      #
      def get_style()
        @style
      end
      #
      def set_style(style_data={})
        @style = style_data
      end
      #
      def get_value()
        @value
      end
      #
      def set_value(data=nil)
        @value = data
      end
      #
      def get_classes()
        @classes
      end
      #
      def set_classes(data="")
        @classes = data
      end
      #
      def get_features()
        @browsing
      end
      #
      def set_features(data={})
        @browsing = data
      end
      #
      def get_authoring_features()
        @authoring
      end
      #
      def set_authoring_features(data={})
        @authoring = data
      end
      #
      def get_options()
        @options
      end
      #
      def set_options(data={})
        @options = data
      end
      #
      def generate_html()
        accumulator = []
        contents = GxG::children_of(self)
        contents.each do |the_object|
          accumulator << the_object.generate_html()
        end
        accumulator.join("\n")
      end
      #
      def render_dom(settings={})
        # FIX: Make non-recursive, iterative.
        # Generate a complete replacement for the current DOM content.
        # Assume NO dom_objects are internally available to the child objects.
        # Call generate_html on each child
        new_dom_html = self.generate_html()
        ::Element.find('body').append(::Element::parse(new_dom_html))
        # call establish_dom_link on each object after DOM commit. 
        link_db = [(self)]
        while link_db.size > 0 do
          entry = link_db.shift
          GxG::children_of(entry).each do |the_object|
            the_object.activate()
            link_db << the_object
          end
        end
        #
      end
      #
      def refresh_dom()
        link_db = [(self)]
        while link_db.size > 0 do
          entry = link_db.shift
          GxG::children_of(entry).each do |the_object|
            the_object.sync_to_dom()
            link_db << the_object
          end
        end
        #
      end
      #
      def switch_to_mode(the_mode=:browsing)
        if the_mode.is_a?(String)
          the_mode = the_mode.to_sym
        end
        if GxG::DISPLAY_DETAILS[:mode] == :authoring
          if the_mode == :browsing
            # switch back to browsing mode
            GxG::DISPLAY_DETAILS[:mode] = :browsing
            link_db = [(self)]
            while link_db.size > 0 do
              entry = link_db.shift
              GxG::children_of(entry).each do |the_object|
                the_object.sync_from_dom()
                the_object.activate()
                link_db << the_object
              end
            end
            # TODO: update server gui-mode as well
          end
        else
          if the_mode == :authoring
            # switch to authoring mode
            GxG::DISPLAY_DETAILS[:mode] = :authoring
            link_db = [(self)]
            while link_db.size > 0 do
              entry = link_db.shift
              GxG::children_of(entry).each do |the_object|
                the_object.sync_from_dom()
                the_object.activate()
                link_db << the_object
              end
            end
            # TODO: update server gui-mode as well
          end
        end
      end
      #
      def activate()
        # No-op for display object
      end
      #
      def deactivate(settings={})
        # No-op for display object
      end
    end
    #
    class GuiComponent
      # Abstract Class - only instantiate sub-classes.
      def self.class_mapping()
        {
          :display => GxG::Gui::Display,
          :background => GxG::Gui::Background,
          :page => GxG::Gui::Page,
          :window => GxG::Gui::Window,
          :menubar => GxG::Gui::MenuBar,
          :accordion => GxG::Gui::Accordion,
          :accordion_section => GxG::Gui::AccordionSection,
          :accordion_section_label => GxG::Gui::AccordionSectionLabel,
          :accordion_section_content => GxG::Gui::AccordionSectionContent,
          :anchor => GxG::Gui::Anchor,
          :button => GxG::Gui::Button,
          :division => GxG::Gui::Division,
          :input_label => GxG::Gui::InputLabel,
          :paragraph => GxG::Gui::Paragraph,
          :text_lable => GxG::Gui::TextLabel,
          :legend => GxG::Gui::Legend,
          :list_item => GxG::Gui::ListItem,
          :ordered_list => GxG::Gui::OrderedList,
          :unordered_list => GxG::Gui::UnorderedList,
          :control_group => GxG::Gui::ControlGroup,
          :field_set => GxG::Gui::FieldSet,
          :text_input => GxG::Gui::TextInput,
          :date_picker => GxG::Gui::DatePicker,
          :menu => GxG::Gui::Menu,
          :select_menu => GxG::Gui::SelectMenu,
          :select_menu_option => GxG::Gui::SelectMenuOption,
          :slider => GxG::Gui::Slider,
          :spinner => GxG::Gui::Spinner,
          :progress_bar => GxG::Gui::ProgressBar,
          :tabs => GxG::Gui::Tabs,
          :tab_section => GxG::Gui::TabSection,
          :table => GxG::Gui::Table,
          :table_row => GxG::Gui::TableRow,
          :table_header => GxG::Gui::TableHeader,
          :table_data => GxG::Gui::TableData,
          :image => GxG::Gui::Image
        }
      end
      #
      def self.key_to_class(the_key)
        GxG::Gui::GuiComponent::class_mapping()[(the_key)]
      end
      #
      def self.class_to_key(the_class)
        result = nil
        mapping = GxG::Gui::GuiComponent::class_mapping()
        mapping.keys.each do |the_key|
          if mapping[(the_key)] == the_class
            result = the_key
            break
          end
        end
        result
      end
      #
      def initialize(settings={})
        @uuid = (settings[:uuid] || GxG::uuid_generate)
        @parent = settings[:parent]
        # Class, Style, and Features are for cached for browse-mode only.
        @base_tag = "div"
        @attributes = {}
        @classes = ""
        @style = {}
        @browsing = {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""}
        @authoring = {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""}
        @options = {}
        @value = nil
        @dom_object = nil
        @visible = true
        GxG::register(self,@parent)
      end
      #
      def uuid()
        @uuid
      end
      #
      def dom_object()
        @dom_object
      end
      #
      def visible?()
        @visible
      end
      #
      def hide()
        if @dom_object
          @dom_object.hide()
          @visible = false
        end
      end
      #
      def show()
        if @dom_object
          @dom_object.show()
          @visible = true
        end
      end
      #
      def toggle_visibility()
        if @dom_object
          if @visible == true
            self.hide()
          else
            self.show()
          end
        end
      end
      #
      def establish_dom_link()
        #
        @dom_object = Element.find("##{@uuid.to_s}")
        if @dom_object
          # Set event traps on @dom_object
          # ???
          @dom_object.on :dblclick do |event|
            GxG::DISPLAY_DETAILS[:object].process_event({:uuid => @uuid, :event => event})
          end
          @dom_object.on :mouseup do |event|
            GxG::DISPLAY_DETAILS[:object].process_event({:uuid => @uuid, :event => event})
          end
          @dom_object.on :mousedown do |event|
            GxG::DISPLAY_DETAILS[:object].process_event({:uuid => @uuid, :event => event})
          end
          #          @dom_object.on :mouseenter do |event|
          #            GxG::DISPLAY_DETAILS[:object].process_event({:uuid => @uuid, :event => event})
          #          end
          #          @dom_object.on :mouseleave do |event|
          #            GxG::DISPLAY_DETAILS[:object].process_event({:uuid => @uuid, :event => event})
          #          end
        end
        true
      end
      #
      def get_dom_features()
        valid_draggable_options = {:add_classes => "addClasses", :append_to => "appendTo", :axis => "axis", :cancel => "cancel", :classes => "classes", :connect_to_sortable => "connectToSortable", :containment => "containment", :cursor => "cursor", :cursor_at => "cursorAt", :delay => "delay", :disabled => "disabled", :distance => "distance", :grid => "grid", :handle => "handle", :helper => "helper", :iframe_fix => "iframeFix", :opacity => "opacity", :refresh_positions => "refreshPositions", :revert => "revert", :revert_duration => "revertDuration", :scope => "scope", :scroll => "scroll", :scroll_sensitivity => "scrollSensitivity", :scroll_speed => "scrollSpeed", :snap => "snap", :snap_mode => "snapMode", :snap_tolerance => "snapTolerance", :stack => "stack", :z_index => "z-index"}
        valid_droppable_options = {:accept => "accept", :active_class => "activeClass", :add_classes => "addClasses", :classes => "classes", :disabled => "disabled", :greedy => "greedy", :hover_class => "hoverClass", :scope => "scope", :tolerance => "tolerance"}
        valid_resizable_options = {:also_resize => "alsoResize", :animate => "animate", :animate_duration => "animateDuration", :animate_easing => "animateEasing", :aspect_ration => "aspectRatio", :auto_hide => "autoHide", :cancel => "cancel", :classes => "classes", :containment => "containment", :delay => "delay", :disabled => "disabled", :distance => "distance", :ghost => "ghost", :grid => "grid", :handles => "handles", :helper => "helper", :max_height => "maxHeight", :max_width => "maxWidth"}
        valid_selectable_options = {:append_to => "appendTo", :auto_refresh => "autoRefresh", :cancel => "cancel", :classes => "classes", :delay => "delay", :disabled => "disabled", :distance => "distance", :filter => "filter", :tolerance => "tolerance"}
        valid_sortable_options = {:append_to => "appendTo", :axis => "axis", :cancel => "cancel", :classes => "classes", :connect_with => "connectWith", :cursor => "cursor", :cursor_at => "cursorAt", :delay => "delay", :disabled => "disabled", :distance => "distance", :drop_on_empty => "dropOnEmpty", :grid => "grid", :handle => "handle", :helper => "helper", :items => "items", :opacity => "opacity", :placeholder => "placeholder", :revert => "revert", :scroll => "scroll", :scroll_sensitivity => "scrollSensitivity", :scroll_speed => "scrollSpeed", :tolerance => "tolerance", :z_index => "z-index"}
        # TODO: include tool_tip in process.
        the_features = {:draggable => {}, :droppable => {}, :resizable => {}, :selectable => {}, :sortable => {}, :tool_tip => {}, :alt_text => ""}
        if @dom_object
          begin
            valid_draggable_options.keys.each do |the_option_key|
              unless [].include?(the_option_key)
                the_features[:draggable][(the_option_key)] = @dom_object.draggable("option",(valid_draggable_options[(the_option_key)]))
              end
            end
          rescue Exception => the_error
          end
          #
          begin
            valid_droppable_options.keys.each do |the_option_key|
              unless [].include?(the_option_key)
                the_features[:droppable][(the_option_key)] = @dom_object.droppable("option",(valid_droppable_options[(the_option_key)]))
              end
            end
          rescue Exception => the_error
          end
          #
          begin
            valid_resizable_options.keys.each do |the_option_key|
              unless [].include?(the_option_key)
                the_features[:resizable][(the_option_key)] = @dom_object.resizable("option",(valid_resizable_options[(the_option_key)]))
              end
            end
          rescue Exception => the_error
          end
          #
          begin
            valid_selectable_options.keys.each do |the_option_key|
              unless [].include?(the_option_key)
                the_features[:selectable][(the_option_key)] = @dom_object.selectable("option",(valid_selectable_options[(the_option_key)]))
              end
            end
          rescue Exception => the_error
          end
          #
          begin
            valid_sortable_options.keys.each do |the_option_key|
              unless [].include?(the_option_key)
                the_features[:sortable][(the_option_key)] = @dom_object.sortable("option",(valid_sortable_options[(the_option_key)]))
              end
            end
          rescue Exception => the_error
          end
          #
        end
        #
        the_features
      end
      #
      def set_dom_features(the_features=nil)
        valid_draggable_options = {:add_classes => "addClasses", :append_to => "appendTo", :axis => "axis", :cancel => "cancel", :classes => "classes", :connect_to_sortable => "connectToSortable", :containment => "containment", :cursor => "cursor", :cursor_at => "cursorAt", :delay => "delay", :disabled => "disabled", :distance => "distance", :grid => "grid", :handle => "handle", :helper => "helper", :iframe_fix => "iframeFix", :opacity => "opacity", :refresh_positions => "refreshPositions", :revert => "revert", :revert_duration => "revertDuration", :scope => "scope", :scroll => "scroll", :scroll_sensitivity => "scrollSensitivity", :scroll_speed => "scrollSpeed", :snap => "snap", :snap_mode => "snapMode", :snap_tolerance => "snapTolerance", :stack => "stack", :z_index => "z-index"}
        valid_droppable_options = {:accept => "accept", :active_class => "activeClass", :add_classes => "addClasses", :classes => "classes", :disabled => "disabled", :greedy => "greedy", :hover_class => "hoverClass", :scope => "scope", :tolerance => "tolerance"}
        valid_resizable_options = {:also_resize => "alsoResize", :animate => "animate", :animate_duration => "animateDuration", :animate_easing => "animateEasing", :aspect_ration => "aspectRatio", :auto_hide => "autoHide", :cancel => "cancel", :classes => "classes", :containment => "containment", :delay => "delay", :disabled => "disabled", :distance => "distance", :ghost => "ghost", :grid => "grid", :handles => "handles", :helper => "helper", :max_height => "maxHeight", :max_width => "maxWidth"}
        valid_selectable_options = {:append_to => "appendTo", :auto_refresh => "autoRefresh", :cancel => "cancel", :classes => "classes", :delay => "delay", :disabled => "disabled", :distance => "distance", :filter => "filter", :tolerance => "tolerance"}
        valid_sortable_options = {:append_to => "appendTo", :axis => "axis", :cancel => "cancel", :classes => "classes", :connect_with => "connectWith", :cursor => "cursor", :cursor_at => "cursorAt", :delay => "delay", :disabled => "disabled", :distance => "distance", :drop_on_empty => "dropOnEmpty", :grid => "grid", :handle => "handle", :helper => "helper", :items => "items", :opacity => "opacity", :placeholder => "placeholder", :revert => "revert", :scroll => "scroll", :scroll_sensitivity => "scrollSensitivity", :scroll_speed => "scrollSpeed", :tolerance => "tolerance", :z_index => "z-index"}
        #
        unless the_features.is_a?(::Hash)
          the_features = @browsing
        end
        if @dom_object
          if the_features[:draggable][:enable] == true
            @dom_object.draggable()
            the_features[:draggable].keys.each do |the_option_key|
              if valid_draggable_options.keys.include?(the_option_key) && the_option_key != :enable
                @dom_object.draggable("option",(valid_draggable_options[(the_option_key)]),(the_features[:draggable][(the_option_key)]))
              end
            end
          else
            # @dom_object.draggable('disable')
          end
          if the_features[:droppable][:enable] == true
            @dom_object.droppable()
            the_features[:droppable].keys.each do |the_option_key|
              if valid_droppable_options.keys.include?(the_option_key) && the_option_key != :enable
                @dom_object.droppable("option",(valid_droppable_options[(the_option_key)]),(the_features[:droppable][(the_option_key)]))
              end
            end
          else
            # @dom_object.droppable('disable')
          end
          if the_features[:resizable][:enable] == true
            @dom_object.resizable()
            the_features[:resizable].keys.each do |the_option_key|
              if valid_resizable_options.keys.include?(the_option_key) && the_option_key != :enable
                @dom_object.resizable("option",(valid_resizable_options[(the_option_key)]),(the_features[:resizable][(the_option_key)]))
              end
            end
          else
            # @dom_object.resizable('disable')
          end
          if the_features[:selectable][:enable] == true
            @dom_object.selectable()
            the_features[:selectable].keys.each do |the_option_key|
              if valid_selectable_options.keys.include?(the_option_key) && the_option_key != :enable
                @dom_object.selectable("option",(valid_selectable_options[(the_option_key)]),(the_features[:selectable][(the_option_key)]))
              end
            end
          else
            # @dom_object.selectable('disable')
          end
          if the_features[:sortable][:enable] == true
            @dom_object.sortable()
            the_features[:sortable].keys.each do |the_option_key|
              if valid_sortable_options.keys.include?(the_option_key) && the_option_key != :enable
                @dom_object.sortable("option",(valid_sortable_options[(the_option_key)]),(the_features[:sortable][(the_option_key)]))
              end
            end
          else
            # @dom_object.sortable('disable')
          end
        end
        #
        true
      end
      #
      def activate()
        unless @dom_object
          self.establish_dom_link
        end
        if @dom_object
          #
          unless self.is_any?(GxG::Gui::Background, GxG::Gui::Page, GxG::Gui::Window)
            # unless in :authoring mode:
            if GxG::DISPLAY_DETAILS[:mode] == :authoring
              self.set_dom_features(@authoring)
            else
              self.set_dom_features(@browsing)
            end
            # TODO: figure out how to incorporate @browsing[:tool_tip]
          end
          #
        end
        #
      end
      #
      def deactivate(settings={})
        if @dom_object
          begin
            @dom_object.remove
          rescue Exception
          end
          @dom_object = nil
        end
      end
      #
      def components()
        GxG::children_of(self)
      end
      #
      def add_component(the_type=nil, settings={})
        result = nil
        if the_type.is_any?(::String, ::Symbol)
          # [:display, :background, :page, :window, :menubar, :accordion, :accordion_section, :accordion_section_label, :accordion_section_content, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :list_item, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :select_menu_option, :slider, :spinner, :progress_bar, :tabs, :tab_section]
          viable = []
          case GxG::Gui::GuiComponent::class_to_key(self.class)
          when :background
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :page
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :menubar
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :window
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :accordion
            viable = [:accordion_section]
          when :accordion_section
            viable = [:accordion_section_label, :accordion_section_content]
          when :accordion_section_label
            viable = []
          when :accordion_section_content
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :anchor
            viable = []
          when :button
            viable = []
          when :division
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :input_label
            viable = []
          when :paragraph
            viable = []
          when :text_label
            viable = []
          when :legend
            viable = []
          when :list_item
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :ordered_list
            viable = [:list_item]
          when :unordered_list
            viable = [:list_item]
          when :control_group
            viable = [:anchor, :button, :input_label, :text_lable, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar]
          when :field_set
            viable = [:anchor, :button, :input_label, :text_lable, :text_input, :legend, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar]
          when :text_input
            viable = []
          when :date_picker
            viable = []
          when :menu
            viable = []
          when :select_menu
            viable = [:select_menu_option]
          when :select_menu_option
            viable = []
          when :slider
            viable = []
          when :spinner
            viable = []
          when :progress_bar
            viable = []
          when :tabs
            viable = [:tab_section]
          when :tab_section
            viable = [:accordion, :anchor, :button, :division, :input_label, :paragraph, :text_lable, :legend, :ordered_list, :unordered_list, :control_group, :field_set, :text_input, :date_picker, :menu, :select_menu, :slider, :spinner, :progress_bar, :tabs, :table, :image]
          when :table
            viable = [:table_row]
          when :table_row
            viable = [:table_header, :table_data]
          when :image
            viable = []
          end
          #
          if viable.include?(the_type.to_sym)
            the_class = GxG::Gui::GuiComponent::key_to_class(the_type.to_sym)
            if the_class
              result = the_class.new(settings.merge({:parent => self}))
            else
              # err
            end
          else
            # err
          end
          #
        end
        result
      end
      #
      def receive_an_update(the_delta=nil)
        if the_delta.is_a?(::Hash)
          # TODO: fine-grained updates
          if the_delta[:attributes].is_a?(::Hash)
            self.set_attributes(the_delta[:attributes])
          end
          if the_delta[:classes]
            self.set_classes(the_delta[:classes])
          end
          if the_delta[:style].is_a?(::Hash)
            self.set_style(the_delta[:style])
          end
          if the_delta[:browsing].is_a?(::Hash)
            self.set_features(the_delta[:browsing])
          end
          if the_delta[:authoring].is_a?(::Hash)
            self.set_authoring_features(the_delta[:authoring])
          end
          if the_delta[:options].is_a?(::Hash)
            self.set_options(the_delta[:options])
          end
          if the_delta[:value]
            self.set_value(the_delta[:value])
          end
          self.sync_to_dom()
          # ???
        end
      end
      #
      def get_attributes()
        @attributes
      end
      #
      def set_attributes(data={})
        @attributes = data
      end
      #
      def get_style()
        @style
      end
      #
      def set_style(style_data={})
        @style = style_data
      end
      #
      def get_value()
        @value
      end
      #
      def set_value(data=nil)
        @value = data
      end
      #
      def get_classes()
        @classes
      end
      #
      def set_classes(data=nil)
        @classes = data.to_s
      end
      #
      def get_features()
        @browsing
      end
      #
      def set_features(data={})
        @browsing = data
      end
      #
      def get_authoring_features()
        @authoring
      end
      #
      def set_authoring_features(data={})
        @authoring = data
      end
      #
      def get_options()
        @options
      end
      #
      def set_options(data={})
        # ???
        if data.is_a?(::Hash)
          data.keys.each do |op_key|
            if op_key == :visibility
              case op_key
              when "hide"
                self.hide()
              when "show"
                self.show()
              when "toggle"
                self.toggle_visibility()
              end
            else
              @options[(op_key.to_sym)] = data[(op_key)]
            end
          end
        end
        #
      end
      # Rendering to DOM
      def generate_html()
        # TODO: figure out where to incorporate @browsing[:alt_text] (string) into html tag output. (508 compliance)
        if @classes.size > 0
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}' class='#{@classes.to_s}'"
        else
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}'"
        end
        #
        if @attributes.size > 0
          @attributes.keys.each do |the_key|
            result = result + " #{the_key.to_s}='#{@attributes[(the_key)].to_s}'"
          end
        end
        #
        if @style.keys.size > 0
          style_string = " style='"
        else
          style_string = ""
        end
        @style.keys.each do |the_key|
          unless @style[(the_key)] == ""
            # ???
            # the_property = GxG::Css::get_property_name(the_key)
            the_property = (the_key.to_s.gsub("_","-"))
            if the_property
              style_string = style_string + " #{the_property.to_s}: #{@style[(the_key)].to_s};"
            end
          end
        end
        if style_string.size > 0
          result = (result + style_string + "'")
        end
        if ["button", "input", "li", "option", "progress", "param"].include?(@base_tag)
          # value is in the main tag def.
          if @attributes[:value]
            result = result + ">"
          else
            if @value
              result = (result + " value='" + @value.to_s + "'>")
            else
              result = result + ">"
            end
          end
        else
          # close the main tag def.
          result = result + ">"
        end
        accumulator = []
        contents = GxG::children_of(self)
        contents.each do |the_object|
          accumulator << the_object.generate_html()
        end
        if (@attributes[:value] || self.respond_to?(:set_dom_value))
          result = (result + accumulator.join("\n") + "</#{@base_tag.to_s}>")
        else
          if ["button", "input", "li", "option", "progress", "param"].include?(@base_tag)
            result = (result + accumulator.join("\n") + "</#{@base_tag.to_s}>")
          else
            # value is in-line text
            if @value
              result = (result + @value.to_s + accumulator.join("\n") + "</#{@base_tag.to_s}>")
            else
              result = (result + accumulator.join("\n") + "</#{@base_tag.to_s}>")
            end
          end
        end
        result
      end
      #
      def sync_to_dom()
        if @dom_object
          @dom_object.attr("class",@classes)
          @style.keys.each do |css_key|
            the_name = ::GxG::Css::get_property_name(css_key)
            if the_name
              @dom_object.css(the_name.to_s,@style[(css_key)])
            end
          end
          @attributes.keys.each do |attr_key|
            @dom_object.attr(attr_key.to_s,@attributes[(attr_key)])
          end
          unless @attributes[:value]
            unless @base_tag == "div"
              # @dom_object.innerHTML = @value.to_s
              @dom_object.html(@value.to_s).fadeIn(500)
            end
          end
          #
          if GxG::DISPLAY_DETAILS[:mode] == :authoring
            self.set_dom_features(self.get_authoring_features())
          else
            self.set_dom_features(self.get_features())
          end
          #
        end
        true
      end
      #
      def sync_from_dom()
        # Produces a state delta record to send to the server, as well as sets state to match dom.
        delta = nil
        if @dom_object
          delta = {}
          the_class = @dom_object.attr("class")
          if the_class != @classes
            @classes = the_class
            delta[:classes] = the_class
          end
          new_style = {}
          ::GxG::Css::valid_properties.each do |prop_key|
            the_name = ::GxG::Css::get_property_name(prop_key)
            if the_name && @style[(prop_key)]
              new_style[(prop_key)] = @dom_object.css(the_name.to_s)
            end
          end
          if new_style.size > 0
            if new_style != @style
              @style = new_style
              delta[:style] = new_style
            end
          end
          if @attributes.size > 0
            delta[:attributes] = {}
          end
          @attributes.keys.each do |attr_key|
            unless attr_key.to_s == "class" || attr_key.to_s == "style"
              the_attribute = @dom_object.attr(attr_key.to_s)
              if @attributes[(attr_key)] != the_attribute
                @attributes[(attr_key)] = the_attribute
                delta[:attributes][(attr_key)] = the_attribute
              end
            end
          end
          unless @attributes[:value]
            unless @base_tag == "div"
              the_value = @dom_object.innerHTML
              if @value != the_value
                @value = the_value
                delta[:value] = the_value
              end 
            end
          end
          #
          the_features = self.get_dom_features()
          if GxG::DISPLAY_DETAILS[:mode] == :authoring
            if @authoring != the_features
              @authoring = the_features
              delta[:authoring] = the_features
            end
          else
            if @browsing != the_features
              @browsing = the_features
              delta[:browsing] = the_features
            end
          end
          #
          if delta.size > 0
            delta[:uuid] = @uuid
          else
            delta = nil
          end
        end
        delta
      end
      #
    end
    #
    class Background < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "div"
        # z-index of 0 or 1
        self
      end
      #
    end
    #
    class Page < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "div"
        # z-index of 50
        self
      end
      #
    end
    #
    class Window < GuiComponent
      #
      #Window Options:
      # Extended Options:
      #closable
      #
      #Type: Boolean
      #
      #Usage: enable/disable close button
      #
      #Default: true
      #maximizable
      #
      #Type: Boolean
      #
      #Usage: enable/disable maximize button
      #
      #Default: false
      #minimizable
      #
      #Type: Boolean
      #
      #Usage: enable/disable minimize button
      #
      #Default: false
      #collapsable
      #
      #Type: Boolean
      #
      #Usage: enable/disable collapse button
      #
      #Default: false
      #minimizeLocation
      #
      #Type: String
      #
      #Usage: sets alignment of minimized dialogues
      #
      #Default: 'left'
      #
      #Valid: 'left', 'right'
      #dblclick
      #
      #Type: Boolean, String
      #
      #Usage: set action on double click
      #
      #Default: false
      #
      #Valid: false, 'maximize', 'minimize', 'collapse'
      #titlebar
      #
      #Type: Boolean, String
      #
      #Default: false
      #
      #Valid: false, 'none', 'transparent'
      #icons
      #
      #Type: Object
      #
      #Default:
      #
      #{
      #  "close" : "ui-icon-circle-closethick", // new in v1.0.1
      #  "maximize" : "ui-icon-extlink",
      #  "minimize" : "ui-icon-minus",
      #  "restore" : "ui-icon-newwin"
      #}
      #
      #Valid: <jQuery UI icon class>
      # Basic Example:
      #      $("<div>This is content</div>")
      #      .dialog({ "title" : "My Dialog" })
      #      .dialogExtend({
      #        "maximizable" : true,
      #        "dblclick" : "maximize",
      #        "icons" : { "maximize" : "ui-icon-arrow-4-diag" }
      #      });
      #      
      #      So: @dom_object.dialog(standard_options).dialogExtend(extended_options)
      #
      def initialize(settings)
        super(settings)
        @base_tag = "div"
        # minimum z-index of 100, managed by jQuery
        # `#{@dom_object}.dialog(#{JSON.generate(standard_options)}).dialogExtend(#{JSON.generate(extended_options)})`
        self
      end
      #
      def activate()
        super()
        if @dom_object
          valid_standard_options = {:append_to => "appendTo", :auto_open => "autoOpen", :buttons => "buttons", :classes => "classes",
            :close_on_escape => "closeOnEscape", :close_text => "closeText", :dialog_class => "dialogClass", :draggable => "draggable",
            :height => "height", :hide => "hide", :max_height => "maxHeight", :max_width => "maxWidth", :min_height => "minHeight",
            :min_width => "minWidth", :modal => "modal", :position => "position", :resizable => "resizable", :show => "show", :title => "title",
            :width => "width"}
          valid_extended_options = {:closable => "closable", :maximizable => "maximizable", :minimizable => "minimizable",
            :collapsable => "collapsable", :minimize_location => "minimizeLocation", :double_click => "dblclick", :titlebar => "titlebar",
            :icons => "icons"}
          standard_options = {}
          extended_options = {}
          @options.keys.each do |the_option|
            if valid_standard_options.keys.include?(the_option)
              standard_options[(valid_standard_options[(the_option)])] = @options[(the_option)]
            end
            if valid_extended_options.keys.include?(the_option)
              extended_options[(valid_extended_options[(the_option)])] = @options[(the_option)]
            end
          end
          #`#{@dom_object}.dialog(#{JSON.generate(standard_options)}).dialogExtend(#{JSON.generate(extended_options)})`
          if extended_options.size > 0
            @dom_object.dialog(standard_options).dialogExtend(extended_options)
          else
            @dom_object.dialog(standard_options)
          end
        end
      end
      #
      def hide()
        if @dom_object
          @dom_object.dialog("hide")
          @visible = false
        end
      end
      #
      def show()
        if @dom_object
          @dom_object.dialog("show")
          @visible = true
        end
      end
      #
    end
    #
    class Accordion < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # `#{@dom_object}.accordion();`
        # has: Title, and Content (sections)
        self
      end
      #
      def activate()
        unless @dom_object
          self.establish_dom_link
        end
        if @dom_object
          @dom_object.accordion();
        end
        # super()
        true
      end
      #
    end
    #
    class AccordionSection < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # has: AccordionSectionLabel, and AccordionSectionContent: (any)
        # some compound-obj slight of hand here.
        # 
        @banner = nil
        @content = nil
        self
      end
      #
      def establish_dom_link()
        unless @banner && @content
          contents = GxG::children_of(self)
          contents.each do |the_object|
            if the_object.is_a?(GxG::Gui::AccordionSectionLabel)
              @banner = the_object
            end
            if the_object.is_a?(GxG::Gui::AccordionSectionContent)
              @content = the_object
            end
            if @banner && @content
              break
            end
          end
        end
        true
      end
      #
      def activate()
        unless @banner && @content
          self.establish_dom_link()
        end
        true
      end
      #
      def deactivate()
        true
      end
      #
      def generate_html()
        accumulator = []
        contents = GxG::children_of(self)
        contents.each do |the_object|
          accumulator << the_object.generate_html()
        end
        accumulator.join("\n")
      end
      #
      def sync_to_dom()
        # this is called on the banner and content elsewhere
        true
      end
      #
      def sync_from_dom()
        # this is called on the banner and content elsewhere ?
        nil
      end
      #
      def hide()
        # No-op
      end
      #
      def show()
        # No-op
      end
      #
    end
    #
    class AccordionSectionLabel < GuiComponent
      def initialize(settings)
        super(settings)
        @base_tag = "H3"
        # text held in @value ?
        self
      end
      #
      def set_options(options={})
        @options = options
        if options[:font_size].is_a?(Numeric)
          # Font size in EM units only
          case options[:font_size].to_f
          when 2.0
            @base_tag = "H1"
          when 1.5
            @base_tag = "H2"
          when 1.17
            @base_tag = "H3"
          when 1.0
            @base_tag = "H4"
          when 0.83
            @base_tag = "H5"
          when 0.67
            @base_tag = "H6"
          else
            @base_tag = "H3"
            @style[:'font-size'] = "#{options[:font_size].to_f}em"
          end
        end
      end
      #
    end
    #
    class AccordionSectionContent < GuiComponent
      def initialize(settings)
        super(settings)
        self
      end
      #
    end
    #
    class Anchor < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "a"
        # a (anchor) tag
        # has: href, and text value.
        self
      end
      #
      def generate_html()
        super({:href => "#"})
      end
    end
    #
    class Button < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "button"
        # button tag
        self
      end
      #
    end
    #
    class RadioButton < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "input"
        @attributes[:type] = "radio"
        self
      end
      #
    end
    #
    class CheckBoxButton < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "input"
        @attributes[:type] = "checkbox"
        self
      end
      #
    end
    #
    class Division < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "div"
        self
      end
      #
    end
    #
    class InputLabel < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "label"
        # label tag
        # for=(a control uuid)
        self
      end
      #
      def set_options(options={})
        @options = options
        if options[:font_size].is_a?(Numeric)
          # Font size in EM units only
          @style[:'font-size'] = "#{options[:font_size].to_f}em"
        end
      end
      #
    end
    #
    class Paragraph < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "p"
        # p tag
        self
      end
      #
    end
    #
    class TextLabel < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "h1"
        # h1 tag
        self
      end
      #
      def set_options(options={})
        @options = options
        if options[:font_size].is_a?(Numeric)
          # Font size in EM units only
          @style[:'font-size'] = "#{options[:font_size].to_f}em"
        end
      end
      #
    end
    #
    class Legend < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "legend"
        # legend tag
        self
      end
      #
    end
    #
    class ListItem < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "li"
        # li tag
        self
      end
      #
    end
    #
    class OrderedList < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "ol"
        # ol tag
        self
      end
      #
    end
    #
    class UnorderedList < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "ul"
        # ul tag
        self
      end
      #
    end
    #
    class ControlGroup < GuiComponent
      # See: http://jqueryui.com/controlgroup/
      def initialize(settings)
        super(settings)
        self
      end
      #
    end
    #
    class FieldSet < GuiComponent
      def initialize(settings)
        super(settings)
        @base_tag = "fieldset"
        # fieldset tag
        self
      end
      #
    end
    #
    class TextInput < GuiComponent
      # See: http://jqueryui.com/controlgroup/
      def initialize(settings)
        super(settings)
        @base_tag = "input"
        @attributes[:type] = "text"
        # input tag, type="text"
        # For auto-complete: `#{@dom_object}.autocomplete({source: <JS-Array>});`
        self
      end
      #
      def generate_html()
        super({:type => "text"})
      end
      #
    end
    #
    class DatePicker < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "input"
        # `#{@dom_object}.datepicker();`
        # input tag, type="text"
        self
      end
      #
      def generate_html()
        super({:type => "text"})
      end
      #
      def establish_dom_link()
        super()
        if @dom_object
          @dom_object.datepicker()
        end
        true
      end
    end
    #
    class MenuBar < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # sections have: title
        # @record[:style][:z_index] = 99
        self
      end
      #
      def establish_dom_link()
        # No event linking for menubar - just a place holder object.
        @dom_object = Element.find("##{@uuid.to_s}")
      end
    end
    #
    class Menu < GuiComponent
      private
      #
      def menu_body_html(menu_hash=nil)
        result = ""
        # FIX: watch your stack depth !
        unless menu_hash
          menu_hash = @options[:menu_definition]
        end
        if menu_hash.is_a?(::Hash)
          menu_hash.keys.each do |choice|
            if menu_hash[(choice)].is_a?(::Array)
              result = (result + "<li><div>" + "<img src='#{menu_hash[(choice)][0].to_s}' alt='#{choice.to_s}' width='16' height='16'>" + choice.to_s + "</div></li>")
              #
            end
            if menu_hash[(choice)].is_a?(::Hash)
              result = (result + "<li><div>" + choice.to_s + "</div><ul>" + menu_body_html(menu_hash[(choice)]) + "</ul></li>")
              #
            end
            if menu_hash[(choice)].is_any?(::String, ::Symbol)
              result = (result + "<li><div>" + menu_hash[(choice)] + "</div></li>")
            end
            #
          end
        end
        #
        result
      end
      #
      public
      #
      def decode_choice(selection=nil,menu_hash=nil)
        result = nil
        # FIX: watch your stack depth !
        unless menu_hash
          menu_hash = @options[:menu_definition]
        end
        if menu_hash.is_a?(::Hash)
          menu_hash.keys.each do |choice|
            if menu_hash[(choice)].is_a?(::Array)
              if choice.to_s == selection
                result = menu_hash[(choice)][1]
                break
              end
              #
            end
            if menu_hash[(choice)].is_a?(::Hash)
              result = decode_choice(selection,menu_hash[(choice)])
              if result
                break
              end
            end
            if menu_hash[(choice)].is_any?(::String, ::Symbol)
              if choice.to_s == selection
                result = menu_hash[(choice)]
                break
              end
            end
          end
        end
        result
      end
      #
      def initialize(settings)
        super(settings)
        @base_tag = "ul"
        # Needs custom generateHTML
        # Contains Ordered and Unordered Lists: class='ui-state-disabled' to disable menu any menu item/sub-item.
        # Idea:
        # @options[:menu_definition] contains the menu definition.
        # Structure: key is text label of choice, value is a) code associated, b) Array with image path to icon then code associated (later: 3rd item key-code).
        # If Hash = sub-menu following same pattern
        # trap menuselect to match string with @options[:menu_definition] hash/sub-hash
        # ???
        self
      end
      #
      def establish_dom_link()
        @dom_object = Element.find("##{@uuid.to_s}")
        true
      end
      #
      def activate()
        unless @dom_object
          self.establish_dom_link
        end
        if @dom_object
          # Set event traps on @dom_object
          @dom_object.menu()
          self.hide()
          @dom_object.on :menuselect do |event,ui|
            self.hide()
            data = self.decode_choice(`#{ui}.item.text()`)
            if data
              GxG::DISPLAY_DETAILS[:object].process_event({:uuid => @uuid, :event => event, :data => data})
            end
          end
        end
        true
      end
      #
      def set_options(the_options={})
        if the_options.is_a?(::Hash)
          the_options.keys.each do |op_key|
            if op_key == :visibility
              case op_key
              when "hide"
                self.hide()
              when "show"
                self.show()
              when "toggle"
                self.toggle_visibility()
              end
            else
              #
              if op_key == :menu_definition
                if @options[:menu_definition].hash != the_options[:menu_definition].hash
                  @options[:menu_definition] = the_options[:menu_definition]
                  if @dom_object
                    @dom_object.html(menu_body_html())
                  end
                end
              else
                @options[(op_key.to_sym)] = the_options[(op_key)]
              end
              #
            end
          end
        end
        #
      end
      #
      def generate_html()
        if @classes.size > 0
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}' class='#{@classes.to_s}'"
        else
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}'"
        end
        #
        if @attributes.size > 0
          @attributes.keys.each do |the_key|
            result = result + " #{the_key.to_s}='#{@attributes[(the_key)].to_s}'"
          end
        end
        #
        if @style.keys.size > 0
          style_string = " style='"
        else
          style_string = ""
        end
        @style.keys.each do |the_key|
          unless @style[(the_key)] == ""
            #the_property = GxG::Css::get_property_name(the_key)
            the_property = (the_key.to_s.gsub("_","-"))
            if the_property
              style_string = style_string + " #{the_property.to_s}: #{@style[(the_key)].to_s};"
            end
          end
        end
        if style_string.size > 0
          result = (result + style_string + "'")
        end
        result = (result + ">" + menu_body_html() + "</#{@base_tag.to_s}>")
        result
      end
      #
    end
    #
    class SelectMenu < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "select"
        # select tag
        # Contains: SelectMenuOption(s).
        self
      end
      #
    end
    #
    class SelectMenuOption < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "option"
        # option tag
        # <option selected="selected">Blah Blah</option> to select the SelectMenuOption.
        self
      end
      #
    end
    #
    class Slider < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # div tag
        # `#{@dom_object}.slider();`
        # Read Value: `#{@dom_object}.slider('value');`
        # Write Value: `#{@dom_object}.slider('value', the_value);`
        self
      end
      #
      def activate()
        unless @dom_object
          self.establish_dom_link()
        end
        if @dom_object
          @dom_object.slider()
        end
      end
      #
    end
    #
    class Spinner < GuiComponent
      #
      def initialize(settings)
        super(settings)
        @base_tag = "input"
        # input tag
        # `#{@dom_object}.spinner();`
        # Read Value: `#{@dom_object}.spinner('value');`
        # Write Value: `#{@dom_object}.spinner('value', the_value);`
        self
      end
      #
      def activate()
        if @dom_object
          @dom_object.spinner()
        end
      end
    end
    #
    class ProgressBar < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # uses div tag
        # `#{@dom_object}.progressbar({value: 37});`
        # Read Progress Percentage Value: `#{@dom_object}.progressbar('value');`
        # Write Progress Percentage Value: `#{@dom_object}.progressbar('value', the_percentage);`
        # Inner div tag for progress-label: <div class="progress-label">Loading...</div>
        self
      end
      #
      def activate()
        unless @dom_object
          self.establish_dom_link()
        end
        if @dom_object
          @dom_object.progressbar()
        end
      end
      #
    end
    #
    class Tabs < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # div tag
        # `#{@dom_object}.tabs();`
        #        <div id="tabs">
        #          <ul>
        #            <li><a href="#tabs-1">Nunc tincidunt</a></li>
        #            <li><a href="#tabs-2">Proin dolor</a></li>
        #            <li><a href="#tabs-3">Aenean lacinia</a></li>
        #          </ul>
        #          <div id="tabs-1">
        #            <p>Proin elit arcu, rutrum commodo, vehicula tempus, commodo a, risus. Curabitur nec arcu. Donec sollicitudin mi sit amet mauris. Nam elementum quam ullamcorper ante. Etiam aliquet massa et lorem. Mauris dapibus lacus auctor risus. Aenean tempor ullamcorper leo. Vivamus sed magna quis ligula eleifend adipiscing. Duis orci. Aliquam sodales tortor vitae ipsum. Aliquam nulla. Duis aliquam molestie erat. Ut et mauris vel pede varius sollicitudin. Sed ut dolor nec orci tincidunt interdum. Phasellus ipsum. Nunc tristique tempus lectus.</p>
        #          </div>
        #          <div id="tabs-2">
        #            <p>Morbi tincidunt, dui sit amet facilisis feugiat, odio metus gravida ante, ut pharetra massa metus id nunc. Duis scelerisque molestie turpis. Sed fringilla, massa eget luctus malesuada, metus eros molestie lectus, ut tempus eros massa ut dolor. Aenean aliquet fringilla sem. Suspendisse sed ligula in ligula suscipit aliquam. Praesent in eros vestibulum mi adipiscing adipiscing. Morbi facilisis. Curabitur ornare consequat nunc. Aenean vel metus. Ut posuere viverra nulla. Aliquam erat volutpat. Pellentesque convallis. Maecenas feugiat, tellus pellentesque pretium posuere, felis lorem euismod felis, eu ornare leo nisi vel felis. Mauris consectetur tortor et purus.</p>
        #          </div>
        #          <div id="tabs-3">
        #            <p>Mauris eleifend est et turpis. Duis id erat. Suspendisse potenti. Aliquam vulputate, pede vel vehicula accumsan, mi neque rutrum erat, eu congue orci lorem eget lorem. Vestibulum non ante. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Fusce sodales. Quisque eu urna vel enim commodo pellentesque. Praesent eu risus hendrerit ligula tempus pretium. Curabitur lorem enim, pretium nec, feugiat nec, luctus a, lacus.</p>
        #            <p>Duis cursus. Maecenas ligula eros, blandit nec, pharetra at, semper at, magna. Nullam ac lacus. Nulla facilisi. Praesent viverra justo vitae neque. Praesent blandit adipiscing velit. Suspendisse potenti. Donec mattis, pede vel pharetra blandit, magna ligula faucibus eros, id euismod lacus dolor eget odio. Nam scelerisque. Donec non libero sed nulla mattis commodo. Ut sagittis. Donec nisi lectus, feugiat porttitor, tempor ac, tempor vitae, pede. Aenean vehicula velit eu tellus interdum rutrum. Maecenas commodo. Pellentesque nec elit. Fusce in lacus. Vivamus a libero vitae lectus hendrerit hendrerit.</p>
        #          </div>
        #        </div>
        self
      end
      #
      def activate()
        unless @dom_object
          self.establish_dom_link()
        end
        if @dom_object
          @dom_object.tabs()
        end
      end
      #
      def generate_html()
        if @classes.size > 0
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}' class='#{@classes.to_s}'"
        else
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}'"
        end
        #
        if @attributes.size > 0
          @attributes.keys.each do |the_key|
            result = result + " #{the_key.to_s}='#{@attributes[(the_key)].to_s}'"
          end
        end
        #
        if @style.keys.size > 0
          style_string = " style='"
        else
          style_string = ""
        end
        @style.keys.each do |the_key|
          unless @style[(the_key)] == ""
            the_property = GxG::Css::get_property_name(the_key)
            if the_property
              style_string = style_string + " #{the_property.to_s}: #{@style[(the_key)].to_s};"
            end
          end
        end
        if style_string.size > 0
          result = (result + style_string + "'")
        end
        result = result + ">"
        section_headers = []
        accumulator = []
        contents = GxG::children_of(self)
        contents.each do |the_object|
          section_headers << {:uuid => the_object.uuid.to_s, :title => the_object.get_options()[:title].to_s}
          accumulator << the_object.generate_html()
        end
        result = result + "<ul>"
        section_headers.each do |the_record|
          result = result + "<li><a href='##{the_record[:uuid].to_s}'>#{the_record[:title].to_s}</a></li>"
        end
        result = result + "</ul>"
        result = (result + accumulator.join("\n") + "</#{@base_tag.to_s}>")
        #
        result
      end
      #
    end
    #
    class TabSection < GuiComponent
      # has label (bound to content uuid) and content (any): options = {:title => "Tab Label Text"}
      def hide()
        # No-op
      end
      def show()
        # No-op
      end
    end
    #
    class Table < GuiComponent
      # ???
      def initialize(settings)
        super(settings)
        @base_tag = "table"
        self
      end
    end
    #
    class TableRow < GuiComponent
      def initialize(settings)
        super(settings)
        @base_tag = "tr"
        self
      end
    end
    #
    class TableHeader < GuiComponent
      def initialize(settings)
        super(settings)
        @base_tag = "th"
        self
      end
    end
    #
    class TableData < GuiComponent
      def initialize(settings)
        super(settings)
        @base_tag = "td"
        self
      end
    end
    #
    class Image < GuiComponent
      def initialize(settings)
        super(settings)
        @base_tag = "img"
        # REQUIRES attributes src=ImageURL and alt=TEXT to be set
        # set width and height in attributes, NOT style
        self
      end
      #
      def generate_html()
        if @classes.size > 0
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}' class='#{@classes.to_s}'"
        else
          result = "<#{@base_tag.to_s} id='#{@uuid.to_s}'"
        end
        #
        if @attributes.size > 0
          @attributes.keys.each do |the_key|
            result = result + " #{the_key.to_s}='#{@attributes[(the_key)].to_s}'"
          end
        end
        #
        if @style.keys.size > 0
          style_string = " style='"
        else
          style_string = ""
        end
        @style.keys.each do |the_key|
          unless @style[(the_key)] == ""
            the_property = GxG::Css::get_property_name(the_key)
            if the_property
              style_string = style_string + " #{the_property.to_s}: #{@style[(the_key)].to_s};"
            end
          end
        end
        if style_string.size > 0
          result = (result + style_string + "'")
        end
        result = result + ">"
        # NO end tag on img tag
        result
      end
      #
    end
    #
    class ToolTip < GuiComponent
      #
      def initialize(settings)
        super(settings)
        # This should be a modifier method (feature)- not a component.
        # uses *any* tag
        # `#{any_dom_object}.tooltip();`
        # Set the title attribute on the tag to allow display of the tooltip.
        self
      end
      #
    end
    #
  end
end
