module GxG
    module Gui
        # Viewport
        class ApplicationViewport < ::GxG::Gui::Vdom::BaseElement
            def set_application(the_application=nil)
                @application = the_application
            end
            alias :application= :set_application
            #
            def detach()
                if @application
                    if @application.respond_to?(:unlink_viewport)
                        @application.unlink_viewport(@uuid)
                        @application = nil
                    end
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.application.viewport", ::GxG::Gui::ApplicationViewport)
        # ### Window support
        class Window < ::GxG::Gui::Vdom::BaseElement
            #
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
            alias :application= :set_application
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
                if the_reference && the_object && details.is_any?(::Hash, ::GxG::Database::DetachedHash)
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
            alias :top= :set_top
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
            alias :left= :set_left
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
            alias :right= :set_right
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
            alias :bottom= :set_bottom
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
            alias :width= :set_width
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
            alias :height= :set_height
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
            alias :window_title= :set_window_title
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
            def initialize(the_parent,the_options,other_data={})
                # FIXME: work around for strange bug in layout_refresh
                ::GxG::DISPLAY_DETAILS[:object].layout_refresh
                bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                #
                @special_state = nil
                @content = nil
                # Process the_options
                # So, at this point I've decided to use pixels internally, but percentages externally. (interface)
                # You can pass Integer (as Pixels), Float, or String Percentage
                if the_options[:top].is_a?(::String) || the_options[:top].to_s.include?(".")
                    if the_options[:top].is_a?(::String)
                        @top = (bounds[:page_height] * (the_options[:top].gsub("%","").to_f / 100.0))
                    else
                        @top = (bounds[:page_height] * (the_options[:top] / 100.0))
                    end
                else
                    @top = (the_options[:top] || ((`window.innerHeight`.to_i / 2) - 50))
                end
                if the_options[:left].is_a?(::String) || the_options[:left].to_s.include?(".")
                    if the_options[:left].is_a?(::String)
                        @left = (bounds[:page_width] * (the_options[:left].gsub("%","").to_f / 100.0))
                    else
                        @left = (bounds[:page_width] * (the_options[:left] / 100.0))
                    end
                else
                    @left = (the_options[:left] || ((`window.innerWidth`.to_i / 2) - 100))
                end
                if the_options[:right].is_a?(::String) || the_options[:right].to_s.include?(".")
                    if the_options[:right].is_a?(::String)
                        @right = (bounds[:page_width] * (the_options[:right].gsub("%","").to_f / 100.0))
                    else
                        @right = (bounds[:page_width] * (the_options[:right] / 100.0))
                    end
                else
                    @right = (the_options[:right] || ((`window.innerWidth`.to_i / 2) + 100))
                end
                if the_options[:bottom].is_a?(::String) || the_options[:bottom].to_s.include?(".")
                    if the_options[:bottom].is_a?(::String)
                        @bottom = (bounds[:page_height] * (the_options[:bottom].gsub("%","").to_f / 100.0))
                    else
                        @bottom = (bounds[:page_height] * (the_options[:bottom] / 100.0))
                    end
                else
                    @bottom = (the_options[:bottom] || ((`window.innerHeight`.to_i / 2) + 50))
                end
                #
                @window_title = the_options[:window_title] || "Untitled"
                @title_object = nil
                #
                if the_options[:width].is_a?(::String) || the_options[:width].to_s.include?(".")
                    if the_options[:width].is_a?(::String)
                        @right = @left + ((bounds[:right] - bounds[:left]) * (the_options[:width].gsub("%","").to_f / 100.0))
                    else
                        @right = @left + ((bounds[:right] - bounds[:left]) * (the_options[:width] / 100.0))
                    end
                else
                    if the_options[:width].is_a?(::Numeric)
                        @right = (@left + the_options.delete(:width))
                    end
                end
                if the_options[:height].is_a?(::String) || the_options[:height].to_s.include?(".")
                    if the_options[:height].is_a?(::String)
                        @bottom = @top + ((bounds[:bottom] - bounds[:top]) * (the_options[:height].gsub("%","").to_f / 100.0))
                    else
                        @bottom = @top + ((bounds[:bottom] - bounds[:top]) * (the_options[:height] / 100.0))
                    end
                else
                    if the_options[:height].is_a?(::Numeric)
                        @bottom = (@top + the_options[:height])
                    end
                end
                # Bounds check top, left, right, and bottom
                self.fit_within_boundaries()
                #
                @modal = (the_options[:modal] || false)
                @scrolling = the_options[:scroll]
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
                @menu_reference = the_options[:menu]
                @menu_area = nil
                @menu_bar = nil
                if @menu_reference
                    @menu_margin = 16
                else
                    @menu_margin = 0
                end
                #
                super(the_parent,the_options, other_data)
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
            def menubar()
                @menu_area
            end
            #
            # def set_menu(the_menu_source=nil)
            #     if the_menu_source.is_any?(::Hash, ::GxG::Database::DetachedHash)
            #         if @menu_area
            #             page.build_components(@menu_area, [(the_menu_source)])
            #             #
            #             @menu_margin = (`#{@menu_area.element}.getBoundingClientRect().bottom - #{@menu_area.element}.getBoundingClientRect().top`.to_i)
            #             #
            #             @menu_bar = self.find_child(@menu_reference,true)
            #             #
            #             if @menu_bar
            #                 self.commit_settings
            #                 true
            #             else
            #                 log_warn("Unable to properly initialize window menu #{@menu_reference.inspect} .")
            #                 false
            #             end
            #         else
            #             false
            #         end
            #     else
            #         false
            #     end
            # end
            # alias :menu= :set_menu
            #
            alias :original_add_child :add_child
            def add_child(object_record=nil)
                if @content
                    @content.add_child(object_record)
                else
                    original_add_child(object_record)
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
                the_title = ::GxG::Database::DetachedHash.new
                the_title.title = "title_object #{@uuid.to_s}"
                the_title[:component] = "org.gxg.gui.label"
                the_title[:settings] = {}
                the_title[:options] = {:content => @window_title, :style => {:width => "100%", :"font-size" => "16px", :"text-align" => "center"}}
                the_title[:script] = ""
                the_title[:content] = []
                #
                close_box = ::GxG::Database::DetachedHash.new
                close_box[:component] = "org.gxg.gui.image"
                close_box[:settings] = {}
                close_box[:options] = {:src => theme_widget("close.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}
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
                close_box[:content] = []
                #
                minimize_box = ::GxG::Database::DetachedHash.new
                minimize_box[:component] = "org.gxg.gui.image"
                minimize_box[:settings] = {}
                minimize_box[:options] = {:src => theme_widget("minimize.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}
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
                minimize_box[:content] = []
                #
                maximize_box = ::GxG::Database::DetachedHash.new
                maximize_box[:component] = "org.gxg.gui.image"
                maximize_box[:settings] = {}
                maximize_box[:options] = {:src => theme_widget("maximize.png"), :width=>20, :height=>20, :style => {:padding => "2px"}}
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
                maximize_box[:content] = []
                #
                table = ::GxG::Database::DetachedHash.new
                table[:component] = "org.gxg.gui.block.table"
                table[:settings] = {}
                table[:options] = {:style => {:clear => "both", :height=>"24px", :padding => "0px", :margin => "0px", :"border-radius" => "5px 5px 0px 0px", :"border-bottom" => "1px solid #c2c2c2"}, :states => {:"default-background-color" => true}}
                table[:script] = ""
                table[:content] = []
                #
                row = ::GxG::Database::DetachedHash.new
                row[:component] = "org.gxg.gui.block.table.row"
                row[:settings] = {}
                row[:options] = {:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent"}}
                row[:script] = ""
                row[:content] = []
                #
                cell_one = ::GxG::Database::DetachedHash.new
                cell_one[:component] = "org.gxg.gui.block.table.cell"
                cell_one[:settings] = {}
                cell_one[:options] = {:style => {:padding => "0px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent"}}
                cell_one[:script] = ""
                cell_one[:content] = []
                #
                cell_two = ::GxG::Database::DetachedHash.new
                cell_two[:component] = "org.gxg.gui.block.table.cell"
                cell_two[:settings] = {}
                cell_two[:options] = {:style => {:width => "100%",:padding => "0px 0px 0px #{((self.width() / 2) - ((@window_title.size / 2) * 8)) - 60}px", :"vertical-align" => "middle", :margin => "0px", :"background-color" => "transparent"}}
                cell_two[:script] = ""
                cell_two[:content] = []
                #
                cell_three = ::GxG::Database::DetachedHash.new
                cell_three[:component] = "org.gxg.gui.block.table.cell"
                cell_three[:settings] = {}
                cell_three[:options] = {:style => {:float => "right", :padding => "0px", :"vertical-align" => "middle", :margin => "0px", :"background-color" => "transparent"}}
                cell_three[:script] = ""
                cell_three[:content] = []
                #
                # link pieces
                if @closebox
                    if @closebox == :disabled
                        close_box[:options][:src] = theme_widget("close_disable.png")
                        close_box[:options][:states] = {:disabled => true}
                    end
                    cell_one[:content] << close_box
                end
                if @minimizebox
                    if @minimizebox == :disabled
                        minimize_box[:options][:src] = theme_widget("minimize_disable.png")
                        minimize_box[:options][:states] = {:disabled => true}
                    end
                    cell_one[:content] << minimize_box
                end
                if @maximizebox
                    if @maximizebox == :disabled
                        maximize_box[:options][:src] = theme_widget("maximize_disable.png")
                        maximize_box[:options][:states] = {:disabled => true}
                    end
                    cell_one[:content] << maximize_box
                end
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
                cell_two[:content] << the_title
                row[:content] << cell_one
                row[:content] << cell_two
                row[:content] << cell_three
                table[:content] << row
                #
                build_list << table
                #
                interior_component = ::GxG::Database::DetachedHash.new
                interior_component.title = "content #{@uuid.to_s}"
                interior_component[:component] = "org.gxg.gui.block"
                interior_component[:settings] = {}
                interior_component[:options] = {:style => {:clear => "both", :padding => "0px", :margin => "0px", :border => "0px", :width => "#{(self.width - (@resize_margin * 2))}px", :height => "#{self.height - (@title_margin + @menu_margin + @resize_margin)}px"}, :states => {:"default-background-color" => true}}
                interior_component[:script] = ""
                interior_component[:content] = []
                interior_component_uuid = interior_component.uuid()
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
                left_resizer = ::GxG::Database::DetachedHash.new
                left_resizer[:component] = "org.gxg.gui.block.table.cell"
                left_resizer[:settings] = {}
                left_resizer[:options] = {:style => {:width => "2px", :cursor => "w-resize"}}
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
                left_resizer[:content] = []
                #
                right_resizer = ::GxG::Database::DetachedHash.new
                right_resizer[:component] = "org.gxg.gui.block.table.cell"
                right_resizer[:settings] = {}
                right_resizer[:options] = {:style => {:width => "2px", :cursor => "e-resize"}}
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
                right_resizer[:content] = []
                #
                bottom_resizer = ::GxG::Database::DetachedHash.new
                bottom_resizer[:component] = "org.gxg.gui.block.table.cell"
                bottom_resizer[:settings] = {}
                bottom_resizer[:options] = {:style => {:height => "2px", :cursor => "s-resize"}}
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
                bottom_resizer[:content] = []
                #
                sw_resizer = ::GxG::Database::DetachedHash.new
                sw_resizer[:component] = "org.gxg.gui.block.table.cell"
                sw_resizer[:settings] = {}
                sw_resizer[:options] = {:style => {:width => "2px", :height => "2px", :cursor => "sw-resize"}}
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
                sw_resizer[:content] = []
                #
                se_resizer = ::GxG::Database::DetachedHash.new
                se_resizer[:component] = "org.gxg.gui.block.table.cell"
                se_resizer[:settings] = {}
                se_resizer[:options] = {:style => {:width => "2px", :height => "2px", :cursor => "se-resize"}}
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
                se_resizer[:content] = []
                #
                left_menu_resize = ::GxG::Database::DetachedHash.new
                left_menu_resize[:component] = "org.gxg.gui.block.table.cell"
                left_menu_resize[:settings] = {}
                left_menu_resize[:options] = {:style => {:width => "2px", :cursor => "w-resize"}}
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
                left_menu_resize[:content] = []
                #
                right_menu_resize = ::GxG::Database::DetachedHash.new
                right_menu_resize[:component] = "org.gxg.gui.block.table.cell"
                right_menu_resize[:settings] = {}
                right_menu_resize[:options] = {:style => {:width => "2px", :cursor => "e-resize"}}
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
                right_menu_resize[:content] = []
                #
                menu_cell = ::GxG::Database::DetachedHash.new
                menu_cell.title = "menu_area #{@uuid.to_s}"
                menu_cell[:component] = "org.gxg.gui.block.table.cell"
                menu_cell[:settings] = {}
                menu_cell[:options] = {:style => {:overflow => "hidden", :height=>"16px",:padding => "0px", :margin => "0px"}}
                menu_cell[:script] = ""
                menu_cell[:content] = []
                #
                menu_row = ::GxG::Database::DetachedHash.new
                menu_row.title = "menu_area_row #{@uuid.to_s}"
                menu_row[:component] = "org.gxg.gui.block.table.row"
                menu_row[:settings] = {}
                menu_row[:options] = {:style => {:overflow => "hidden", :clear => "both", :padding => "0px", :width => "100%", :height=>"16px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent", :"border-bottom" => "1px solid #c2c2c2"}}
                menu_row[:script] = ""
                menu_row[:content] = [(left_menu_resize),(menu_cell),(right_menu_resize)]
                #
                content_area = ::GxG::Database::DetachedHash.new
                content_area.title = "content_area #{@uuid.to_s}"
                content_area[:component] = "org.gxg.gui.block.table.cell"
                content_area[:settings] = {}
                content_area[:options] = {:style => {:padding => "0px", :margin => "0px", :border => "0px"}}
                content_area[:script] = ""
                content_area[:content] = [(interior_component)]
                #
                row_one = ::GxG::Database::DetachedHash.new
                row_one[:component] = "org.gxg.gui.block.table.row"
                row_one[:settings] = {}
                row_one[:options] = {}
                row_one[:script] = ""
                row_one[:content] = []
                #
                row_two = ::GxG::Database::DetachedHash.new
                row_two[:component] = "org.gxg.gui.block.table.row"
                row_two[:settings] = {}
                row_two[:options] = {}
                row_two[:script] = ""
                row_two[:content] = []
                #
                resizing_areas = ::GxG::Database::DetachedHash.new
                resizing_areas.title = "window_body #{@uuid.to_s}"
                resizing_areas[:component] = "org.gxg.gui.block.table"
                resizing_areas[:settings] = {}
                resizing_areas[:options] = {:style => {:width => "100%"}, :states => {:"default-background-color" => true}}
                resizing_areas[:script] = ""
                resizing_areas[:content] = []
                #
                # link pieces
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
                @content = nil
                page.build_components(self,build_list, {:application => @application})
                # self.build_interior_components(build_list)
                #
                the_object = page.find_object_by(interior_component_uuid)
                if the_object
                    @content = the_object
                end
                # 
                the_object = page.find_object_by("window_body #{@uuid.to_s}")
                if the_object
                    @window_body = the_object
                end
                #
                the_object = page.find_object_by("title_object #{@uuid.to_s}")
                if the_object
                    @title_object = the_object
                end
                #
                the_object = page.find_object_by("menu_area #{@uuid.to_s}")
                if the_object
                    @menu_area = the_object
                    @menu_margin = (`#{@menu_area.element}.getBoundingClientRect().bottom - #{@menu_area.element}.getBoundingClientRect().top`.to_i)
                    # border-collapse: collapse
                    if @menu_area
                        @menu_area.parent.parent.gxg_merge_style({:"border-collapse" => "collapse"})
                    end
                end
                GxG::DISPATCHER.post_event do
                    self.commit_settings
                end
                self
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.window", ::GxG::Gui::Window)
        #
        class DialogBox < ::GxG::Gui::Vdom::BaseElement
            #
            def _before_create
                super()
            end
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
            alias :application= :set_application
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
            alias :window_title= :set_window_title
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
            alias :data= :set_data
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
            alias :responder= :set_responder
            #
            def respond(data=nil)
                page.dialog_close()
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
            def initialize(the_parent, the_options, other_data={})
                # FIXME: work around for strange bug in layout_refresh
                # ::GxG::DISPLAY_DETAILS[:object].layout_refresh
                # bounds = GxG::DISPLAY_DETAILS[:object].layout_content_area()
                #
                @special_state = nil
                @content = nil
                # So, at this point I've decided to use pixels internally, but percentages externally. (interface)
                # You can pass Integer (as Pixels), Float, or String Percentage
                the_width = nil
                if the_options[:width].is_a?(::String) || the_options[:width].to_s.include?(".")
                    if the_options[:width].is_a?(::String)
                        the_width = ((`window.innerWidth`.to_f) * (the_options[:width].gsub("%","").to_f / 100.0))
                    else
                        the_width = ((`window.innerWidth`.to_f) * (the_options[:width] / 100.0))
                    end
                else
                    if the_options[:width].is_a?(::Numeric)
                        the_width = the_options[:width].to_f
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
                        the_height = ((`window.innerHeight`.to_f) * (the_options[:height].gsub("%","").to_f / 100.0))
                    else
                        the_height = ((`window.innerHeight`.to_f) * (the_options[:height] / 100.0))
                    end
                else
                    if the_options[:height].is_a?(::Numeric)
                        the_height = the_options[:height].to_f
                    end
                end
                if the_height
                    @top = ((`window.innerHeight`.to_f / 2.0) - (the_height / 2.0))
                    @bottom = ((`window.innerHeight`.to_f / 2.0) + (the_height / 2.0))
                end
                #
                if the_options[:top].is_a?(::String) || the_options[:top].to_s.include?(".")
                    if the_options[:top].is_a?(::String)
                        @top = (`window.innerHeight`.to_f * (the_options[:top].gsub("%","").to_f / 100.0))
                    else
                        @top = (`window.innerHeight`.to_f * (the_options[:top] / 100.0))
                    end
                else
                    unless the_height
                        @top = (the_options[:top] || ((`window.innerHeight`.to_i / 2) - 150))
                    end
                end
                if the_options[:left].is_a?(::String) || the_options[:left].to_s.include?(".")
                    if the_options[:left].is_a?(::String)
                        @left = (`window.innerWidth`.to_f * (the_options[:left].gsub("%","").to_f / 100.0))
                    else
                        @left = (`window.innerWidth`.to_f * (the_options[:left] / 100.0))
                    end
                else
                    unless the_width
                        @left = (the_options[:left] || ((`window.innerWidth`.to_i / 2) - 300))
                    end
                end
                if the_options[:right].is_a?(::String) || the_options[:right].to_s.include?(".")
                    if the_options[:right].is_a?(::String)
                        @right = (`window.innerWidth`.to_f * (the_options[:right].gsub("%","").to_f / 100.0))
                    else
                        @right = (`window.innerWidth`.to_f * (the_options[:right] / 100.0))
                    end
                else
                    unless the_width
                        @right = (the_options[:right] || ((`window.innerWidth`.to_i / 2) + 300))
                    end
                end
                if the_options[:bottom].is_a?(::String) || the_options[:bottom].to_s.include?(".")
                    if the_options[:bottom].is_a?(::String)
                        @bottom = (`window.innerHeight`.to_f * (the_options[:bottom].gsub("%","").to_f / 100.0))
                    else
                        @bottom = (`window.innerHeight`.to_f * (the_options[:bottom] / 100.0))
                    end
                else
                    unless the_height
                        @bottom = (the_options[:bottom] || ((`window.innerHeight`.to_i / 2) + 150))
                    end
                end
                #
                @window_title = the_options[:window_title] || "Untitled"
                @title_object = nil
                #
                @opacity = (the_options[:opacity] || 0.8)
                @background_color = (the_options[:"background-color"] || "rgba(0,0,0,#{@opacity.to_s})")
                @layer = 2000
                #
                @tracking = {}
                @responder = nil
                @data = {}
                #
                super(the_parent, the_options,other_data)
                #
                self.set_attribute(:draggable,false)
                #
                self
            end
            # Slight of hand:
            alias :original_add_child :add_child
            def add_child(component_record)
                if @content
                    @content.add_child(component_record)
                else
                    original_add_child(component_record)
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
                self.merge_style({:position => "absolute", :top => "0px", :left => "0px", :width => "100%", :height => "100%", :"background-color" => @background_color, :"z-index" => @layer})
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
                modal_frame = ::GxG::Database::DetachedHash.new
                modal_frame.title = "modal_frame #{@uuid.to_s}"
                modal_frame[:component] = "org.gxg.gui.block.table"
                modal_frame[:settings] = {}
                modal_frame[:options] = {:style => {:opacity => 1.0, :clear => "both", :overflow => "hidden", :position => "absolute", :top => "#{@top}px", :left => "#{@left}px", :width => "#{self.width}px", :height=>"#{self.height}px", :padding => "0px", :margin => "0px", :"border-radius" => "5px 5px 5px 5px", :"z-index" => (@layer + 100)}, :states => {:"default-background-color" => true}}
                modal_frame[:script] = ""
                modal_frame[:content] = []
                #
                the_title = ::GxG::Database::DetachedHash.new
                the_title.title = "title #{@uuid.to_s}"
                the_title[:component] = "org.gxg.gui.label"
                the_title[:settings] = {}
                the_title[:options] = {:content => @window_title, :style => {:opacity => 1.0, :width => "100%", :"font-size" => "16px", :"text-align" => "center"}}
                the_title[:script] = ""
                the_title[:content] = []
                #
                title_cell = ::GxG::Database::DetachedHash.new
                title_cell[:component] = "org.gxg.gui.block.table.cell"
                title_cell[:settings] = {}
                title_cell[:options] = {:style => {:opacity => 1.0, :width => "100%", :padding => "0px 0px 0px #{((self.width() / 2) - ((@window_title.size / 2) * 8))}px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "transparent"}}
                title_cell[:script] = ""
                title_cell[:content] = [(the_title)]
                #
                title_row = ::GxG::Database::DetachedHash.new
                title_row[:component] = "org.gxg.gui.block.table.row"
                title_row[:settings] = {}
                title_row[:options] = {:style => {:opacity => 1.0, :clear => "both", :padding => "0px", :width => "100%", :height=>"24px", :margin => "0px", :"vertical-align" => "middle", :"background-color" => "#ffffff", :"border-bottom" => "1px solid #c2c2c2"}}
                title_row[:script] = ""
                title_row[:content] = [(title_cell)]
                #
                interior_component = ::GxG::Database::DetachedHash.new
                interior_component.title = "content #{@uuid.to_s}"
                interior_component[:component] = "org.gxg.gui.block.table.cell"
                interior_component[:settings] = {}
                interior_component[:options] = {:style => {:opacity => 1.0, :clear => "both", :padding => "0px", :margin => "0px", :border => "0px", :width => "#{self.width}px", :height => "#{self.height}px"}, :states => {:"default-background-color" => true}}
                interior_component[:script] = ""
                interior_component[:content] = []
                #
                content_row = ::GxG::Database::DetachedHash.new
                content_row[:component] = "org.gxg.gui.block.table.row"
                content_row[:settings] = {}
                content_row[:options] = {:style => {:opacity => 1.0, :width => "#{self.width}px", :height => "#{self.height - 24}px", :padding => "0px", :margin => "0px", :border => "0px"}}
                content_row[:script] = ""
                content_row[:content] = [(interior_component)]
                #
                modal_frame[:content] = [(title_row),(content_row)]
                #
                build_list << modal_frame
                #
                @content = nil
                page.build_components(self,build_list)
                #
                the_object = page.find_object_by("content #{@uuid.to_s}")
                if the_object
                    @content = the_object
                end
                #
                the_object = page.find_object_by("title #{@uuid.to_s}")
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
        ::GxG::Gui::register_component_class(:"org.gxg.gui.window.dialog", ::GxG::Gui::DialogBox)
        #
        # ### Page supports
        module Vdom
            class Page
                def window_open(build_source=nil, the_application=nil)
                    if build_source.is_a?(GxG::Database::DetachedHash)
                        self.build_components(self, [(build_source)], {:application => the_application})
                        new_window = self.find_object_by(build_source.uuid)
                        #
                        if new_window
                            if new_window.menu_reference()
                                the_menu_source = the_application.search_content(new_window.menu_reference())
                                if the_menu_source.is_a?(GxG::Database::DetachedHash)
                                    new_window.set_menu(the_menu_source)
                                else
                                    log_warn("Invalid Menu Resource referenced: #{new_window.menu_reference().inspect}")
                                end
                            end
                            #
                            self.window_register(new_window.uuid, new_window)
                            new_window.before_open
                            new_window.open
                            new_window.show
                            new_window.after_open
                            true
                        else
                            log_warn("Unable to locate newly created window object.")
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
                            if registration[:window].application()
                                registration[:window].application.unlink_window(the_reference)
                                registration[:window].set_application(nil)
                            end
                            self.window_unregister(the_reference)
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
                def dialog_open(build_source=nil, the_application=nil, details=nil, &block)
                    if build_source.is_a?(::GxG::Database::DetachedHash)
                        if @dialog.is_a?(::GxG::Gui::DialogBox)
                            @dialog_queue << {:source => build_source, :application => the_application, :details => details, :responder => block}
                            true
                        else
                            page.build_components(self,[(build_source)],{:application => the_application})
                            new_window = page.find_object_by(build_source.uuid)
                            if new_window
                                new_window.set_title(build_source.title)
                                if the_application.is_a?(::GxG::Application)
                                    new_window.set_application(the_application)
                                    unless the_application.get_window(build_source.uuid)
                                        the_application.link_window(new_window)
                                    end
                                end
                                # Set details if provided
                                if details
                                    new_window.set_data(details)
                                end
                                if block.respond_to?(:call)
                                    new_window.set_responder(block)
                                end
                                new_window.before_open()
                                new_window.open()
                                new_window.show({:origin => {:opacity => 0.0}, :destination => {:opacity => 1.0}})
                                new_window.after_open()
                                true
                            else
                                false
                            end
                        end
                    end
                end
                #
                def dialog_close(options={})
                    if @dialog.is_a?(::GxG::Gui::DialogBox)
                        @dialog.before_close()
                        close_procedure = Proc.new do
                            @dialog.close()
                            @dialog.after_close()
                            @dialog.every_child do |the_child|
                                if the_child.is_a?(::GxG::Gui::ApplicationViewport)
                                    the_application = the_child.application
                                    if the_application
                                        the_application.unlink_viewport(the_child.title)
                                    end
                                end
                            end
                            @dialog.destroy
                            @dialog = nil
                            if @dialog_queue.size > 0
                                entry = @dialog_queue.shift
                                page.dialog_open(entry[:source], entry[:application], entry[:details], &entry[:responder])
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
                #
                # ### Window Layering & Effects
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
                # ### Window Registry
                def get_window_registration(the_reference=nil)
                    if the_reference.is_any?(::String, ::Symbol)
                        # {:window => nil, :layer => 0, :restore => nil}
                        @window_registry[(the_reference)]
                    else
                        nil
                    end
                end
                #
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
                # ### Window Switcher Supports
                def set_window_switcher(the_switcher=nil)
                    if the_switcher
                        @window_switcher = the_switcher
                    end
                end
                #
                def get_window_switcher()
                    @window_switcher
                end
                #
            end
        end
    end
end