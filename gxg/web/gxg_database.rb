#
module GxG
    module Database
        def self.element_tables()
          {
          :unspecified => nil,
          :element_boolean => [::TrueClass, ::FalseClass, ::NilClass],
          :element_integer => [::Integer],
          :element_float => [::Float],
          :element_bigdecimal => [::BigDecimal],
          :element_datetime => [::Time],
          :element_text => [::String],
          :element_binary => [::GxG::ByteArray],
          :element_array => [::Array],
          :element_hash => [::Hash]
          }
        end
        #
        def self.valid_field_classes()
          [::TrueClass, ::FalseClass, ::NilClass, ::Integer, ::Float, ::BigDecimal, ::Time, ::String, ::GxG::ByteArray]
        end
        #
        def self.element_table_index(the_key=:unspecified)
          (::GxG::Database::element_tables().keys.index(the_key.to_sym) || 0)
        end
        #
        def self.element_table_by_index(the_index=0)
          (::GxG::Database::element_tables().keys[(the_index)] || :unspecified)
        end
        #
        def self.element_table_for_instance(the_instance=nil)
          result = :unspecified
          #
          table = ::GxG::Database::element_tables()
          table.keys.each do |the_key| 
            unless the_key == :unspecified
              if the_instance.is_any?(table[(the_key)])
                result = the_key
                break
              end
            end
          end
          #
          result
        end
        #
        def self.persistable?(the_object)
          result = true
          unless the_object.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
            if the_object.is_any?(::Hash, ::Array)
              the_object.search do |item, selector, container|
                if result
                  if ::GxG::Database::element_table_for_instance(item) == :unspecified
                    result = false
                    break
                  end
                end
                nil
              end
            else
              if ::GxG::Database::element_table_for_instance(the_object) == :unspecified
                result = false
              end
            end
          end
          result
        end
        #
        def self.iterative_detached_persist(old_root=nil)
          # New DetachedArray, or DetachedHash interface:
          # 
          result = nil
          begin
            # db open?
            # write permissions on db?
            unless old_root.is_any?(::Array, ::Hash)
              raise ArgumentError, "You MUST provide either an Array or a Hash."
            end
            unless GxG::Database::persistable?(old_root)
              raise ArgumentError, "The object you are attempting to persist contains a non-persistable item."
            end
            #
            if old_root.is_a?(::Array)
              original_partner = ::GxG::Database::DetachedArray.new()
              #
            end
            if old_root.is_a?(::Hash)
              original_partner = ::GxG::Database::DetachedHash.new()
            end
            #
            paring_data = [{:parent => nil, :parent_selector => nil, :object => old_root, :partner => original_partner}]
            children_of = Proc.new do |the_parent=nil|
              list = []
              paring_data.each do |node|
                if node[:parent].object_id == the_parent.object_id
                  list << node
                end
              end
              list
            end
            #
            parent_of = Proc.new do |the_parent=nil|
              output = nil
              paring_data.each do |entry|
                if entry[:object].object_id == the_parent.object_id
                  output = entry
                end
              end
              output
            end
            find_partner = Proc.new do |the_object|
              found_partner = nil
              paring_data.each do |the_record|
                if the_record.is_a?(::Hash)
                  if the_record[:object].object_id == the_object.object_id
                    found_partner = the_record[:partner]
                    break
                  end
                end
              end
              found_partner
            end
            # build paring data:
            delegate_permission = nil
            old_root.search do |the_value, the_selector, the_container|
              if the_value.is_a?(::Array)
                paring_data << {:parent => the_container, :parent_selector => the_selector, :object => the_value, :partner => ::GxG::Database::DetachedArray.new()}
              else
                if the_value.is_a?(::Hash)
                  paring_data << {:parent => the_container, :parent_selector => the_selector, :object => the_value, :partner => ::GxG::Database::DetachedHash.new()}
                else
                  paring_data << {:parent => the_container, :parent_selector => the_selector, :object => the_value, :partner => the_value}
                end
              end
            end
            #
            # Assign objects to structure in order by parent / parent_selector
            link_db = [(paring_data[0])]
            while link_db.size > 0
              entry = link_db.shift
              if entry.is_a?(::Hash)
                if entry[:object].is_any?(::Array, ::Hash)
                  # get children and assign
                  children = children_of.call(entry[:object])
                  children.each do |child|
                    entry[:partner][(child[:parent_selector])] = child[:partner]
                    if child[:partner].is_any?(::GxG::Database::DetachedArray, ::GxG::Database::DetachedHash)
                      link_db << child
                    end
                  end
                end
              end
            end
            result = original_partner
          rescue Exception => the_error
            log_error({:error => the_error, :parameters => {:object => old_root}})
          end
          result
        end
        #
        #
        # Format support:
        def self.detached_format_find(the_criteria={})
          result = nil
          tests = {}
          [:uuid, :ufs, :title, :version].each do |the_key|
            if the_criteria[(the_key)]
              tests[(the_key)] = the_criteria[(the_key)]
            end
          end
          GxG::DB[:formats].each_pair do |uuid,record|
            score = 0
            tests.keys.each do |the_test|
              if record[(the_test)] == tests[(the_test)]
                score += 1
              end
            end
            if tests.keys.size == score
              result = record
              break
            end
          end
          result
        end
        #
        def self.detached_format_load(the_criteria={}, &block)
          # If already loaded and block provided: return an Array of format records.
          # Load any missing formats from server, and call block if provided.
          # Note: results are in NO particular order (DO NOT INDEX into the result set from source criteria)
          success = false
          needed = []
          results = []
          if the_criteria.is_a?(::Hash)
            loaded = ::GxG::Database::detached_format_find(the_criteria)
            if loaded
              results << loaded
              if block.respond_to?(:call)
                block.call(results)
              end
              success = true
            else
              needed << the_criteria
            end
          else
            if the_criteria.is_a?(::Array)
              the_criteria.each do |the_specifier|
                loaded = ::GxG::Database::detached_format_find(the_specifier)
                if loaded
                  results << loaded
                else
                  needed << the_specifier
                end
              end
            end
          end
          if needed.size > 0
            GxG::CONNECTION.format_pull(needed) do |response|
              if response.is_a?(::Hash)
                if response[:result].is_a?(::Array)
                  response[:result].each do |format_record|
                    GxG::DB[:formats][(format_record[:uuid].to_sym)] = format_record
                    results << format_record
                  end
                  if block.respond_to?(:call)
                    block.call(results)
                  end
                  success = true
                end
              end
            end
          else
            if results.size > 0
              if block.respond_to?(:call)
                block.call(results)
              end
              success = true
            end
          end
          #
          success
        end
        #
        def self.process_detached_import(import_manifest=nil)
            result = []
            if import_manifest.is_a?(::Hash)
                if import_manifest[:formats].size > 0
                    # import formats: GxG::DB[:formats]
                    import_manifest[:formats].keys.each do |the_key|
                        unless GxG::DB[:formats][(the_key)]
                          # Review do ::Hash.gxg_import on format content
                          format_record = import_manifest[:formats][(the_key)]
                          if format_record[:version].is_a?(::String)
                            format_record[:version] = BigDecimal(format_record[:version].to_s)
                          end
                          format_record[:content] = ::Hash.gxg_import(format_record[:content])
                          GxG::DB[:formats][(the_key)] = format_record
                        end
                    end
                end
                #
                if import_manifest[:records].size > 1
                  import_manifest[:records].each do |the_record|
                    result << GxG::Database::DetachedHash::import(the_record)
                  end
                else
                  result << GxG::Database::DetachedHash::import(import_manifest[:records][0])
                end
            end
            result
        end
        #
        def self.process_import(import_manifest=nil)
          result = []
          if import_manifest.is_a?(::Hash)
              if import_manifest[:formats].size > 0
                  # import formats: GxG::DB[:formats]
                  import_manifest[:formats].keys.each do |the_key|
                      unless GxG::DB[:formats][(the_key)]
                        # Review do ::Hash.gxg_import on format content
                        format_record = import_manifest[:formats][(the_key)]
                        if format_record[:version].is_a?(::String)
                          format_record[:version] = BigDecimal(format_record[:version].to_s)
                        end
                        format_record[:content] = ::Hash.gxg_import(format_record[:content])
                        GxG::DB[:formats][(the_key)] = format_record
                      end
                  end
              end
              #
              if import_manifest[:records].size > 1
                import_manifest[:records].each do |the_record|
                  result << GxG::Database::PersistedHash::import(the_record)
                end
              else
                result << GxG::Database::PersistedHash::import(import_manifest[:records][0])
              end
          end
          result
      end
      #
      class DetachedHash
        #
        public
        #
        def uuid()
            @uuid.clone
        end
        #
        def uuid=(the_uuid=nil)
          if GxG::valid_uuid?(the_uuid)
            @uuid = the_uuid.to_s.to_sym
          end
        end
        #
        def title()
            @title.clone
        end
        #
        def title=(the_title=nil)
          if the_title
            @title = the_title.to_s[0..255]
            self.increment_version
          end
        end
        #
        def version()
          @version.clone
        end
        #
        def version=(the_version=nil)
          if the_version.is_a?(::Numeric)
            @version = the_version.to_s("F").to_d
          end
        end
        #
        def element_version(key=nil)
          result = 0.0
          if key.is_a?(::Symbol)
            if key.to_s.size > 256
              log_warn({:warning => "Attempted oversized key usage (limited to 256 characters), truncated #{key.inspect} to #{key.to_s[(0..255)].to_sym.inspect}"})
              key = key.to_s[(0..255)].to_sym
            end
            #
            if @property_links[(key.to_s.to_sym)]
              result = @property_links[(key.to_s.to_sym)][:record][:version]
            else
              result = 0.0
            end
            #
          end
          result
        end
        #
        def set_element_version(element_key, the_version=nil)
          result = false
          if @property_links[(element_key)]
            if the_version.is_a?(::Numeric)
              @property_links[(element_key)][:record][:version] = (((the_version.to_f) * 10000.0).to_i.to_f / 10000.0)
              result = true
            else
              log_warning("Attempted to set version to an invalid version value #{the_version.inspect} for #{element_key.inspect} on Object #{@uuid.inspect}")
            end
          else
            log_warning("Attempted to set version with an invalid key #{element_key.inspect} on Object #{@uuid.inspect}")
          end
          result
        end
        #
        def format()
          @format.clone
        end
        #
        def format=(the_format=nil)
          if GxG::valid_uuid?(the_format)
            @format = the_format.to_s.to_sym
          end
        end
        #
        def parent()
            @parent
        end
        #
        def parent=(object=nil)
          if object.is_any?([::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray])
            # Review : parent can only be set once -- is this best??
            unless @parent
              @parent = object
            end
          end
        end
        #
        def write_reserved?()
          true
        end
        #
        def release_reservation()
          true
        end
        #
        def get_reservation()
          true
        end
        #
        def wait_for_reservation(timeout=nil)
          true
        end
        # ### Review: move to Database class as generic toolbox method at some point:
        #
        def self.import(import_record=nil)
          result = nil
          unless import_record.is_any?(::Hash, ::GxG::Database::DetachedHash)
              raise Exception, "Malformed import record passed."
          end
          # {:type => :element_hash, :uuid => @uuid.clone, :title => @title.clone, :version => @version.clone, :format => @format.clone, :content => {}}
          import_db = [{:target => ::GxG::Database::DetachedHash.new, :record => import_record}]
          result =  import_db[0][:target]
          while import_db.size > 0 do
              entry = import_db.shift
              case entry[:record][:type].to_s.to_sym
              when :element_hash
                  entry[:target].uuid = entry[:record][:uuid].to_s.to_sym
                  entry[:target].title = entry[:record][:title].to_s
                    entry[:record][:content].keys.each do |the_key|
                        case entry[:record][:content][(the_key)][:type].to_s.to_sym
                        when :element_hash
                            new_target = GxG::Database::DetachedHash.new
                            entry[:target][(the_key)] = new_target
                            import_db << {:target => new_target, :record => (entry[:record][:content][(the_key)])}
                            entry[:target][(the_key)].parent = (entry[:target])
                        when :element_array
                            new_target = GxG::Database::DetachedArray.new
                            entry[:target][(the_key)] = new_target
                            import_db << {:target => new_target, :record => (entry[:record][:content][(the_key)])}
                            entry[:target][(the_key)].parent = (entry[:target])
                        when :element_boolean, :element_integer, :element_float, :element_text
                            entry[:target][(the_key)] = entry[:record][:content][(the_key)][:content]
                        when :element_bigdecimal
                            entry[:target][(the_key)] = BigDecimal(entry[:record][:content][(the_key)][:content].to_s)
                        when :element_datetime
                          entry[:target][(the_key)] = ::Chronic::parse(entry[:record][:content][(the_key)][:content].to_s)
                        when :element_binary
                          entry[:target][(the_key)] = ::GxG::ByteArray.new(entry[:record][:content][(the_key)][:content].to_s.decode64)
                        end
                    end
                  entry[:target].version = BigDecimal(entry[:record][:version].to_s)
                  entry[:target].format = entry[:record][:format].to_s.to_sym
              when :element_array
                  entry[:target].uuid = entry[:record][:uuid].to_s.to_sym
                  entry[:target].title = entry[:record][:title].to_s
                    entry[:record][:content].each_index do |indexer|
                        case entry[:record][:content][(indexer)][:type].to_s.to_sym
                        when :element_hash
                            new_target = GxG::Database::DetachedHash.new
                            entry[:target][(indexer)] = new_target
                            import_db << {:target => new_target, :record => (entry[:record][:content][(indexer)])}
                            entry[:target][(indexer)].parent =(entry[:target])
                        when :element_array
                            new_target = GxG::Database::DetachedArray.new
                            entry[:target][(indexer)] = new_target
                            import_db << {:target => new_target, :record => (entry[:record][:content][(indexer)])}
                            entry[:target][(indexer)].parent = (entry[:target])
                        when :element_boolean, :element_integer, :element_float, :element_text
                            entry[:target][(indexer)] = entry[:record][:content][(indexer)][:content]
                        when :element_bigdecimal
                            entry[:target][(indexer)] = BigDecimal(entry[:record][:content][(indexer)][:content].to_s)
                        when :element_datetime
                          entry[:target][(indexer)] = ::Chronic::parse(entry[:record][:content][(indexer)][:content].to_s)
                        when :element_binary
                          entry[:target][(indexer)] = ::GxG::ByteArray.new(entry[:record][:content][(indexer)][:content].to_s.decode64)
                        end
                    end
                  entry[:target].version = BigDecimal(entry[:record][:version].to_s)
                  entry[:target].constraint = entry[:record][:constraint].to_s.to_sym
              end
          end
          #
          result
        end
        #
        def self.create_from_format(the_format=nil)
          # GxG::DB[:formats][(the_key)]
        end
        #
        def ufs()
          if @format
            record = GxG::DB[:formats][(@format.to_s.to_sym)]
            if record
              record[:ufs].to_s.to_sym
            else
              ""
            end
          else
            ""
          end
        end
        #
        def increment_version()
          @version += 0.0001
        end
        #
        def initialize()
          @uuid = ::GxG::uuid_generate().to_s.to_sym
          @title = "Untitled #{@uuid.to_s}"
          @version = BigDecimal("0.0")
          @format = nil
          @parent = nil
          @property_links = {}
          self
        end
        #
        def inspect()
          # FORNOW: make re-entrant (yes, I know!) Fortunately, circular links are impossible with DetachedHash.
          # TODO: make interative instead of re-entrant.
          last_key = @property_links.keys.last
          result = "{"
          @property_links.keys.each do |element_key|
            result = result + (":#{element_key.to_s} => " + @property_links[(element_key)][:content].inspect)
            # if @property_links[(element_key)][:loaded] == true
            #   result = result + (":#{element_key.to_s} => " + @property_links[(element_key)][:content].inspect)
            # else
            #   result = result + (":#{element_key.to_s} => (Not Loaded)")
            # end
            unless last_key == element_key
              result = result + ", "
            end
          end
          result = result + "}"
          result
        end
        #
        def alive?()
          true
        end
        #
        def save()
          result = false
          if self.alive?
            begin
              # Review : expand to save to server
              result = true
            rescue Exception => the_error
              log_error({:error => the_error})
            end
          end
          result
        end
        #
        def destroy()
          result = false
          if self.alive?
            begin
              # Review : expand to destroy on server the stored object in question.
              result = true
            rescue Exception => the_error
              log_error({:error => the_error})
            end
          end
          result
        end
        #
        def size()
          @property_links.size
        end
        #
        def keys()
          @property_links.keys
        end
        #
        def []=(key=nil, value=nil)
          # Only works with Symbols.
          unless self.alive?()
            raise Exception, "Attempted to alter a defunct structure"
          end
          result = nil
          if key.is_a?(::Symbol)
            if key.to_s.size > 256
              log_warn({:warning => "Attempted oversized key usage (limited to 256 characters), truncated #{key.inspect} to #{key.to_s[(0..255)].to_sym.inspect}"})
              key = key.to_s[(0..255)].to_sym
            end
            property_key = key.to_s.to_sym
            # Review : rewrite ????
            if value.is_any?(::NilClass, ::TrueClass, ::FalseClass, ::Integer, ::Float, ::BigDecimal, ::String, ::Time, ::GxG::ByteArray, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray, ::Hash, ::Array)
              unless self.write_reserved?()
                self.get_reservation()
              end
              if self.write_reserved?()
                # Further screen value provided:
                # ### Check provided DetachedHashes and DetachedArrays
                # ### Check provided Hashes and Arrays
                # ### Property Exists?
                if @property_links[(key.to_s.to_sym)]
                  # set property to value
                  operation = :set_value
                else
                  if @format
                    raise Exception, "Formatted - the structure cannot be altered"
                  else
                    # add property : value pair
                    operation = :add_value
                  end
                end
                # ### Prepare new value
                new_value = {
                  :linkid => nil,
                  :content => nil,
                  :loaded => true,
                  :state => 0,
                  :record => {
                    :parent_uuid => @uuid.to_s,
                    :property => key.to_s,
                    :ordinal => 0,
                    :version => BigDecimal("0.0"),
                    :element => "element_boolean",
                    :element_boolean => -1,
                    :element_integer => 0,
                    :element_float => 0.0,
                    :element_bigdecimal => BigDecimal("0.0"),
                    :element_datetime => ::Time.now,
                    :time_offset => 0.0,
                    :time_prior => 0.0,
                    :time_after => 0.0,
                    :length => 0,
                    :element_text => "",
                    :element_binary => nil,
                    :element_array => nil,
                    :element_hash => nil
                  }
                }
                #
                if value.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  # ### Assimilate DetachedHash or DetachedArray
                  new_value[:content] = value
                  new_value[:loaded] = true
                  new_value[:state] = new_value[:content].hash
                  # Note: version is sync'd here, but don't rely upon property version with linked structures, but use structure's version method.
                  new_value[:record][:version] = new_value[:content].version()
                  if value.is_a?(::GxG::Database::DetachedHash)
                    new_value[:record][:element] = "element_hash"
                    new_value[:record][:element_hash] = value
                  else
                    new_value[:record][:element] = "element_array"
                    new_value[:record][:element_array] = value
                  end
                else
                  # ### Persist Hashes and Arrays
                  if value.is_any?(::Hash, ::Array)
                    new_value[:content] = ::GxG::Database::iterative_detached_persist(value)
                    new_value[:loaded] = true
                    new_value[:state] = new_value[:content].hash
                    # Note: version is sync'd here, but don't rely upon property version with linked structures, but use structure's version method.
                    new_value[:record][:version] = new_value[:content].version()
                    if value.is_a?(::Hash)
                      new_value[:record][:element] = "element_hash"
                      new_value[:record][:element_hash] = new_value[:content]
                    else
                      new_value[:record][:element] = "element_array"
                      new_value[:record][:element_array] = new_value[:content]
                    end
                  else
                    # ### Persist Base Element Values
                    new_value[:record][:element] = ::GxG::Database::element_table_for_instance(value).to_s
                    case new_value[:record][:element]
                    when "element_boolean"
                      if value.class == ::NilClass
                        new_value[:record][:element_boolean] = -1
                        new_value[:content] = nil
                      end
                      if value.class == ::FalseClass
                        new_value[:record][:element_boolean] = 0
                        new_value[:content] = false
                      end
                      if value.class == ::TrueClass
                        new_value[:record][:element_boolean] = 1
                        new_value[:content] = true
                      end
                    when "element_integer"
                      new_value[:record][:element_integer] = value
                      new_value[:content] = value
                    when "element_float"
                      new_value[:record][:element_float] = value
                      new_value[:content] = value
                    when "element_bigdecimal"
                      new_value[:record][:element_bigdecimal] = BigDecimal(value.to_s)
                      new_value[:content] = new_value[:record][:element_bigdecimal]
                    when "element_datetime"
                      new_value[:record][:element_datetime] = value
                      new_value[:content] = value
                    when "element_text"
                      new_value[:record][:element_text] = value
                      new_value[:record][:length] = value.size
                      new_value[:content] = value
                    when "element_binary"
                      # Note: be sure to keep version & length sync'd with linked binary element record
                      if operation == :set_value
                        new_value[:record][:version] = @property_links[(property_key)][:record][:version]
                        new_value[:record][:element_binary] = @property_links[(property_key)][:record][:element_binary]
                      end
                      new_value[:record][:length] = value.size
                      new_value[:content] = value
                    else
                      raise Exception, "Unable to map an element type for value: #{value.inspect}"
                    end
                  end
                end
                # ### Commit Changes
                case operation
                when :set_value
                  # Note: Set In-memory value only, don't save unless you have to.
                  if new_value[:content].is_a?(@property_links[(property_key)][:content].class) || ([true, false, nil].include?(new_value[:content]) && [true, false, nil].include?(@property_links[(property_key)][:content]))
                    # Replace value directly, but don't save yet unless you have to (:state refers to the last 'loaded-in-from-db' state of the data).
                    new_value[:linkid] = @property_links[(property_key)][:linkid]
                    if new_value[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                      new_value[:record][:version] = new_value[:content].version()
                    else
                      new_value[:record][:version] = (@property_links[(property_key)][:record][:version] + 0.0001)
                    end
                    new_value[:record][:ordinal] = @property_links[(property_key)][:record][:ordinal]
                    new_value[:loaded] = true
                    new_value[:state] = @property_links[(property_key)][:state]
                    #
                    @property_links[(property_key)] = new_value
                    #
                  else
                    # Other class value being substituted.
                    if new_value[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                      new_value[:record][:version] = new_value[:content].version()
                    else
                      new_value[:record][:version] = (((@property_links[(property_key)][:record][:version].to_f + 0.0001) * 10000.0).to_i.to_f / 10000.0)
                    end
                    new_value[:record][:ordinal] = @property_links[(property_key)][:record][:ordinal]
                    new_value[:loaded] = true
                    #
                    @property_links[(property_key)] = new_value
                  end
                  result = @property_links[(property_key)][:content]
                  #
                when :add_value
                  # Note: set in-memory value and save.
                  if new_value[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                    new_value[:record][:version] = new_value[:content].version()
                  else
                    new_value[:record][:version] = BigDecimal("0.0")
                  end
                  new_value[:record][:ordinal] = @property_links.keys.size
                  new_value[:loaded] = true
                  #
                  @property_links[(property_key)] = new_value
                  # Review : is this wise to do this here??
                  # property_write(property_key)
                  # refresh_ordinals
                end
                # ### Handle coordination between persisted objects:
                if @property_links[(property_key)][:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  @property_links[(property_key)][:content].parent = (self)
                end
                #
                self.increment_version()
                result = @property_links[(property_key)][:content]
                #
              else
                raise Exception, "You do not have sufficient privileges to make this change. (write-reservation)"
              end
            else
              raise Exception, "The value is not persistable."
            end
          else
            raise Exception, "You must provide a property key in the form of a Symbol."
          end
          result
        end
        #
        def [](key=nil)
          result = nil
          # if key exists
          if self.alive?()
            if key.is_a?(::Symbol)
              if key.to_s.size > 256
                log_warn({:warning => "Attempted oversized key usage (limited to 256 characters), truncated #{key.inspect} to #{key.to_s[(0..255)].to_sym.inspect}"})
                key = key.to_s[(0..255)].to_sym
              end
              property_key = key.to_s.to_sym
              if @property_links[(property_key)]
                result = @property_links[(property_key)][:content]
              end
            else
              raise ArgumentError, "You must specify with a Symbol, not a #{key.class.inspect}"
            end
          else
            raise Exception, "Attempted to access a defunct structure"
          end
          result
        end
        #
        def include?(the_key)
          @property_links.keys.include?(the_key)
        end
        #
        def delete(key=nil)
          result = nil
          if key.is_a?(::Symbol)
            if key.to_s.size > 256
              log_warn({:warning => "Attempted oversized key usage (limited to 256 characters), truncated #{key.inspect} to #{key.to_s[(0..255)].to_sym.inspect}"})
              key = key.to_s[(0..255)].to_sym
            end
            if @format
              raise Exception, "Formatted - the structure cannot be altered"
            else
              if @property_links[(key)]
                result = @property_links[(key)][:content]
                @property_links.delete(key)
                # Review : send a 'delete_element' to server with the uuid of the DetachedHash and the key name.
                # ### -OR- develop @ the server: an 'overwrite' push call that will trim missing elements from stored copy.
              end
            end
          else
            raise ArgumentError, "You must specify with a Symbol, not a #{key.class.inspect}"
          end
          #
          result
        end
        #
        def unpersist()
          result = {}
          if self.alive?
            #
            export_db = [{:parent => nil, :parent_selector => nil, :object => self, :record => result}]
            children_of = Proc.new do |the_parent=nil|
              list = []
              export_db.each do |node|
                if node[:parent].object_id == the_parent.object_id
                  list << node
                end
              end
              list
            end
            # Build up export_db:
            self.search do |the_value, the_selector, the_container|
              if the_value.is_a?(::GxG::Database::DetachedHash)
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {}}
              else
                if the_value.is_a?(::GxG::Database::DetachedArray)
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => []}
                else
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => the_value}
                end
              end
            end
            # Collect children export content:
            link_db =[(export_db[0])]
            while link_db.size > 0 do
              entry = link_db.shift
              children_of.call(entry[:object]).each do |the_child|
                entry[:record][(the_child[:parent_selector])] = the_child[:record]
                if the_child[:object].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  link_db << the_child
                end
              end
            end
            #
          end
          result
        end
        #
        def export(options={:exclude_file_segments=>false})
          exclude_file_segments = (options[:exclude_file_segments] || false)
          if options[:clone] == true
            # Review : why are cloned objects unformatted? sync issues??
            result = {:type => :element_hash, :uuid => GxG::uuid_generate.to_s.to_sym, :title => @title.clone, :version => @version.to_s("F"), :content => {}}
          else
            result = {:type => :element_hash, :uuid => @uuid.clone, :title => @title.clone, :version => @version.to_s("F"), :format => @format.clone, :content => {}}
          end
          export_db = [{:parent => nil, :parent_selector => nil, :object => self, :record => result}]
          children_of = Proc.new do |the_parent=nil|
            list = []
            export_db.each do |node|
              if node[:parent].object_id == the_parent.object_id
                list << node
              end
            end
            list
          end
          # Build up export_db:
          self.search do |the_value, the_selector, the_container|
            if the_value.is_a?(::GxG::Database::DetachedHash)
              if options[:clone] == true
                the_uuid = GxG::uuid_generate.to_s.to_sym
              else
                the_uuid = the_value.uuid().clone
              end
              if (exclude_file_segments == true) && (the_selector == :file_segments || the_selector == :segments || the_selector == :portions)
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => {}, :record => {:type => :element_hash, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().to_s("F"), :format => the_value.format().clone, :content => {}}}
              else
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => :element_hash, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().to_s("F"), :format => the_value.format().clone, :content => {}}}
              end
            end
            if the_value.is_a?(::GxG::Database::DetachedArray)
              if options[:clone] == true
                the_uuid = GxG::uuid_generate.to_s.to_sym
              else
                the_uuid = the_value.uuid().clone
              end
              if (exclude_file_segments == true) && (the_selector == :file_segments || the_selector == :segments || the_selector == :portions)
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => [], :record => {:type => :element_array, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().to_s("F"), :constraint => the_value.constraint().clone, :content => []}}
              else
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => :element_array, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().to_s("F"), :constraint => the_value.constraint().clone, :content => []}}
              end
            end
            if the_value.is_any?(::NilClass, ::TrueClass, ::FalseClass, ::Integer, ::Float, ::BigDecimal, ::String, ::Time, ::GxG::ByteArray)
              data_type = GxG::Database::element_table_for_instance(the_value)
              #
              case data_type
              when :element_bigdecimal
                data = the_value.to_s
              when :element_datetime
                data = the_value.iso8601.to_s
              when :element_binary
                data = the_value.to_s.encode64
              when :element_text
                data = the_value.to_s
              else
                data = the_value
              end
              #
              export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => data_type, :version => (the_container.version(the_selector) || BigDecimal("0.0")).to_s("F"), :content => data}}
            end
          end
          # Collect children export content:
          link_db = [(export_db[0])]
          while link_db.size > 0 do
            entry = link_db.shift
            children_of.call(entry[:object]).each do |the_child|
              entry[:record][:content][(the_child[:parent_selector])] = the_child[:record]
              if the_child[:object].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                link_db << the_child
              end
            end
          end
          #
          result
        end
        #
        def each_pair(&block)
          collection = {}
          @property_links.keys.each do |key|
            collection[(key)] = (self[(key)])
          end
          if block.respond_to?(:call)
            collection.to_enum(:each_pair).each do |key,value|
              block.call(key,value)
            end
          else
            collection.to_enum(:each_pair)
          end
        end
        #
        def iterative(options={:include_inactive => true}, &block)
          result = []
          visit = Proc.new do |the_node=nil, accumulator=[]|
            node_stack = []
            if the_node
              node_stack << ({:parent => nil, :parent_selector => nil, :object => (the_node)})
              while (node_stack.size > 0) do
                a_node = node_stack.shift
                #
                if a_node[:object].is_a?(::GxG::Database::DetachedHash)
                  if a_node[:object].alive?
                    a_node[:object].each_pair do |the_key, the_value|
                      node_stack << ({:parent => a_node[:object], :parent_selector => the_key, :object => the_value})
                    end
                  else
                    if options[:include_inactive]
                      accumulator << a_node
                    end
                  end
                end
                if a_node[:object].is_a?(::GxG::Database::DetachedArray)
                  if a_node[:object].alive?
                    a_node[:object].each_with_index do |the_value, the_index|
                      node_stack << ({:parent => a_node[:object], :parent_selector => the_index, :object => the_value})
                    end
                  else
                    if options[:include_inactive]
                      accumulator << a_node
                    end
                  end
                end
              end
            end
            accumulator
          end
          #
          children_of = Proc.new do |the_db=[], the_parent=nil|
            list = []
            the_db.each do |node|
              if node[:parent].object_id == the_parent.object_id
                list << node
              end
            end
            list
          end
          #
          begin
            database = visit.call(self,[])
            link_db = children_of.call(database, self)
            if block.respond_to?(:call)
              while (link_db.size > 0) do
                entry = link_db.shift
                unless entry[:object].object_id == self.object_id
                  # calls with parameters: the_value, the_key/the_index (the_selector), the_container
                  raw_result = block.call(entry[:object], entry[:parent_selector], entry[:parent])
                  if raw_result
                    result << raw_result
                  end
                end
                if entry[:object].object_id != nil.object_id
                  children = children_of.call(database, entry[:object])
                  children.each do |child|
                    link_db << child
                  end
                end
              end
            end
            #
          rescue Exception => the_error
            log_error({:error => the_error, :parameters => {}})
          end
          #
          result
        end
        alias :process :iterative
        #
        def process!(options={:include_inactive => true}, &block)
          self.iterative(options, &block)
          self
        end
        #
        def search(options={:include_inactive => true}, &block)
          results = []
          if block.respond_to?(:call)
            results = self.iterative(options, &block)
          end
          results
        end
        #
        def paths_to(the_object=nil,base_path="")
          # new idea here:
          search_results = []
          unless base_path[0] == "/"
            base_path = ("/" << base_path)
          end
          if base_path.size > 1
            path_stack = base_path.split("/")[1..-1].reverse
          else
            path_stack = []
          end
          origin = self.get_at_path(base_path)
          container_stack = [{:selector => nil, :container => origin}]
          find_container = Proc.new do |the_container|
            result = nil
            container_stack.each_with_index do |entry, index|
              if entry[:container] == the_container
                result = entry
                break
              end
            end
            result
          end
          last_container = origin
          found = false
          # tester = {:a=>1, :b=>2, :c=>[0, 5], :testing=>{:d=>4.0, :e=>0.9, :f => nil}}
          if origin.is_any?(::Hash, ::Array, ::Struct, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
            origin.process! do |the_value, selector, container|
              if last_container.object_id != container.object_id
                container_record = find_container.call(container)
                if container_record
                  path_stack = container_record[:prefix].split("/").reverse
                  if path_stack.size == 0
                    path_stack << ""
                  end
                end
                last_container = container
              end
              if selector.is_a?(Symbol)
                safe_key = (":" + selector.to_s)
              else
                safe_key = selector.to_s
              end
              safe_key.gsub!("/","%2f")
              path_stack.unshift(safe_key)
              # compare the_value
              found = false
              if (the_value == the_object)
                found = true
              end
              if found
                search_results << ("/" << path_stack.reverse.join("/"))
              end
              #
              if the_value.is_any?(::Array, ::Hash, ::Struct, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                container_stack.unshift({:selector => selector, :container => the_value, :prefix => (path_stack.reverse.join("/"))})
              end
              path_stack.shift
              #
              nil
            end
          else
            search_results << ("/" << path_stack.join("/"))
          end
          search_results
        end
        #
        def get_at_path(the_path="/")
          result = nil
          if the_path == "/"
            result = self
          else
            object_stack = [(self)]
            path_stack = the_path.split("/")
            path_stack.to_enum.each do |path_element|
              element = nil
              if path_element.size > 0
                if (path_element =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
                  element = path_element.to_i
                else
                  element = path_element
                  element.gsub!("%2f","/")
                  if element[0] == ":"
                    element = element[(1..-1)].to_sym
                  end
                end
              end
              if element
                result = object_stack.first[(element)]
                if result.is_a?(NilClass)
                  break
                else
                  object_stack.unshift(result)
                end
              else
                # ignore double slashes? '//'
                # break
              end
            end
          end
          result
        end
        #
        def set_at_path(the_path="/",the_value=nil)
          result = nil
          if the_path != "/"
            container = self.get_at_path(::File::dirname(the_path))
            if container
              raw_selector = ::File::basename(the_path)
              selector = nil
              if raw_selector.size > 0
                if (raw_selector =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
                  selector = raw_selector.to_i
                else
                  selector = raw_selector
                  selector.gsub!("%2f","/")
                  if selector[0] == ":"
                    selector = selector[(1..-1)].to_sym
                  end
                end
              end
              if selector
                container[(selector)] = the_value
                result = container[(selector)]
              else
                # ignore double slashes? '//'
                # break
              end
              #
            end
          end
          result
        end
        #
      end
        #
      class DetachedArray
        #
        private
        #
        def element_destroy(indexer=nil)
          # Review : develop on-server element destroy command path ??
        end
        # Note: property_read handled by load_property_links
        def element_write(indexer=nil)
          # Review : not needed on webclient version ??
        end
        #
        def load_element_links
          # Review : not needed on webclient version ??
        end
        #
        def refresh_ordinals()
          new_links = []
          @element_links.each_with_index do |the_key, ordinal|
            @element_links[(ordinal)][:record][:ordinal] = ordinal
            new_links << @element_links[(ordinal)]
          end
          @element_links = new_links
        end
        #
        public
        #
        def uuid()
            @uuid.clone
        end
        #
        def uuid=(the_uuid=nil)
          if GxG::valid_uuid?(the_uuid)
            @uuid = the_uuid.to_s.to_sym
          end
        end
        #
        def title()
            @title.clone
        end
        #
        def title=(the_title=nil)
          if the_title
            @title = the_title.to_s[0..255]
            self.increment_version
          end
        end
        #
        def version()
          @version.clone
        end
        #
        def version=(the_version=nil)
          if the_version.is_a?(::Numeric)
            @version = the_version.to_s("F").to_d
          end
        end
        #
        def element_version(index=nil)
          result = 0.0
          if index.is_a?(::Numeric)
            #
            if @element_links[(index)]
              result = @element_links[(index)][:record][:version]
            else
              result = 0.0
            end
            #
          end
          result
        end
        #
        def set_element_version(element_index, the_version=nil)
          result = false
          if @element_links[(element_index)]
            if the_version.is_a?(::Numeric)
              @element_links[(element_index)][:record][:version] = (((the_version.to_f) * 10000.0).to_i.to_f / 10000.0)
              result = true
            else
              log_warning("Attempted to set version to an invalid version value #{the_version.inspect} for index #{element_index.inspect} on Object #{@uuid.inspect}")
            end
          else
            log_warning("Attempted to set version with an invalid index #{element_index.inspect} on Object #{@uuid.inspect}")
          end
          result
        end
        #
        def constraint()
          @constraint.clone
        end
        #
        def constraint=(the_format=nil)
          if GxG::valid_uuid?(the_format)
            @constraint = the_format.to_s.to_sym
          end
        end
        #
        def parent()
            @parent
        end
        #
        def parent=(object=nil)
          if object.is_any?([::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray])
            # Review : parent can only be set once -- is this best??
            unless @parent
              @parent = object
            end
          end
        end
        # Permission Management:
        def get_permissions()
          # Review : not needed on webclient version ??
        end
        #
        def set_permissions(credential=nil, the_permission=nil)            
          # Review : not needed on webclient version ??
        end
        #
        def reservation()
          # Review : not needed on webclient version ??
        end
        #
        def write_permission?()
          true
        end
        #
        def write_reserved?()
          true
        end
        #
        def release_reservation()
          true
        end
        #
        def get_reservation()
          true
        end
        #
        def wait_for_reservation(timeout=nil)
          true
        end
        #
        def get_delegate()
          # Review : not needed on webclient version ??
        end
        #
        def set_delegate(the_delegate=nil)
          # Review : not needed on webclient version ??
        end
        #
        def increment_version()
          if self.alive?
            if self.write_reserved?()
              @version = (((@version + 0.0001) * 10000.0).to_i.to_f / 10000.0)
            end
          end
        end
        #
        def save_version()
          # Review : not needed on webclient version ??
        end
        #
        def clear_constraint()
          if self.alive?
            if @constraint
              @constraint = nil
            end
          end
          true
        end
        #
        def constraint()
          @constraint.clone
        end
        #
        def ufs()
          if @format
            record = GxG::DB[:formats][(@format.to_s.to_sym)]
            if record
              record[:ufs].to_s.to_sym
            else
              ""
            end
          else
            ""
          end
        end
        #
        def refresh_links()
          # Review : not needed on webclient ??
        end
        #
        def initialize()
          @uuid = ::GxG::uuid_generate().to_s.to_sym
          @title = "Untitled #{@uuid.to_s}"
          @version = 0.0
          @constraint = nil
          @parent = nil
          @data = []
          @element_links = []
          self
        end
        #
        def inspect()
          # FORNOW: make re-entrant (yes, I know!) Fortunately, circular links are impossible with DetachedArray.
          # TODO: make interative instead of re-entrant.
          result = "["
          @element_links.each_index do |element_index|
            result = result + @element_links[(element_index)][:content].inspect
            # if @element_links[(element_index)].is_a?(::Hash)
            #   result = result + @element_links[(element_index)][:content].inspect
            # else
            #   result = result + "(Not Loaded)"
            # end
            unless element_index == (@element_links.size - 1)
              result = result + ", "
            end
          end
          result = result + "]"
          result
        end
        #
        def alive?()
          true
        end
        #
        def db_address()
          nil
        end
        #
        def deactivate()
          # Review : not needed on webclient ??
        end
        #
        def save()
          # Review : create a save-to-server command path here.
        end
        #
        def destroy()
          # Review : create a destroy-at-server command path here.
        end
        #
        def size()
          @element_links.size
        end
        #
        def structure_attached?()
          # Review : not needed on webclient ??
          false
        end
        def structure_detach()
          # Review : not needed on webclient ??
          true
        end
        #
        def []=(indexer=nil, value=nil)
          # Only works with Integer indexes.
          unless self.alive?()
            raise Exception, "Attempted to alter a defunct structure"
          end
          result = nil
          if indexer.is_a?(::Integer)
            # Review : rewrite ????
            if value.is_any?(::GxG::Database::valid_field_classes()) || value.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray, ::Hash, ::Array)
              unless self.write_reserved?()
                self.get_reservation()
              end
              if self.write_reserved?()
                # Further screen value provided:
                # ### Check provided DetachedHashes and DetachedArrays
                # ### Check provided Hashes and Arrays
                if value.is_any?(::Hash, ::Array)
                  value.search do |the_value, the_selector, the_container|
                    unless the_value.is_any?(::GxG::Database::valid_field_classes()) || the_value.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray, ::Hash, ::Array)
                      raise Exception, "The structure you are attaching has an unpersistable item within it (not supported)."
                    end
                  end
                end
                # ### Property Exists?
                if @element_links[(indexer)]
                  # set property to value
                  operation = :set_value
                else
                  if @constraint
                    raise Exception, "Formatted - the structure cannot be altered"
                  else
                    # add property : value pair
                    operation = :add_value
                  end
                end
                # ### Prepare new value
                new_value = {
                  :linkid => nil,
                  :content => nil,
                  :loaded => false,
                  :state => 0,
                  :record => {
                    :parent_uuid => @uuid.to_s,
                    :ordinal => 0,
                    :version => 0.0,
                    :element => "element_boolean",
                    :element_boolean => -1,
                    :element_integer => 0,
                    :element_float => 0.0,
                    :element_bigdecimal => BigDecimal("0.0"),
                    :element_datetime => ::Time.now,
                    :time_offset => 0.0,
                    :time_prior => 0.0,
                    :time_after => 0.0,
                    :length => 0,
                    :element_text => "",
                    :element_binary => nil,
                    :element_array => nil,
                    :element_hash => nil
                  }
                }
                #
                if value.is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  # ### Assimilate DetachedHash or DetachedArray
                  new_value[:content] = value
                  new_value[:loaded] = true
                  new_value[:state] = new_value[:content].hash
                  # Note: version is sync'd here, but don't rely upon property version with linked structures, but use structure's version method.
                  new_value[:record][:version] = new_value[:content].version()
                  if value.is_a?(::GxG::Database::DetachedHash)
                    new_value[:record][:element] = "element_hash"
                    new_value[:record][:element_hash] = value
                  else
                    new_value[:record][:element] = "element_array"
                    new_value[:record][:element_array] = value
                  end
                else
                  # ### Persist Hashes and Arrays
                  if value.is_any?(::Hash, ::Array)
                    new_value[:content] = ::GxG::Database::iterative_detached_persist(value)
                    new_value[:loaded] = true
                    new_value[:state] = new_value[:content].hash
                    # Note: version is sync'd here, but don't rely upon property version with linked structures, but use structure's version method.
                    new_value[:record][:version] = new_value[:content].version()
                    if value.is_a?(::Hash)
                      new_value[:record][:element] = "element_hash"
                      new_value[:record][:element_hash] = new_value[:content]
                    else
                      new_value[:record][:element] = "element_array"
                      new_value[:record][:element_array] = new_value[:content]
                    end
                  else
                    # ### Persist Base Element Values
                    new_value[:record][:element] = ::GxG::Database::element_table_for_instance(value).to_s
                    case new_value[:record][:element]
                    when "element_boolean"
                      case value.class
                      when ::NilClass
                        new_value[:record][:element_boolean] = -1
                        new_value[:content] = nil
                      when ::FalseClass
                        new_value[:record][:element_boolean] = 0
                        new_value[:content] = false
                      when ::TrueClass
                        new_value[:record][:element_boolean] = 1
                        new_value[:content] = true
                      end
                    when "element_integer"
                      new_value[:record][:element_integer] = value
                      new_value[:content] = value
                    when "element_float"
                      new_value[:record][:element_float] = value
                      new_value[:content] = value
                    when "element_bigdecimal"
                      new_value[:record][:element_bigdecimal] = BigDecimal(value.to_s)
                      new_value[:content] = new_value[:record][:element_bigdecimal]
                    when "element_datetime"
                      new_value[:record][:element_datetime] = value
                      new_value[:content] = value
                    when "element_text"
                      new_value[:record][:element_text] = value
                      new_value[:record][:length] = value.size
                      new_value[:content] = value
                    when "element_binary"
                      # Note: be sure to keep version & length sync'd with linked binary element record
                      if operation == :set_value
                        new_value[:record][:version] = @element_links[(indexer)][:record][:version]
                        new_value[:record][:element_binary_uuid] = @element_links[(indexer)][:record][:element_binary_uuid]
                      end
                      new_value[:record][:length] = value.size
                      new_value[:content] = value
                    else
                      raise Exception, "Unable to map an element type for value: #{value.inspect}"
                    end
                  end
                end
                # ### Commit Changes
                case operation
                when :set_value
                  # Note: Set In-memory value only, don't save unless you have to.
                  if new_value[:content].is_a?(@element_links[(indexer)][:content].class) || ([true, false, nil].include?(new_value[:content]) && [true, false, nil].include?(@element_links[(indexer)][:content]))
                    # Replace value directly, but don't save yet unless you have to (:state refers to the last 'loaded-in-from-db' state of the data).
                    new_value[:linkid] = @element_links[(indexer)][:linkid]
                    if new_value[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                      new_value[:record][:version] = new_value[:content].version()
                    else
                      new_value[:record][:version] = (((@element_links[(indexer)][:record][:version].to_f + 0.0001) * 10000.0).to_i.to_f / 10000.0)
                    end
                    new_value[:record][:ordinal] = @element_links[(indexer)][:record][:ordinal]
                    new_value[:loaded] = true
                    new_value[:state] = @element_links[(indexer)][:state]
                    # 
                    if new_value[:content].is_a?(::String)
                      @element_links[(indexer)] = new_value
                    end
                    #
                  else
                    # Other class value being substituted.
                    if new_value[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                      new_value[:record][:version] = new_value[:content].version()
                    else
                      new_value[:record][:version] = (((@element_links[(indexer)][:record][:version].to_f + 0.0001) * 10000.0).to_i.to_f / 10000.0)
                    end
                    new_value[:record][:ordinal] = @element_links[(indexer)][:record][:ordinal]
                    new_value[:loaded] = true
                    #
                    @element_links[(indexer)] = new_value
                  end
                  #
                when :add_value
                  # Note: set in-memory value and save.
                  if new_value[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                    new_value[:record][:version] = new_value[:content].version()
                  else
                    new_value[:record][:version] = 0.0
                  end
                  new_value[:record][:ordinal] = @element_links.size
                  new_value[:loaded] = true
                  #
                  @element_links[(indexer)] = new_value
                end
                # ### Handle coordination between persisted objects:
                if @element_links[(indexer)][:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  @element_links[(indexer)][:content].parent = (self)
                end
                #
                self.increment_version()
                result = @element_links[(indexer)][:content]
                #
              else
                raise Exception, "You do not have sufficient privileges to make this change. (write-reservation)"
              end
            else
              raise Exception, "The value is not persistable."
            end
          else
            raise Exception, "You must provide a index in the form of an Integer."
          end
          result
        end
        #
        #
        def [](indexer=nil)
          result = nil
          # if exists
          # if is not loaded, load element (if String or ByteArray)
          if self.alive?()
            if indexer.is_a?(::Integer)
              if @element_links[(indexer)]
                result = @element_links[(indexer)][:content]
              end
            else
              raise ArgumentError, "You must specify with an Integer, not a #{indexer.class.inspect}"
            end              
          else
            raise Exception, "Attempted to access a defunct structure"
          end
          result
        end
        #
        def delete_at(indexer=nil)
          result = nil
          # if exists
          # if is not loaded, load element
          if self.alive?()
            if indexer.is_a?(::Integer)
              if self.write_reserved?()
                #
                if @element_links[(indexer)]
                  # This will load the unloaded prior to separation.
                  result = self[(indexer)]
                  the_link = @element_links.delete_at(indexer)
                  # Review : element-unlink on server side ??
                  if the_link[:content].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                    the_link[:content].save
                  end
                  self.increment_version()
                end
                #
              else
                raise Exception, "You do not have sufficient privileges to make this change"
              end
            else
              raise ArgumentError, "You must specify with a Symbol, not a #{key.class.inspect}"
            end              
          else
            raise Exception, "Attempted to access a defunct structure"
          end
          result
        end
        #
        def <<(*args)
          if args.size > 0
            args.each do |item|
              self[(@element_links.size)] = item
            end
          end
          self
        end
        #
        def push(*args)
          if args.size > 0
            args.each do |item|
              self << item
            end
          end
          self
        end
        #
        def pop()
          self.delete_at((@element_links.size - 1))
        end
        #
        def shift()
          self.delete_at(0)
        end
        #
        def insert(the_index=nil, the_object=nil)
          # resovle the_index : the_index < 0 : the_index = (size - the_index)
          # if the_index == 0 : @element_links.unshift(nil-record);  self[0] = the_object
          # if the_index > size-1 : push(the_object)
          # else: @element_links.insert(the_index, nil-record); self[(the_index)] = the_object
          # vette the_object --> persistable?
          if ::GxG::Database::persistable?(the_object)
            new_value = {
              :linkid => nil,
              :content => nil,
              :loaded => false,
              :state => 0,
              :record => {
                :parent_uuid => @uuid.to_s,
                :ordinal => 0,
                :version => BigDecimal("0.0"),
                :element => "element_boolean",
                :element_boolean => -1,
                :element_integer => 0,
                :element_float => 0.0,
                :element_bigdecimal => BigDecimal("0.0"),
                :element_datetime => ::DateTime.now,
                :time_offset => 0.0,
                :time_prior => 0.0,
                :time_after => 0.0,
                :length => 0,
                :element_text => "",
                :element_text_uuid => "",
                :element_binary_uuid => "",
                :element_array_uuid => "",
                :element_hash_uuid => ""
              }
            }
            the_index = the_index.to_i
            if the_index < 0
              the_index = (self.size - the_index)
            end
            if the_index == 0
              new_value[:record][:ordinal] = the_index
              @element_links.unshift(new_value)
              refresh_ordinals
              self[0] = the_object
            else
              if the_index > (self.size - 1)
                self.push(the_object)
              else
                new_value[:record][:ordinal] = the_index
                @element_links.insert(the_index, new_value)
                refresh_ordinals
                self[(the_index)] = the_object
              end
            end
          end
          self
        end
        # ???? def insert - ::GxG::Database::persistable?(the_object)
        def unshift(the_object=nil)
          self.insert(0,the_object)
        end
        #
        def swap(first_index=nil, last_index=nil)
          result = false
          if first_index && last_index
            if (0..(self.size - 1)).include?(first_index.to_i) && (0..(self.size - 1)).include?(last_index.to_i)
              if first_index.to_i != last_index.to_i
                record = @element_links[(first_index)]
                @element_links[(first_index)] = @element_links[(last_index)]
                @element_links[(last_index)] = record
                result = true
              end
            end
          end
          result
        end
        #
        def include?(the_value)
          result = false
          @element_links.each do |element|
            if element[:content] == the_value
              result = true
              break
            end
          end
          result
        end
        #
        def find_index(the_value)
          result = nil
          @element_links.each_with_index do |element, indexer|
            if element[:content] == the_value
              result = indexer
              break
            end
          end
          result
        end
        #
        def export(options={:exclude_file_segments=>false})
          if self.alive?
            exclude_file_segments = (options[:exclude_file_segments] || false)
            if options[:clone] == true
              # Review : why are cloned objects unconstrained? sync issues??
              result = {:type => :element_array, :uuid => GxG::uuid_generate.to_s.to_sym, :title => @title.clone, :version => @version.clone, :content => []}
            else
              result = {:type => :element_array, :uuid => @uuid.clone, :title => @title.clone, :version => @version.clone, :constraint => @constraint.clone, :content => []}
            end
            export_db = [{:parent => nil, :parent_selector => nil, :object => self, :record => result}]
            children_of = Proc.new do |the_parent=nil|
              list = []
              export_db.each do |node|
                if node[:parent].object_id == the_parent.object_id
                  list << node
                end
              end
              list
            end
            # Build up export_db:
            self.search do |the_value, the_selector, the_container|
              if the_value.is_a?(::GxG::Database::DetachedHash)
                if options[:clone] == true
                  the_uuid = GxG::uuid_generate.to_s.to_sym
                else
                  the_uuid = the_value.uuid().clone
                end
                if (exclude_file_segments == true) && (the_selector == :file_segments || the_selector == :segments || the_selector == :portions)
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => {}, :record => {:type => :element_hash, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().clone, :format => the_value.format().clone, :content => {}}}
                else
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => :element_hash, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().clone, :format => the_value.format().clone, :content => {}}}
                end
              end
              if the_value.is_a?(::GxG::Database::DetachedArray)
                if options[:clone] == true
                  the_uuid = GxG::uuid_generate.to_s.to_sym
                else
                  the_uuid = the_value.uuid().clone
                end
                if (exclude_file_segments == true) && (the_selector == :file_segments || the_selector == :segments || the_selector == :portions)
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => [], :record => {:type => :element_array, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().clone, :constraint => the_value.constraint().clone, :content => []}}
                else
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => :element_array, :uuid => the_uuid, :title => the_value.title().clone, :version => the_value.version().clone, :constraint => the_value.constraint().clone, :content => []}}
                end
              end
              if the_value.is_any?(::GxG::Database::valid_field_classes())
                data_type = GxG::Database::element_table_for_instance(the_value)
                case data_type
                when :element_bigdecimal
                  data = the_value.to_s
                when :element_datetime
                  data = the_value.iso8601.to_s
                when :element_binary
                  data = the_value.to_s.encode64
                when :element_text
                  data = the_value.to_s
                else
                  data = the_value
                end              
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {:type => data_type, :version => (the_container.version(the_selector) || 0.0), :content => data}}
              end
            end
            # Collect children export content:
            link_db = [(export_db[0])]
            while link_db.size > 0 do
              entry = link_db.shift
              children_of.call(entry[:object]).each do |the_child|
                entry[:record][:content][(the_child[:parent_selector])] = the_child[:record]
                if the_child[:object].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  link_db << the_child
                end
              end
            end
          else
            result = nil
          end
          result
        end
        #
        def sync_export(options={})
          # Review : does this work with DetachedArray ??
          self.save
        end
        #
        def first()
          if @element_links.size > 0
            self[0]
          else
            nil
          end
        end
        #
        def last()
          if @element_links.size > 0
            self[(@element_links.size - 1)]
          else
            nil
          end
        end
        #
        def each(&block)
          if block.respond_to?(:call)
            load_element_links
            if @element_links.size > 0
              @element_links.each_index do |index|
                block.call(self[(index)])
              end
            end
            self
          else
            self.to_enum(:each)
          end
        end
        #
        def each_index(&block)
          if block.respond_to?(:call)
            load_element_links
            if @element_links.size > 0
              @element_links.each_index do |index|
                block.call(index)
              end
            end
            self
          else
            self.to_enum(:each_index)
          end
        end
        #
        def each_with_index(offset=0,&block)
          if block.respond_to?(:call)
            load_element_links
            if @element_links.size > 0
              @element_links.to_enum(:each).with_index(offset).each do |entry, index|
                block.call(self[(index)], index)
              end
            end
            self
          else
            self.to_enum(:each_with_index,offset)
          end
        end
        #
        def iterative(options={:include_inactive => true}, &block)
          result = []
          visit = Proc.new do |the_node=nil, accumulator=[]|
            node_stack = []
            if the_node
              node_stack << ({:parent => nil, :parent_selector => nil, :object => (the_node)})
              while (node_stack.size > 0) do
                a_node = node_stack.shift
                #
                if a_node[:object].is_a?(::GxG::Database::DetachedHash)
                  if a_node[:object].alive?
                    a_node[:object].each_pair do |the_key, the_value|
                      node_stack << ({:parent => a_node[:object], :parent_selector => the_key, :object => the_value})
                    end
                  else
                    if options[:include_inactive]
                      accumulator << a_node
                    end
                  end
                end
                if a_node[:object].is_a?(::GxG::Database::DetachedArray)
                  if a_node[:object].alive?
                    a_node[:object].each_with_index do |the_value, the_index|
                      node_stack << ({:parent => a_node[:object], :parent_selector => the_index, :object => the_value})
                    end
                  else
                    if options[:include_inactive]
                      accumulator << a_node
                    end
                  end
                end
                #
                if a_node.alive? || options[:include_inactive]
                  accumulator << a_node
                end
              end
            end
            accumulator
          end
          #
          children_of = Proc.new do |the_db=[], the_parent=nil|
            list = []
            the_db.each do |node|
              if node[:parent].object_id == the_parent.object_id
                list << node
              end
            end
            list
          end
          #
          begin
            database = visit.call(self,[])
            link_db = children_of.call(database, self)
            if block.respond_to?(:call)
              while (link_db.size > 0) do
                entry = link_db.shift
                unless entry[:object].object_id == self.object_id
                  # calls with parameters: the_value, the_key/the_index (the_selector), the_container
                  raw_result = block.call(entry[:object], entry[:parent_selector], entry[:parent])
                  if raw_result
                    result << raw_result
                  end
                end
                if entry[:object].object_id != nil.object_id
                  children = children_of.call(database, entry[:object])
                  children.each do |child|
                    link_db << child
                  end
                end
              end
            end
            #
          rescue Exception => the_error
            log_error({:error => the_error, :parameters => {}})
          end
          #
          result
        end
        alias :process :iterative
        #
        def process!(options={:include_inactive => true}, &block)
          self.iterative(options, &block)
          self
        end
        #
        def search(options={:include_inactive => true}, &block)
          results = []
          if block.respond_to?(:call)
            results = self.iterative(options, &block)
          end
          results
        end
        #
        def paths_to(the_object=nil,base_path="")
          # new idea here:
          search_results = []
          unless base_path[0] == "/"
            base_path = ("/" << base_path)
          end
          if base_path.size > 1
            path_stack = base_path.split("/")[1..-1].reverse
          else
            path_stack = []
          end
          origin = self.get_at_path(base_path)
          container_stack = [{:selector => nil, :container => origin}]
          find_container = Proc.new do |the_container|
            result = nil
            container_stack.each_with_index do |entry, index|
              if entry[:container] == the_container
                result = entry
                break
              end
            end
            result
          end
          last_container = origin
          found = false
          # tester = {:a=>1, :b=>2, :c=>[0, 5], :testing=>{:d=>4.0, :e=>0.9, :f => nil}}
          if origin.is_any?(::Hash, ::Array, ::Struct, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
            origin.process! do |the_value, selector, container|
              if last_container.object_id != container.object_id
                container_record = find_container.call(container)
                if container_record
                  path_stack = container_record[:prefix].split("/").reverse
                  if path_stack.size == 0
                    path_stack << ""
                  end
                end
                last_container = container
              end
              if selector.is_a?(Symbol)
                safe_key = (":" + selector.to_s)
              else
                safe_key = selector.to_s
              end
              safe_key.gsub!("/","%2f")
              path_stack.unshift(safe_key)
              # compare the_value
              found = false
              if (the_value == the_object)
                found = true
              end
              if found
                search_results << ("/" << path_stack.reverse.join("/"))
              end
              #
              if the_value.is_any?(::Array, ::Hash, ::Struct, ::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                container_stack.unshift({:selector => selector, :container => the_value, :prefix => (path_stack.reverse.join("/"))})
              end
              path_stack.shift
              #
              nil
            end
          else
            search_results << ("/" << path_stack.join("/"))
          end
          search_results
        end
        #
        def get_at_path(the_path="/")
          # /^(?:[0-9])*[0-9](?:[0-9])*$/ = nil if an alpha present there, else 0 only numeric
          # Attribution : http://stackoverflow.com/questions/1240674/regex-match-a-string-containing-numbers-and-letters-but-not-a-string-of-just-nu
          #
          # if ":" detected do: (str.gsub("%2f","/").to_sym) as key else (str.gsub("%2f","/"))
          result = nil
          if the_path == "/"
            result = self
          else
            object_stack = [(self)]
            path_stack = the_path.split("/")
            path_stack.to_enum.each do |path_element|
              element = nil
              if path_element.size > 0
                if (path_element =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
                  element = path_element.to_i
                else
                  element = path_element
                  element.gsub!("%2f","/")
                  if element[0] == ":"
                    element = element[(1..-1)].to_sym
                  end
                end
              end
              if element
                result = object_stack.first[(element)]
                if result.is_a?(NilClass)
                  break
                else
                  object_stack.unshift(result)
                end
              else
                # ignore double slashes? '//'
                # break
              end
            end
          end
          result
        end
        #
        def set_at_path(the_path="/",the_value=nil)
          result = nil
          if the_path != "/"
            container = self.get_at_path(::File::dirname(the_path))
            if container
              raw_selector = ::File::basename(the_path)
              selector = nil
              if raw_selector.size > 0
                if (raw_selector =~ /^(?:[0-9])*[0-9](?:[0-9])*$/) == 0
                  selector = raw_selector.to_i
                else
                  selector = raw_selector
                  selector.gsub!("%2f","/")
                  if selector[0] == ":"
                    selector = selector[(1..-1)].to_sym
                  end
                end
              end
              if selector
                container[(selector)] = the_value
                result = container[(selector)]
              else
                # ignore double slashes? '//'
                # break
              end
              #
            end
          end
          result
        end
        #
        def unpersist()
          result = []
          if self.alive?
            #
            export_db = [{:parent => nil, :parent_selector => nil, :object => self, :record => result}]
            children_of = Proc.new do |the_parent=nil|
              list = []
              export_db.each do |node|
                if node[:parent].object_id == the_parent.object_id
                  list << node
                end
              end
              list
            end
            # Build up export_db:
            self.search do |the_value, the_selector, the_container|
              if the_value.is_a?(::GxG::Database::DetachedHash)
                export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => {}}
              else
                if the_value.is_a?(::GxG::Database::DetachedArray)
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => []}
                else
                  export_db << {:parent => the_container, :parent_selector => the_selector.clone, :object => the_value, :record => the_value}
                end
              end
            end
            # Collect children export content:
            link_db =[(export_db[0])]
            while link_db.size > 0 do
              entry = link_db.shift
              children_of.call(entry[:object]).each do |the_child|
                entry[:record][(the_child[:parent_selector])] = the_child[:record]
                if the_child[:object].is_any?(::GxG::Database::DetachedHash, ::GxG::Database::DetachedArray)
                  link_db << the_child
                end
              end
            end
            #
          end
          result
        end
        #
      end
        # ### Compatibility with legacy code
        class PeristedArray < ::GxG::Database::DetachedArray
        end
        #
        class PeristedHash < ::GxG::Database::DetachedHash
          def self.import(import_record=nil)
            result = nil
            unless import_record.is_any?(::Hash, ::GxG::Database::DetachedHash, ::GxG::Database::PersistedHash)
                raise Exception, "Malformed import record passed."
            end
            # {:type => :element_hash, :uuid => @uuid.clone, :title => @title.clone, :version => @version.clone, :format => @format.clone, :content => {}}
            import_db = [{:target => ::GxG::Database::PersistedHash.new, :record => import_record}]
            result =  import_db[0][:target]
            while import_db.size > 0 do
                entry = import_db.shift
                case entry[:record][:type].to_s.to_sym
                when :element_hash
                    entry[:target].uuid = entry[:record][:uuid].to_s.to_sym
                    entry[:target].title = entry[:record][:title].to_s
                      entry[:record][:content].keys.each do |the_key|
                          case entry[:record][:content][(the_key)][:type].to_s.to_sym
                          when :element_hash
                              new_target = GxG::Database::PersistedHash.new
                              entry[:target][(the_key)] = new_target
                              import_db << {:target => new_target, :record => (entry[:record][:content][(the_key)])}
                              entry[:target][(the_key)].parent = (entry[:target])
                          when :element_array
                              new_target = GxG::Database::PersistedArray.new
                              entry[:target][(the_key)] = new_target
                              import_db << {:target => new_target, :record => (entry[:record][:content][(the_key)])}
                              entry[:target][(the_key)].parent = (entry[:target])
                          when :element_boolean, :element_integer, :element_float, :element_text
                              entry[:target][(the_key)] = entry[:record][:content][(the_key)][:content]
                          when :element_bigdecimal
                              entry[:target][(the_key)] = BigDecimal(entry[:record][:content][(the_key)][:content].to_s)
                          when :element_datetime
                            entry[:target][(the_key)] = ::Chronic::parse(entry[:record][:content][(the_key)][:content].to_s)
                          when :element_binary
                            entry[:target][(the_key)] = ::GxG::ByteArray.new(entry[:record][:content][(the_key)][:content].to_s.decode64)
                          end
                      end
                    entry[:target].version = BigDecimal(entry[:record][:version].to_s)
                    entry[:target].format = entry[:record][:format].to_s.to_sym
                when :element_array
                    entry[:target].uuid = entry[:record][:uuid].to_s.to_sym
                    entry[:target].title = entry[:record][:title].to_s
                      entry[:record][:content].each_index do |indexer|
                          case entry[:record][:content][(indexer)][:type].to_s.to_sym
                          when :element_hash
                              new_target = GxG::Database::PersistedHash.new
                              entry[:target][(indexer)] = new_target
                              import_db << {:target => new_target, :record => (entry[:record][:content][(indexer)])}
                              entry[:target][(indexer)].parent =(entry[:target])
                          when :element_array
                              new_target = GxG::Database::PersistedArray.new
                              entry[:target][(indexer)] = new_target
                              import_db << {:target => new_target, :record => (entry[:record][:content][(indexer)])}
                              entry[:target][(indexer)].parent = (entry[:target])
                          when :element_boolean, :element_integer, :element_float, :element_text
                              entry[:target][(indexer)] = entry[:record][:content][(indexer)][:content]
                          when :element_bigdecimal
                              entry[:target][(indexer)] = BigDecimal(entry[:record][:content][(indexer)][:content].to_s)
                          when :element_datetime
                            entry[:target][(indexer)] = ::Chronic::parse(entry[:record][:content][(indexer)][:content].to_s)
                          when :element_binary
                            entry[:target][(indexer)] = ::GxG::ByteArray.new(entry[:record][:content][(indexer)][:content].to_s.decode64)
                          end
                      end
                    entry[:target].version = BigDecimal(entry[:record][:version].to_s)
                    entry[:target].constraint = entry[:record][:constraint].to_s.to_sym
                end
            end
            #
            result
          end
          #
        end
        #
        #
        #
    end
end
# perisistence hooks:
class Array
  def persist()
    GxG::Database::iterative_detached_persist(self)
  end
end
class Hash
  def persist()
    GxG::Database::iterative_detached_persist(self)
  end
end
#