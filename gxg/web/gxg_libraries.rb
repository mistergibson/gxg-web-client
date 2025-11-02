# backtick_javascript: true
# ----------------------------------------------------------------------------------------------------
# Provided Module Space for libraries to declare their :global within.
module Libraries
end
# ----------------------------------------------------------------------------------------------------
module GxG
    class Library
        #
        def initialize(the_definition=nil)
            unless the_definition.is_a?(GxG::Database::PersistedHash)
                raise ArgumentError, "You MUST provide a persisted source object."
            end
            #
            @uuid = the_definition.uuid
            @title = the_definition.title
            @version = the_definition.version
            @type = (the_definition[:type] || "text/javascript").to_s
            #
            load_list = []
            if the_definition[:requirements].is_a?(::GxG::Database::PersistedArray)
                the_definition[:requirements].each do |the_requirement|
                    unless GxG::DISPLAY_DETAILS[:object].library_loaded?(the_requirement)
                        load_list << the_requirement
                    end
                end
            end
            GxG::DISPLAY_DETAILS[:object].load_libraries(load_list) do |all_loaded|
            	if all_loaded == true
            		#
            		@src = the_definition[:options][:src].to_s
            		unless @src.size > 0
                		@src = nil
            		end
                    @charset = (the_definition[:options][:charset] || "utf-8").to_s
            		@local = the_definition[:options][:local]
                    unless @local
                        @local = false
                    end
            		@global = the_definition[:options][:global].to_s
                    unless @global.size > 0
                        @global = nil
                    end
                    # Load native code portion if supplied.
                    # If the global is already defined, your wrapper code will still work.
                    unless self.loaded?()
                        unless @global.to_s.size > 0
                            if @type = "text/javascript"
                                @global = "Opal"
                            else
                                @global = "GxG"
                            end
                        end
                        if @src.is_a?(::String)
                            the_uuid = @uuid
                            the_type = @type
                            the_charset = @charset
                            the_src = @src
                            %x{
                                var the_element = document.createElement('script');
                                the_element.id = the_uuid;
                                the_element.type = the_type;
                                the_element.charset = the_charset;
                                the_element.src = the_src;
                                document.body.appendChild(the_element);
                            }
                        else
                            the_script = the_definition[:options][:native].to_s
                            if the_script.is_a?(::String)
                                if the_script.size > 0
                                    if the_script.base64?
                                        the_script = the_script.to_s.decode64
                                    end
                                    the_uuid = @uuid
                                    the_type = @type
                                    the_charset = @charset
                                    %x{
                                        var the_element = document.createElement('script');
                                        the_element.id = the_uuid;
                                        the_element.type = the_type;
                                        the_element.charset = the_charset;
                                        the_element.innerHTML = the_script;
                                        document.body.appendChild(the_element);
                                    }
                                end
                            end
                        end
                    end
                    @source = the_definition
                    self.set_script(@source[:script].to_s)
                    @source = nil
            	else
            		raise Exception, "Library load error - skipping library intitialization: #{@title}"
            	end
            end
            #
            self
        end
        #
        def uuid
            @uuid
        end
        #
        def title
            @title
        end
        #
        def version()
            @version
        end
        #
        def type()
        	@type
        end
        #
        def local()
            @local
        end
        #
        def global()
            @global
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
                    if @local == true
                        instance_eval(the_script_body)
                    else
                        eval(the_script_body)
                    end
                    result = true
                rescue Exception => the_error
                    log_error({:error => the_error, :parameters => {:script => the_script_body}})
                end
            end
            result
        end
        #
        def require_resource(the_reference=nil)
            # call self.require_resource("script-name") to load content.script-name
            result = false
            if @source
            	# content source record format: {:component => "script", :type => "text/ruby", :script => ""}
            	@source[:content].each do |the_script|
            		if (the_script.title == the_reference || the_script.uuid == the_refrence.to_s.to_sym) && the_script[:component].to_s == "script" && the_script[:type].to_s == "text/ruby"
            			self.set_script(the_script[:script].to_s)
            			result = true
            			break
            		end
            	end
            end
            result
        end
        #
        def require_module_resource(the_reference=nil)
            # call self.require_module_resource("script-name") to load content.script-name
            result = false
            if @source
            	# content source record format: {:component => "script", :type => "text/ruby", :script => ""}
            	@source[:content].each do |the_script|
            		if (the_script.title == the_reference || the_script.uuid == the_refrence.to_s.to_sym) && the_script[:component].to_s == "script" && the_script[:type].to_s == "text/ruby"
                        if the_script[:script].size > 0
                            if the_script[:script].base64?
                                eval(the_script[:script].to_s.decode64)
                            else
                                eval(the_script[:script].to_s)
                            end
            				result = true
                            break
                        end
            		end
            	end
            end
            result
        end
        #
        def loaded?
            # Opal/JS Note: by saying `!!<js-value>` it will coerse it into a ruby boolean.
            if @type == "text/javascript"
                if (`(window.hasOwnProperty(#{@global.to_s}))`)
                    true
                else
                    false
                end
            else
                if @global
                    if (eval("defined? #{@global.to_s}"))
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
        end
    end
    #
end