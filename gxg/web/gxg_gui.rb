module GxG
    module Gui
        class Tree < ::GxG::Gui::Vdom::BaseElement
            #
            alias :original_add_child :add_child
            def add_child(object_record=nil)
                if object_record.is_a?(::GxG::Database::DetachedHash)
                    if @content
                        @content.add_child(object_record)
                    else
                        original_add_child(object_record)
                    end
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
            def initialize(the_parent,the_options)
                @content = nil
                @selection = nil
                @processors = {}
                super(the_parent,the_options)
                self
            end
            #
            def cascade()
                #
                interior_component = ::GxG::Database::DetachedHash.new
                interior_component.title = "content #{@uuid.to_s}"
                interior_component[:component] = "org.gxg.gui.list"
                interior_component[:settings] = {}
                interior_component[:options] = {:style => {:"white-space" => "nowrap", :width => "auto", :height => "auto", :"list-style" => "none", :margin => "0px", :padding => "0px"}}
                interior_component[:script] = ""
                interior_component[:content] = []
                #
                @content = nil
                page.build_components(self,[(interior_component)])
                #
                the_object = page.find_object_by("content #{@uuid.to_s}")
                if the_object
                    @content = the_object
                end
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
         ::GxG::Gui::register_component_class(:tree, ::GxG::Gui::Tree)
         #
         class TreeNode < ::GxG::Gui::ListItem
            #
            def _before_create
                if @data.is_a?(::Hash)
                    if @data[:title]
                        @title = @data[:title]
                    end
                end
                super()
            end
            #
            alias :original_add_child :add_child
            def add_child(object_record=nil)
                if object_record.is_a?(::GxG::Database::DetachedHash)
                    if @content
                        @content.add_child(object_record)
                    else
                        original_add_child(object_record)
                    end
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
                if @appearance.is_any?(::Hash, ::GxG::Database::DetachedHash)
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
                if the_record.is_any?(::Hash, ::GxG::Database::DetachedHash)
                    @appearance = the_record
                    # Look for :label, :icon w/in the hash record w/in the array.
                    self.update_appearance()
                end
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
            def initialize(the_parent,the_options)
                @content = nil
                @appearance = {:icon => theme_icon("folder.svg"), :label => "Untitled"}
                if the_options.is_any?(::Hash, ::GxG::Database::DetachedHash)
                    # Pass an Hash record containing at LEAST: :title, :type, and :content.
                    @data = (the_options[:data] || {:title => "Untitled", :type => "virtual_directory", :content => {}})
                    # select proper icon for @data[:type] value ?? (do in application!)
                    @appearance[:icon] = (the_options[:icon] || theme_icon("folder.svg")).to_s
                    @appearance[:label] = (the_options[:label] || @data[:title]).to_s
                end
                super(the_parent,the_options)
                self
            end
            #
            def cascade()
                #
                node_frame = ::GxG::Database::DetachedHash.new
                node_frame[:component] = "org.gxg.gui.block.table"
                node_frame[:settings] = {}
                node_frame[:options] = {:nodepath => (self.node_path()), :style => {}}
                node_frame[:script] = ""
                #
                frame_row_one = ::GxG::Database::DetachedHash.new
                frame_row_one[:component] = "org.gxg.gui.block.table"
                frame_row_one[:settings] = {}
                frame_row_one[:options] = {}
                frame_row_one[:script] = ""
                frame_row_one[:content] = []
                #
                expander = ::GxG::Database::DetachedHash.new
                expander.title = "expander #{@uuid.to_s}"
                expander[:component] = "org.gxg.gui.image"
                expander[:settings] = {}
                expander[:options] = {:src=>(theme_widget("collapse.svg")), :width=>32, :height=>32, :style => {:clear => "both", :'vertical-align' => 'middle'}}
                expander[:script] = "
                on(:mouseup) do |event|
                    the_node = self.tree_node()
                    if the_node
                        unless the_node.get_state(:disabled) == true
                            if self.get_state(:expanded) == true
                                self.set_attribute(:src, theme_widget('collapse.svg'))
                                self.set_state(:expanded,false)
                                the_node.collapse()
                            else
                                self.set_attribute(:src, theme_widget('expand.svg'))
                                self.set_state(:expanded,true)
                                the_node.expand()
                            end
                        end
                    end
                end
                "
                expander[:content] = []
                #
                node_expander_cell = ::GxG::Database::DetachedHash.new
                node_expander_cell[:component] = "org.gxg.gui.block.table.cell"
                node_expander_cell[:settings] = {}
                node_expander_cell[:options] = {:style => {:float => "left", :width => "32px", :'vertical-align' => 'middle'}}
                node_expander_cell[:script] = ""
                node_expander_cell[:content] = [(expander)]
                #
                icon = ::GxG::Database::DetachedHash.new
                icon.title = "icon #{@uuid.to_s}"
                icon[:component] = "org.gxg.gui.image"
                icon[:settings] = {}
                icon[:options] = {:src=>@appearance[:icon], :style => {:clear => "both", :width=>"32px", :height=>"32px", :'vertical-align' => 'middle'}}
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
                icon[:content] = []
                #
                node_icon_cell = ::GxG::Database::DetachedHash.new
                node_icon_cell[:component] = "org.gxg.gui.block.table.cell"
                node_icon_cell[:settings] = {}
                node_icon_cell[:options] = {:style => {:float => "left", :width => "32px", :'vertical-align' => 'middle'}}
                node_icon_cell[:script] = ""
                node_icon_cell[:content] = [(icon)]
                #
                the_title = ::GxG::Database::DetachedHash.new
                the_title.title = "title #{@uuid.to_s}"
                the_title[:component] = "org.gxg.gui.label"
                the_title[:settings] = {}
                the_title[:options] = {:content => @appearance[:label], :style => {:float => "left", :'font-size' => '16px', :'vertical-align' => 'middle', :'text-align' => 'left', :margin => "2px", :padding => "2px"}}
                the_title[:script] = "
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
                the_title[:content] = []
                #
                node_label_cell = ::GxG::Database::DetachedHash.new
                node_label_cell[:component] = "org.gxg.gui.block.table.cell"
                node_label_cell[:settings] = {}
                node_label_cell[:options] = {:style => {:float => "left", :'vertical-align' => 'middle'}}
                node_label_cell[:script] = ""
                node_label_cell[:content] = [(the_title)]
                #
                frame_row_one = ::GxG::Database::DetachedHash.new
                frame_row_one[:component] = "org.gxg.gui.block.table.row"
                frame_row_one[:settings] = {}
                frame_row_one[:options] = {}
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
                frame_row_one[:content] = [(node_expander_cell), (node_icon_cell), (node_label_cell)]
                #
                sublist = ::GxG::Database::DetachedHash.new
                sublist.title = "content #{@uuid.to_s}"
                sublist[:component] = "list"
                sublist[:settings] = {}
                sublist[:options] = {:width => "100%", :height => "100%", :style => {:"list-style" => "none"}}
                sublist[:script] = ""
                sublist[:content] = []
                #
                subnodes_frame_cell = ::GxG::Database::DetachedHash.new
                subnodes_frame_cell[:component] = "org.gxg.gui.block.table.cell"
                subnodes_frame_cell[:settings] = {}
                subnodes_frame_cell[:options] = {}
                subnodes_frame_cell[:script] = ""
                subnodes_frame_cell[:content] = [(sublist)]
                #
                frame_row_two = ::GxG::Database::DetachedHash.new
                frame_row_two[:component] = "org.gxg.gui.block.table.row"
                frame_row_two[:settings] = {}
                frame_row_two[:options] = {}
                frame_row_two[:script] = ""
                frame_row_two[:content] = [(subnodes_frame_cell)]
                #
                node_frame[:content] = [(frame_row_one),(frame_row_two)]
                #
                @content = nil
                page.build_components(self, [(node_frame)])
                #
                the_object = page.find_object_by("content #{@uuid.to_s}")
                if the_object
                    @content = the_object
                end
                # 
                the_object = page.find_object_by("expander #{@uuid.to_s}")
                if the_object
                    @expander = the_object
                end
                #
                the_object = page.find_object_by("icon #{@uuid.to_s}")
                if the_object
                    @icon = the_object
                end
                #
                the_object = page.find_object_by("title #{@uuid.to_s}")
                if the_object
                    @label = the_object
                end
                #
            end
            # TODO: Add animation / transition effects.
            def highlight(transition_parameters=nil)
                if @label
                    @label.merge_style({:'background-color' => '#87acd5'})
                end
            end
            #
            def unhighlight(transition_parameters=nil)
                if @label
                    @label.merge_style({:'background-color' => '#f2f2f2'})
                end
            end
            #
            def expand(transition_parameters=nil)
                @content.show(transition_parameters)
                self.set_state(:expanded, true)
                if @expander
                    @expander.set_attribute(:src,GxG::DISPLAY_DETAILS[:object].theme_widget("expand.svg"))
                end
                the_tree = self.tree()
                if the_tree
                    the_tree.expand(self)
                end
            end
            #
            def collapse(transition_parameters=nil)
                @content.hide(transition_parameters)
                self.set_state(:expanded, false)
                if @expander
                    @expander.set_attribute(:src,GxG::DISPLAY_DETAILS[:object].theme_widget("collapse.svg"))
                end
                the_tree = self.tree()
                if the_tree
                    the_tree.collapse(self)
                end
            end
            #
            def enable(transition_parameters=nil)
                if transition_parameters.is_any?(::Hash, ::GxG::Database::DetachedHash)
                    if transition_parameters.is_a?(::GxG::Database::DetachedHash)
                        transition_parameters = transition_parameters.unpersist
                    end
                else
                    transition_parameters = {:origin => {:opacity => 0.5}, :destination => {:opacity => 1.0}}
                end
                self.children.each_pair do |name, object|
                    unless name == "content #{@uuid.to_s}".to_sym
                        object.set_state(:disabled, false)
                        object.animate(transition_parameters)
                    end
                end
            end
            #
            def disable(transition_parameters=nil)
                if transition_parameters.is_any?(::Hash, ::GxG::Database::DetachedHash)
                    if transition_parameters.is_a?(::GxG::Database::DetachedHash)
                        transition_parameters = transition_parameters.unpersist
                    end
                else
                    transition_parameters = {:origin => {:opacity => 1.0}, :destination => {:opacity => 0.5}}
                end
                self.children.each_pair do |name, object|
                    unless name == "content #{@uuid.to_s}".to_sym
                        object.animate(transition_parameters)
                        object.set_state(:disabled, true)
                    end
                end
            end
            #
         end
         ::GxG::Gui::register_component_class(:tree_node, ::GxG::Gui::TreeNode)
         #
        class Panel < ::GxG::Gui::Vdom::BaseElement
            # TODO: Add auto-hide/hide/roll up-left-down-right capabilites with animations.
        end
        ::GxG::Gui::register_component_class(:panel, ::GxG::Gui::Panel)
        # Page extensions
        module Vdom
            class Page
                # Choice Dialog
                def choice_dialog(the_application=nil, details=nil, &block)
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
                    banner = {:component=>"org.gxg.gui.text", :options=> {:content => banner_text, :style => {:"font-size" => "#{banner_font_size}px", :width => "100%"}}, :content => [], :script => ""}
                    banner_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "100%",  :height => (banner_height), :"vertical-align" => "middle"}}, :content => [(banner)], :script => ""}
                    #
                    text_input = {:component=>"org.gxg.gui.input.text", :options=>{:title => "data", :content => default_text, :style => {:"background-color" => "#f2f2f2", :"font-size" => "#{input_font_size}px", :width => "100%"}}, :content=>[], :script=>""}
                    text_input_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "100%",  :"vertical-align" => "middle"}}, :content => [(text_input)], :script => ""}
                    # Buttons:
                    one_btn = {:component=>"org.gxg.gui.button", :options=>{:content => one_text, :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                    one_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.respond({:action => :one})
                        end
                    end
                    "
                    one_btn_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "40%",  :"vertical-align" => "middle"}}, :content => [(one_btn)], :script => ""}
                    #
                    two_btn = {:component=>"org.gxg.gui.button", :options=>{:content => two_text, :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                    two_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.respond({:action => :two})
                        end
                    end
                    "
                    two_btn_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "40%",  :"vertical-align" => "middle"}}, :content => [(two_btn)], :script => ""}
                    #
                    three_btn = {:component=>"org.gxg.gui.button", :options=>{:content => three_text, :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                    three_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.respond({:action => :three})
                        end
                    end
                    "
                    three_btn_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px", :width => "40%",  :"vertical-align" => "middle"}}, :content => [(three_btn)], :script => ""}
                    #
                    cancel_btn = {:component=>"org.gxg.gui.button", :options=>{:content => "Cancel", :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                    cancel_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.respond({:action => :cancel})
                        end
                    end
                    "
                    cancel_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px",  :"vertical-align" => "middle"}}, :content => [(cancel_btn)], :script => ""}
                    #
                    # Define Containers:
                    # Rows:
                    row_one = {:component=>"org.gxg.gui.block.table.row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(banner_cell)], :script=>""}
                    row_two = {:component=>"org.gxg.gui.block.table.row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[(text_input_cell)], :script=>""}
                    row_three = {:component=>"org.gxg.gui.block.table.row", :options=>{:style => {:padding => "0px", :margin => "0px", :width => "100%"}}, :content=>[], :script=>""}
                    # Tables:
                    table_one = {:component=>"org.gxg.gui.block.table", :options=>{:style => {:padding => "5px", :margin => "0px", :width => "100%"}}, :content=>[(row_one)], :script=>""}
                    table_two = {:component=>"org.gxg.gui.block.table", :options=>{:style => {:padding => "5px", :margin => "0px", :width => "100%"}}, :content=>[(row_two)], :script=>""}
                    table_three = {:component=>"org.gxg.gui.block.table", :options=>{:style => {:padding => "5px", :margin => "0px", :width => "100%"}}, :content=>[(row_three)], :script=>""}
                    #
                    # Form:
                    form = {:component=>"org.gxg.gui.form", :options=>{:style => {:"background-color" => "#f2f2f2", :padding => "#{form_padding}px", :margin => "#{form_margin}px"}}, :content=>[], :script=>""}
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
                        action_btn = {:component=>"org.gxg.gui.button", :options=>{:content => "OK", :style => {:padding => "2px", :width => "80px", :height => "32px"}}, :content=>[], :script=>""}
                        action_btn[:script] = "
                        on(:mouseup) do |event|
                            the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                            if the_window
                                the_window.respond({:action => :ok})
                            end
                        end
                        "
                        action_btn_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px"}}, :content => [(action_btn)], :script => ""}
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
                        action_btn_cell = {:component => "org.gxg.gui.block.table.cell", :options => {:style => {:padding => "0px", :margin => "0px"}}, :content => [(action_btn)], :script => ""}
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
                    dialog_source = {:component => "org.gxg.gui.window.dialog", :options => {:window_title => window_title, :states => {:hidden => true}, :width => total_width, :height => total_height}, :script => "", :content => [(form)]}
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
                    #
                    menu_item_script = "
                    def select(data=nil)
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.settings[:data] = @settings[:data]
                            menu_bar_header = page.find_object_by('gxg_path_menu_header')
                            if menu_bar_header
                                menu_bar_header.set_label(File.basename(@settings[:data]))
                                menu_bar_header.set_data(@settings[:data])
                            end
                            menu = page.find_object_by('gxg_path_menu')
                            if menu
                                menu.update_menu(@settings[:data])
                            end
                            sublist = page.find_object_by('gxg_path_subitems')
                            if sublist
                                sublist.update_appearance()
                            end
                        end
                    end
                    "
                    #
                    menu_bar = ::GxG::Database::DetachedHash.new
                    menu_bar.title = "gxg_path_menu_bar"
                    menu_bar[:component] = "org.gxg.gui.menu.bar"
                    menu_bar[:settings] = {:path => (details[:path] || "/")}
                    menu_bar[:options] = {}
                    menu_bar[:script] = ""
                    menu_bar[:content] = []
                    #
                    menu_header = ::GxG::Database::DetachedHash.new
                    menu_header.title = "gxg_path_menu_header"
                    menu_header[:component] = "org.gxg.gui.menu.item"
                    menu_header[:settings] = {:label => File.basename(menu_bar[:settings][:path]), :data => nil}
                    menu_header[:options] = {}
                    menu_header[:script] = ""
                    menu_header[:content] = []
                    #
                    menu = ::GxG::Database::DetachedHash.new
                    menu.title = "gxg_path_menu"
                    menu[:component] = "org.gxg.gui.menu"
                    menu[:settings] = {:item_script => menu_item_script}
                    menu[:options] = {}
                    menu[:script] = "
                    def update_menu(the_path=nil)
                        if the_path.is_a?(::String)
                            build_list = []
                            menu[:content] = []
                            #
                            menu_manifest = []
                            (0..(the_path.split('/').size - 1)).each do |the_index|
                                menu_manifest << (the_path.split('/')[0..(the_index)].join('/'))
                            end
                            menu_manifest.reverse.[1..-1].each do |the_subpath|
                                the_item = ::GxG::Database::DetachedHash.new
                                the_item[:component] = 'menu_item'
                                the_item[:settings] = {:label => File.basename(the_subpath), :data => the_subpath}
                                the_item[:options] = {}
                                the_item[:script] = @settings[:item_script].to_s
                                the_item[:content] = []
                                build_list << the_item
                            end
                            children.values.reverse.each do |the_child|
                                the_child.destroy
                            end
                            if build_list.size > 0
                                page.build_components(self, build_list)
                            end
                            #
                        end
                    end
                    "
                    menu[:content] = []
                    #
                    menu_manifest = []
                    (0..(menu_bar[:settings][:path].split("/").size - 1)).each do |the_index|
                        menu_manifest << (menu_bar[:settings][:path].split("/")[0..(the_index)].join("/"))
                    end
                    menu_manifest.reverse[1..-1].each do |the_path|
                        the_item = ::GxG::Database::DetachedHash.new
                        the_item[:component] = "org.gxg.gui.menu.item"
                        the_item[:settings] = {:label => File.basename(the_path), :data => the_path}
                        the_item[:options] = {}
                        the_item[:script] = menu_item_script
                        the_item[:content] = []
                        menu[:content] << the_item
                    end
                    #
                    menu_header[:content] << menu
                    menu_bar[:content] << menu_header
                    #
                    menu_bar_cell = ::GxG::Database::DetachedHash.new
                    menu_bar_cell[:component] = "org.gxg.gui.block.table.cell"
                    menu_bar_cell[:settings] = {}
                    menu_bar_cell[:options] = {:style => {:border => "1px solid #c2c2c2", :padding => "0px", :margin => "0px", :width => "100%"}}
                    menu_bar_cell[:script] = ""
                    menu_bar_cell[:content] = [(menu_bar)]
                    # SubItem List:
                    list_item_script = "
                    def highlight()
                        self.merge_style({:'background-color' => '#c2c2c2'})
                    end
                    def unhighlight()
                        self.merge_style({:'background-color' => '#ffffff'})
                    end
                    def select()
                        # unhighlight all others
                        parent.children.values.each do |the_child|
                            the_child.unhighlight()
                        end
                        # set selection
                        self.highlight()
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.settings[:selection] = self
                        end
                    end
                    on(:mouseup) do |the_event|
                        self.select()
                    end
                    "
                    subitems = ::GxG::Database::DetachedHash.new
                    subitems.title = "gxg_path_subitems"
                    subitems[:component] = "org.gxg.gui.list"
                    subitems[:settings] = {:list_item_script => list_item_script}
                    subitems[:options] = {:style => {:clear => "both", :"list-style" => "none", :padding => "0px", :margin => "0px"}}
                    subitems[:script] = "
                    def add_list_item(the_icon=nil, the_path=nil, the_profile=nil)
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            #
                            the_item = ::GxG::Database::DetachedHash.new
                            the_item[:component] = 'list_tiem'
                            the_item[:settings] = {:label => File.basename(the_path), :data => the_path}
                            the_item[:options] = {}
                            the_item[:script] = @settings[:list_item_script].to_s
                            the_item[:content] = []
                            #
                            the_window.settings[:manifest][(the_item.uuid.to_s.to_sym)] = {:path => the_path, :profile => the_profile}
                            #
                            icon_item = ::GxG::Database::DetachedHash.new
                            icon_item[:component] = 'image'
                            icon_item[:settings] = {}
                            icon_item[:options] = {src => the_icon.to_s, :style => {:width => '16px', :height => '16px'}}
                            icon_item[:script] = '
                            on(:mouseup) do |the_event|
                                parent.select()
                            end
                            '
                            icon_item[:content] = []
                            #
                            label_item = ::GxG::Database::DetachedHash.new
                            label_item[:component] = 'label'
                            label_item[:settings] = {}
                            label_item[:options] = {:content => File.basename(the_path)}
                            label_item[:script] = '
                            on(:mouseup) do |the_event|
                                parent.select()
                            end
                            '
                            label_item[:content] = []
                            #
                            the_item[:content] << icon_item
                            the_item[:content] << label_item
                            page.build_components(self, [(the_item)])
                            true
                        else
                            false
                        end
                    end
                    #
                    def update_appearance()
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            dialog_type = (the_window.settings[:type] || :folder)
                            the_path = the_window.settings[:data]
                            if the_path.is_a?(::String)
                                #
                                the_window.settings[:selection] = nil
                                the_window.settings[:manifest] = {}
                                # Clear List
                                self.children.values.each do |the_child|
                                    the_child.destroy
                                end
                                # Rebuild List
                                GxG::CONNECTION.entries({:location => (the_path)}) do |response|
                                    if response.is_a?(::Hash)
                                        response[:result].each do |the_profile|
                                            # add list item
                                            item_path = (the_path + '/' + the_profile[:title].to_s)
                                            if dialog_type == :folder
                                                if [:virtual_directory, :directory, :persisted_array].include?(the_profile[:type].to_s.to_sym)
                                                    self.add_list_item(self.theme_icon('folder.svg'), item_path, the_profile)
                                                end
                                            else
                                                case (the_profile[:type].to_s.to_sym)
                                                when :virtual_directory, :directory, :persisted_array
                                                    the_icon_path = self.theme_icon('folder.svg')
                                                when :persisted_hash
                                                    the_icon_path = self.theme_icon('object.svg')
                                                else
                                                    # Review: further qualify file type icons ??
                                                    the_icon_path = self.theme_icon('file.svg')
                                                end
                                                self.add_list_item(the_icon_path, item_path, the_profile)
                                            end
                                            #
                                        end
                                        #
                                    end
                                end
                                #
                            end
                        end
                    end
                    "
                    subitems[:content] = []
                    # xxx
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
                    subitems_container = ::GxG::Database::DetachedHash.new
                    subitems_container[:component] = "org.gxg.gui.block"
                    subitems_container[:settings] = {}
                    subitems_container[:options] = {:style => {:width => "100%", :height => "192px", :"overflow-y" => "scroll"}}
                    subitems_container[:script] = ""
                    subitems_container[:content] = [(subitems)]
                    #
                    subitems_cell = ::GxG::Database::DetachedHash.new
                    subitems_cell[:component] = "org.gxg.gui.block.table.cell"
                    subitems_cell[:settings] = {}
                    subitems_cell[:options] = {:style => {:border => "1px solid #c2c2c2", :padding => "0px", :margin => "0px", :width => "100%"}}
                    subitems_cell[:script] = ""
                    subitems_cell[:content] = [(subitems_container)]
                    #  Save As ... Field
                    save_name = ::GxG::Database::DetachedHash.new
                    save_name.title = "gxg_save_name"
                    save_name[:component] = "org.gxg.gui.input.text"
                    save_name[:settings] = {}
                    save_name[:options] = {:style => {:"background-color" => "#f2f2f2", :"font-size" => "16px", :width => "100%"}}
                    save_name[:script] = ""
                    save_name[:content] = []
                    #
                    save_name_cell = ::GxG::Database::DetachedHash.new
                    save_name_cell[:component] = "org.gxg.gui.block.table.cell"
                    save_name_cell[:settings] = {}
                    save_name_cell[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "100%"}}
                    save_name_cell[:script] = ""
                    save_name_cell[:content] = [(save_name)]
                    # Buttons:
                    action_btn = ::GxG::Database::DetachedHash.new
                    action_btn.title = "gxg_action_button"
                    action_btn[:component] = "org.gxg.gui.input.button.submit"
                    action_btn[:settings] = {}
                    action_btn[:options] = {:content => action_title, :style => {:padding => "0px", :width => "80px", :height => "32px"}}
                    action_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        form = self.find_parent_type(::GxG::Gui::Form)
                        if the_window && form
                            the_action = the_window.settings[:type].to_s.to_sym
                            the_path = the_window.settings[:data].to_s
                            if the_action == :save
                                the_path = (the_path + '/' + (form.form_data()[:gxg_save_name] || 'Untitled.data').to_s)
                            end
                            the_window.respond({:action => the_action, :path => the_path})
                        end
                    end
                    "
                    action_btn[:content] = []
                    #
                    action_cell = ::GxG::Database::DetachedHash.new
                    action_cell[:component] = "org.gxg.gui.block.table.cell"
                    action_cell[:settings] = {}
                    action_cell[:options] = {:style => {:padding => "10px 0px 0px 35px", :margin => "0px", :width => "50%"}}
                    action_cell[:script] = ""
                    action_cell[:content] = [(action_btn)]
                    #
                    cancel_btn = ::GxG::Database::DetachedHash.new
                    cancel_btn.title = "gxg_cancel_button"
                    cancel_btn[:component] = "org.gxg.gui.input.button.submit"
                    cancel_btn[:settings] = {}
                    cancel_btn[:options] = {:content => "Cancel", :style => {:padding => "2px", :width => "80px", :height => "32px"}}
                    cancel_btn[:script] = "
                    on(:mouseup) do |event|
                        the_window = self.find_parent_type(::GxG::Gui::DialogBox)
                        if the_window
                            the_window.respond({:action => :cancel})
                        end
                    end
                    "
                    cancel_btn[:content] = []
                    #
                    cancel_cell = ::GxG::Database::DetachedHash.new
                    cancel_cell[:component] = "org.gxg.gui.block.table.cell"
                    cancel_cell[:settings] = {}
                    cancel_cell[:options] = {:style => {:padding => "10px 0px 0px 35px", :margin => "0px", :width => "50%"}}
                    cancel_cell[:script] = ""
                    cancel_cell[:content] = [(cancel_btn)]
                    #
                    # Rows:
                    row_one = ::GxG::Database::DetachedHash.new
                    row_one[:component] = "org.gxg.gui.block.table.row"
                    row_one[:settings] = {}
                    row_one[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "100%"}}
                    row_one[:script] = ""
                    row_one[:content] = [(menu_bar_cell)]
                    #
                    row_two = ::GxG::Database::DetachedHash.new
                    row_two[:component] = "org.gxg.gui.block.table.row"
                    row_two[:settings] = {}
                    row_two[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "100%"}}
                    row_two[:script] = ""
                    row_two[:content] = [(subitems_cell)]
                    #
                    row_three = ::GxG::Database::DetachedHash.new
                    row_three[:component] = "org.gxg.gui.block.table.row"
                    row_three[:settings] = {}
                    row_three[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "100%"}}
                    row_three[:script] = ""
                    row_three[:content] = [(save_name_cell)]
                    #
                    row_four = ::GxG::Database::DetachedHash.new
                    row_four[:component] = "org.gxg.gui.block.table.row"
                    row_four[:settings] = {}
                    row_four[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "100%"}}
                    row_four[:script] = ""
                    row_four[:content] = [(cancel_cell),(action_cell)]
                    #
                    # Tables:
                    table_one = ::GxG::Database::DetachedHash.new
                    table_one[:component] = "org.gxg.gui.block.table"
                    table_one[:settings] = {}
                    table_one[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "32px"}}
                    table_one[:script] = ""
                    table_one[:content] = [(row_one)]
                    #
                    table_two = ::GxG::Database::DetachedHash.new
                    table_two[:component] = "org.gxg.gui.block.table"
                    table_two[:settings] = {}
                    table_two[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "192px"}}
                    table_two[:script] = ""
                    table_two[:content] = [(row_two)]
                    #
                    table_three = ::GxG::Database::DetachedHash.new
                    table_three[:component] = "org.gxg.gui.block.table"
                    table_three[:settings] = {}
                    table_three[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "32px"}}
                    table_three[:script] = ""
                    table_three[:content] = [(row_three)]
                    #
                    table_four = ::GxG::Database::DetachedHash.new
                    table_four[:component] = "org.gxg.gui.block.table"
                    table_four[:settings] = {}
                    table_four[:options] = {:style => {:padding => "0px", :margin => "0px", :width => "300px", :height => "32px"}}
                    table_four[:script] = ""
                    table_four[:content] = [(row_four)]
                    #
                    # Main Build:
                    form = ::GxG::Database::DetachedHash.new
                    form[:component] = "org.gxg.gui.form"
                    form[:settings] = {}
                    form[:options] = {:style => {:"background-color" => "#f2f2f2", :padding => "20px", :margin => "5px", :width => "100%"}}
                    form[:script] = ""
                    form[:content] = []
                    #
                    total_height = 330
                    form[:content] << table_one
                    form[:content] << table_two
                    if dialog_type == :save || dialog_type == "save"
                        form[:content] << table_three
                        total_height += 32
                    end
                    form[:content] << table_four
                    #
                    viewport = ::GxG::Database::DetachedHash.new
                    viewport.title = "gxg_selection_viewport"
                    viewport[:component] = "org.gxg.gui.application.viewport"
                    viewport[:settings] = {}
                    viewport[:options] = {:style => {:overflow => "hidden", :width => "100%", :height => "100%"}}
                    viewport[:script] = ""
                    viewport[:content] = [(form)]
                    #
                    dialog_source = ::GxG::Database::DetachedHash.new
                    dialog_source.title = window_title
                    dialog_source[:component] = "org.gxg.gui.window.dialog"
                    dialog_source[:settings] = {}
                    dialog_source[:options] = {:window_title => window_title, :states => {:hidden => true}, :width => 350, :height => total_height}
                    dialog_source[:script] = ""
                    dialog_source[:content] = [(viewport)]
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
                #
            end
        end
    end
end