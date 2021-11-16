module GxG
    module Gui
        #
        # Layout System Supports:
        def self.layout_refresh()
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
                ::GxG::LAYOUT[(the_position)].each_pair do |the_uuid,the_record|
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
                        ::GxG::LAYOUT[(the_position.to_s.to_sym)][(the_uuid.to_s.to_sym)] = percentages
                    end
                end
            end
            #
            [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].each do |the_position|
                ::GxG::LAYOUT[(the_position)].values.each do |the_record|
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
            #
            ::GxG::LAYOUT_LIMITS[:page_width] = page_width.to_i
            ::GxG::LAYOUT_LIMITS[:page_height] = page_height.to_i
            ::GxG::LAYOUT_LIMITS[:top] = (top_bound * page_height.to_f).to_i
            ::GxG::LAYOUT_LIMITS[:top_percent] = top_bound * 100.0
            ::GxG::LAYOUT_LIMITS[:left] = (left_bound * page_width.to_f).to_i
            ::GxG::LAYOUT_LIMITS[:left_percent] = left_bound * 100.0
            ::GxG::LAYOUT_LIMITS[:right] = (right_bound * page_width.to_f).to_i
            ::GxG::LAYOUT_LIMITS[:right_percent] = right_bound * 100.0
            ::GxG::LAYOUT_LIMITS[:bottom] = (bottom_bound * page_height.to_f).to_i
            ::GxG::LAYOUT_LIMITS[:bottom_percent] = bottom_bound * 100.0
            true
        end
        #
        def self.layout_add_item(the_uuid=nil, the_position=nil, refresh=true)
            # store by uuid in position's record
            if [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].include?(the_position.to_s.to_sym)
                #
                ::GxG::LAYOUT[(the_position.to_s.to_sym)][(the_uuid.to_s.to_sym)] = {:top => 0.0, :left => 0.0, :right => 0.0, :bottom => 0.0}
                if refresh
                    ::GxG::Gui::layout_refresh
                end
                #
                true
            else
                false
            end
        end
        #
        def self.layout_remove_item(the_uuid=nil)
            [:"top-left", :top, :"top-right", :right, :"bottom-right", :bottom, :"bottom-left", :left].each do |the_position|
                if ::GxG::LAYOUT[(the_position.to_s.to_sym)][(the_uuid.to_s.to_sym)]
                    ::GxG::LAYOUT[(the_position.to_s.to_sym)].delete((the_uuid.to_s.to_sym))
                    break
                end
            end
            ::GxG::Gui::layout_refresh
            #
            true
        end
        #
        def layout_content_area()
            ::GxG::LAYOUT_LIMITS
        end
        #
    end
end