# frozen_string_literal: false
#--
# = uri/common.rb
#
# Author:: Akira Yamada <akira@ruby-lang.org>
# Revision:: $Id$
# License::
#   You can redistribute it and/or modify it under the same term as Ruby.
#
# See URI for general documentation
#

module URI
  #
  # Includes URI::REGEXP::PATTERN
  #
  module RFC2396_REGEXP
    #
    # Patterns used to parse URI's
    #
    module PATTERN
      # :stopdoc:

      # RFC 2396 (URI Generic Syntax)
      # RFC 2732 (IPv6 Literal Addresses in URL's)
      # RFC 2373 (IPv6 Addressing Architecture)

      # alpha         = lowalpha | upalpha
      ALPHA = "a-zA-Z"
      # alphanum      = alpha | digit
      ALNUM = "#{ALPHA}\\d"

      # hex           = digit | "A" | "B" | "C" | "D" | "E" | "F" |
      #                         "a" | "b" | "c" | "d" | "e" | "f"
      HEX     = "a-fA-F\\d"
      # escaped       = "%" hex hex
      ESCAPED = "%[#{HEX}]{2}"
      # mark          = "-" | "_" | "." | "!" | "~" | "*" | "'" |
      #                 "(" | ")"
      # unreserved    = alphanum | mark
      UNRESERVED = "\\-_.!~*'()#{ALNUM}"
      # reserved      = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" |
      #                 "$" | ","
      # reserved      = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" |
      #                 "$" | "," | "[" | "]" (RFC 2732)
      RESERVED = ";/?:@&=+$,\\[\\]"

      # domainlabel   = alphanum | alphanum *( alphanum | "-" ) alphanum
      DOMLABEL = "(?:[#{ALNUM}](?:[-#{ALNUM}]*[#{ALNUM}])?)"
      # toplabel      = alpha | alpha *( alphanum | "-" ) alphanum
      TOPLABEL = "(?:[#{ALPHA}](?:[-#{ALNUM}]*[#{ALNUM}])?)"
      # hostname      = *( domainlabel "." ) toplabel [ "." ]
      HOSTNAME = "(?:#{DOMLABEL}\\.)*#{TOPLABEL}\\.?"

      # :startdoc:
    end # PATTERN

    # :startdoc:
  end # REGEXP

  # class that Parses String's into URI's
  #
  # It contains a Hash set of patterns and Regexp's that match and validate.
  #
  class RFC2396_Parser
    include RFC2396_REGEXP

    #
    # == Synopsis
    #
    #   URI::Parser.new([opts])
    #
    # == Args
    #
    # The constructor accepts a hash as options for parser.
    # Keys of options are pattern names of URI components
    # and values of options are pattern strings.
    # The constructor generates set of regexps for parsing URIs.
    #
    # You can use the following keys:
    #
    #   * :ESCAPED (URI::PATTERN::ESCAPED in default)
    #   * :UNRESERVED (URI::PATTERN::UNRESERVED in default)
    #   * :DOMLABEL (URI::PATTERN::DOMLABEL in default)
    #   * :TOPLABEL (URI::PATTERN::TOPLABEL in default)
    #   * :HOSTNAME (URI::PATTERN::HOSTNAME in default)
    #
    # == Examples
    #
    #   p = URI::Parser.new(:ESCAPED => "(?:%[a-fA-F0-9]{2}|%u[a-fA-F0-9]{4})")
    #   u = p.parse("http://example.jp/%uABCD") #=> #<URI::HTTP:0xb78cf4f8 URL:http://example.jp/%uABCD>
    #   URI.parse(u.to_s) #=> raises URI::InvalidURIError
    #
    #   s = "http://example.com/ABCD"
    #   u1 = p.parse(s) #=> #<URI::HTTP:0xb78c3220 URL:http://example.com/ABCD>
    #   u2 = URI.parse(s) #=> #<URI::HTTP:0xb78b6d54 URL:http://example.com/ABCD>
    #   u1 == u2 #=> true
    #   u1.eql?(u2) #=> false
    #
    def initialize(opts = {})
      @pattern = initialize_pattern(opts)
      @pattern.each_value(&:freeze)
      @pattern.freeze

      @regexp = initialize_regexp(@pattern)
      @regexp.each_value(&:freeze)
      @regexp.freeze
    end

    # The Hash of patterns.
    #
    # see also URI::Parser.initialize_pattern
    attr_reader :pattern

    # The Hash of Regexp
    #
    # see also URI::Parser.initialize_regexp
    attr_reader :regexp

    # Returns a split URI against regexp[:ABS_URI]
    def split(uri)
      case uri
      when ''
        # null uri

      when @regexp[:ABS_URI]
        scheme, opaque, userinfo, host, port,
          registry, path, query, fragment = $~[1..-1]

        # URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]

        # absoluteURI   = scheme ":" ( hier_part | opaque_part )
        # hier_part     = ( net_path | abs_path ) [ "?" query ]
        # opaque_part   = uric_no_slash *uric

        # abs_path      = "/"  path_segments
        # net_path      = "//" authority [ abs_path ]

        # authority     = server | reg_name
        # server        = [ [ userinfo "@" ] hostport ]

        if !scheme
          raise InvalidURIError,
            "bad URI(absolute but no scheme): #{uri}"
        end
        if !opaque && (!path && (!host && !registry))
          raise InvalidURIError,
            "bad URI(absolute but no path): #{uri}"
        end

      when @regexp[:REL_URI]
        scheme = nil
        opaque = nil

        userinfo, host, port, registry,
          rel_segment, abs_path, query, fragment = $~[1..-1]
        if rel_segment && abs_path
          path = rel_segment + abs_path
        elsif rel_segment
          path = rel_segment
        elsif abs_path
          path = abs_path
        end

        # URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]

        # relativeURI   = ( net_path | abs_path | rel_path ) [ "?" query ]

        # net_path      = "//" authority [ abs_path ]
        # abs_path      = "/"  path_segments
        # rel_path      = rel_segment [ abs_path ]

        # authority     = server | reg_name
        # server        = [ [ userinfo "@" ] hostport ]

      else
        raise InvalidURIError, "bad URI(is not URI?): #{uri}"
      end

      path = '' if !path && !opaque # (see RFC2396 Section 5.2)
      ret = [
        scheme,
        userinfo, host, port,         # X
        registry,                     # X
        path,                         # Y
        opaque,                       # Y
        query,
        fragment
      ]
      return ret
    end

    #
    # == Args
    #
    # +uri+::
    #    String
    #
    # == Description
    #
    # parses +uri+ and constructs either matching URI scheme object
    # (FTP, HTTP, HTTPS, LDAP, LDAPS, or MailTo) or URI::Generic
    #
    # == Usage
    #
    #   p = URI::Parser.new
    #   p.parse("ldap://ldap.example.com/dc=example?user=john")
    #   #=> #<URI::LDAP:0x00000000b9e7e8 URL:ldap://ldap.example.com/dc=example?user=john>
    #
    def parse(uri)
      scheme, userinfo, host, port,
        registry, path, opaque, query, fragment = self.split(uri)

      if scheme && URI.scheme_list.include?(scheme.upcase)
        URI.scheme_list[scheme.upcase].new(scheme, userinfo, host, port,
                                           registry, path, opaque, query,
                                           fragment, self)
      else
        Generic.new(scheme, userinfo, host, port,
                    registry, path, opaque, query,
                    fragment, self)
      end
    end


    #
    # == Args
    #
    # +uris+::
    #    an Array of Strings
    #
    # == Description
    #
    # Attempts to parse and merge a set of URIs
    #
    def join(*uris)
      uris[0] = convert_to_uri(uris[0])
      uris.inject :merge
    end

    #
    # :call-seq:
    #   extract( str )
    #   extract( str, schemes )
    #   extract( str, schemes ) {|item| block }
    #
    # == Args
    #
    # +str+::
    #    String to search
    # +schemes+::
    #    Patterns to apply to +str+
    #
    # == Description
    #
    # Attempts to parse and merge a set of URIs
    # If no +block+ given , then returns the result,
    # else it calls +block+ for each element in result.
    #
    # see also URI::Parser.make_regexp
    #
    def extract(str, schemes = nil)
      if block_given?
        str.scan(make_regexp(schemes)) { yield $& }
        nil
      else
        result = []
        str.scan(make_regexp(schemes)) { result.push $& }
        result
      end
    end

    # returns Regexp that is default self.regexp[:ABS_URI_REF],
    # unless +schemes+ is provided. Then it is a Regexp.union with self.pattern[:X_ABS_URI]
    def make_regexp(schemes = nil)
      unless schemes
        @regexp[:ABS_URI_REF]
      else
        /(?=#{Regexp.union(*schemes)}:)#{@pattern[:X_ABS_URI]}/x
      end
    end

    #
    # :call-seq:
    #   escape( str )
    #   escape( str, unsafe )
    #
    # == Args
    #
    # +str+::
    #    String to make safe
    # +unsafe+::
    #    Regexp to apply. Defaults to self.regexp[:UNSAFE]
    #
    # == Description
    #
    # constructs a safe String from +str+, removing unsafe characters,
    # replacing them with codes.
    #
    def escape(str, unsafe = @regexp[:UNSAFE])
      unless unsafe.kind_of?(Regexp)
        # perhaps unsafe is String object
        unsafe = Regexp.new("[#{Regexp.quote(unsafe)}]", false)
      end
      str.gsub(unsafe) do
        us = $&
        tmp = ''
        us.each_byte do |uc|
          tmp << sprintf('%%%02X', uc)
        end
        tmp
      end.force_encoding(Encoding::US_ASCII)
    end

    #
    # :call-seq:
    #   unescape( str )
    #   unescape( str, unsafe )
    #
    # == Args
    #
    # +str+::
    #    String to remove escapes from
    # +unsafe+::
    #    Regexp to apply. Defaults to self.regexp[:ESCAPED]
    #
    # == Description
    #
    # Removes escapes from +str+
    #
    def unescape(str, escaped = @regexp[:ESCAPED])
      str.gsub(escaped) { [$&[1, 2].hex].pack('C') }.force_encoding(str.encoding)
    end

    @@to_s = Kernel.instance_method(:to_s)
    def inspect
      @@to_s.bind(self).call
    end

    private

    # Constructs the default Hash of patterns
    def initialize_pattern(opts = {})
      ret = {}
      ret[:ESCAPED] = escaped = (opts.delete(:ESCAPED) || PATTERN::ESCAPED)
      ret[:UNRESERVED] = unreserved = opts.delete(:UNRESERVED) || PATTERN::UNRESERVED
      ret[:RESERVED] = reserved = opts.delete(:RESERVED) || PATTERN::RESERVED
      ret[:DOMLABEL] = opts.delete(:DOMLABEL) || PATTERN::DOMLABEL
      ret[:TOPLABEL] = opts.delete(:TOPLABEL) || PATTERN::TOPLABEL
      ret[:HOSTNAME] = hostname = opts.delete(:HOSTNAME)

      # RFC 2396 (URI Generic Syntax)
      # RFC 2732 (IPv6 Literal Addresses in URL's)
      # RFC 2373 (IPv6 Addressing Architecture)

      # uric          = reserved | unreserved | escaped
      ret[:URIC] = uric = "(?:[#{unreserved}#{reserved}]|#{escaped})"
      # uric_no_slash = unreserved | escaped | ";" | "?" | ":" | "@" |
      #                 "&" | "=" | "+" | "$" | ","
      ret[:URIC_NO_SLASH] = uric_no_slash = "(?:[#{unreserved};?:@&=+$,]|#{escaped})"
      # query         = *uric
      ret[:QUERY] = query = "#{uric}*"
      # fragment      = *uric
      ret[:FRAGMENT] = fragment = "#{uric}*"

      # hostname      = *( domainlabel "." ) toplabel [ "." ]
      # reg-name      = *( unreserved / pct-encoded / sub-delims ) # RFC3986
      unless hostname
        ret[:HOSTNAME] = hostname = "(?:[a-zA-Z0-9\\-.]|%\\h\\h)+"
      end

      # RFC 2373, APPENDIX B:
      # IPv6address = hexpart [ ":" IPv4address ]
      # IPv4address   = 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT
      # hexpart = hexseq | hexseq "::" [ hexseq ] | "::" [ hexseq ]
      # hexseq  = hex4 *( ":" hex4)
      # hex4    = 1*4HEXDIG
      #
      # XXX: This definition has a flaw. "::" + IPv4address must be
      # allowed too.  Here is a replacement.
      #
      # IPv4address = 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT
      ret[:IPV4ADDR] = ipv4addr = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}"
      # hex4     = 1*4HEXDIG
      hex4 = "[#{PATTERN::HEX}]{1,4}"
      # lastpart = hex4 | IPv4address
      lastpart = "(?:#{hex4}|#{ipv4addr})"
      # hexseq1  = *( hex4 ":" ) hex4
      hexseq1 = "(?:#{hex4}:)*#{hex4}"
      # hexseq2  = *( hex4 ":" ) lastpart
      hexseq2 = "(?:#{hex4}:)*#{lastpart}"
      # IPv6address = hexseq2 | [ hexseq1 ] "::" [ hexseq2 ]
      ret[:IPV6ADDR] = ipv6addr = "(?:#{hexseq2}|(?:#{hexseq1})?::(?:#{hexseq2})?)"

      # IPv6prefix  = ( hexseq1 | [ hexseq1 ] "::" [ hexseq1 ] ) "/" 1*2DIGIT
      # unused

      # ipv6reference = "[" IPv6address "]" (RFC 2732)
      ret[:IPV6REF] = ipv6ref = "\\[#{ipv6addr}\\]"

      # host          = hostname | IPv4address
      # host          = hostname | IPv4address | IPv6reference (RFC 2732)
      ret[:HOST] = host = "(?:#{hostname}|#{ipv4addr}|#{ipv6ref})"
      # port          = *digit
      ret[:PORT] = port = '\d*'
      # hostport      = host [ ":" port ]
      ret[:HOSTPORT] = hostport = "#{host}(?::#{port})?"

      # userinfo      = *( unreserved | escaped |
      #                    ";" | ":" | "&" | "=" | "+" | "$" | "," )
      ret[:USERINFO] = userinfo = "(?:[#{unreserved};:&=+$,]|#{escaped})*"

      # pchar         = unreserved | escaped |
      #                 ":" | "@" | "&" | "=" | "+" | "$" | ","
      pchar = "(?:[#{unreserved}:@&=+$,]|#{escaped})"
      # param         = *pchar
      param = "#{pchar}*"
      # segment       = *pchar *( ";" param )
      segment = "#{pchar}*(?:;#{param})*"
      # path_segments = segment *( "/" segment )
      ret[:PATH_SEGMENTS] = path_segments = "#{segment}(?:/#{segment})*"

      # server        = [ [ userinfo "@" ] hostport ]
      server = "(?:#{userinfo}@)?#{hostport}"
      # reg_name      = 1*( unreserved | escaped | "$" | "," |
      #                     ";" | ":" | "@" | "&" | "=" | "+" )
      ret[:REG_NAME] = reg_name = "(?:[#{unreserved}$,;:@&=+]|#{escaped})+"
      # authority     = server | reg_name
      authority = "(?:#{server}|#{reg_name})"

      # rel_segment   = 1*( unreserved | escaped |
      #                     ";" | "@" | "&" | "=" | "+" | "$" | "," )
      ret[:REL_SEGMENT] = rel_segment = "(?:[#{unreserved};@&=+$,]|#{escaped})+"

      # scheme        = alpha *( alpha | digit | "+" | "-" | "." )
      ret[:SCHEME] = scheme = "[#{PATTERN::ALPHA}][\\-+.#{PATTERN::ALPHA}\\d]*"

      # abs_path      = "/"  path_segments
      ret[:ABS_PATH] = abs_path = "/#{path_segments}"
      # rel_path      = rel_segment [ abs_path ]
      ret[:REL_PATH] = rel_path = "#{rel_segment}(?:#{abs_path})?"
      # net_path      = "//" authority [ abs_path ]
      ret[:NET_PATH] = net_path = "//#{authority}(?:#{abs_path})?"

      # hier_part     = ( net_path | abs_path ) [ "?" query ]
      ret[:HIER_PART] = hier_part = "(?:#{net_path}|#{abs_path})(?:\\?(?:#{query}))?"
      # opaque_part   = uric_no_slash *uric
      ret[:OPAQUE_PART] = opaque_part = "#{uric_no_slash}#{uric}*"

      # absoluteURI   = scheme ":" ( hier_part | opaque_part )
      ret[:ABS_URI] = abs_uri = "#{scheme}:(?:#{hier_part}|#{opaque_part})"
      # relativeURI   = ( net_path | abs_path | rel_path ) [ "?" query ]
      ret[:REL_URI] = rel_uri = "(?:#{net_path}|#{abs_path}|#{rel_path})(?:\\?#{query})?"

      # URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]
      ret[:URI_REF] = "(?:#{abs_uri}|#{rel_uri})?(?:##{fragment})?"

      ret[:X_ABS_URI] = "
        (#{scheme}):                           (?# 1: scheme)
        (?:
           (#{opaque_part})                    (?# 2: opaque)
        |
           (?:(?:
             //(?:
                 (?:(?:(#{userinfo})@)?        (?# 3: userinfo)
                   (?:(#{host})(?::(\\d*))?))? (?# 4: host, 5: port)
               |
                 (#{reg_name})                 (?# 6: registry)
               )
             |
             (?!//))                           (?# XXX: '//' is the mark for hostport)
             (#{abs_path})?                    (?# 7: path)
           )(?:\\?(#{query}))?                 (?# 8: query)
        )
        (?:\\#(#{fragment}))?                  (?# 9: fragment)
      "

      ret[:X_REL_URI] = "
        (?:
          (?:
            //
            (?:
              (?:(#{userinfo})@)?       (?# 1: userinfo)
                (#{host})?(?::(\\d*))?  (?# 2: host, 3: port)
            |
              (#{reg_name})             (?# 4: registry)
            )
          )
        |
          (#{rel_segment})              (?# 5: rel_segment)
        )?
        (#{abs_path})?                  (?# 6: abs_path)
        (?:\\?(#{query}))?              (?# 7: query)
        (?:\\#(#{fragment}))?           (?# 8: fragment)
      "

      ret
    end

    # Constructs the default Hash of Regexp's
    def initialize_regexp(pattern)
      ret = {}

      # for URI::split
      ret[:ABS_URI] = Regexp.new('\A\s*' + pattern[:X_ABS_URI] + '\s*\z', Regexp::EXTENDED)
      ret[:REL_URI] = Regexp.new('\A\s*' + pattern[:X_REL_URI] + '\s*\z', Regexp::EXTENDED)

      # for URI::extract
      ret[:URI_REF]     = Regexp.new(pattern[:URI_REF])
      ret[:ABS_URI_REF] = Regexp.new(pattern[:X_ABS_URI], Regexp::EXTENDED)
      ret[:REL_URI_REF] = Regexp.new(pattern[:X_REL_URI], Regexp::EXTENDED)

      # for URI::escape/unescape
      ret[:ESCAPED] = Regexp.new(pattern[:ESCAPED])
      ret[:UNSAFE]  = Regexp.new("[^#{pattern[:UNRESERVED]}#{pattern[:RESERVED]}]")

      # for Generic#initialize
      ret[:SCHEME]   = Regexp.new("\\A#{pattern[:SCHEME]}\\z")
      ret[:USERINFO] = Regexp.new("\\A#{pattern[:USERINFO]}\\z")
      ret[:HOST]     = Regexp.new("\\A#{pattern[:HOST]}\\z")
      ret[:PORT]     = Regexp.new("\\A#{pattern[:PORT]}\\z")
      ret[:OPAQUE]   = Regexp.new("\\A#{pattern[:OPAQUE_PART]}\\z")
      ret[:REGISTRY] = Regexp.new("\\A#{pattern[:REG_NAME]}\\z")
      ret[:ABS_PATH] = Regexp.new("\\A#{pattern[:ABS_PATH]}\\z")
      ret[:REL_PATH] = Regexp.new("\\A#{pattern[:REL_PATH]}\\z")
      ret[:QUERY]    = Regexp.new("\\A#{pattern[:QUERY]}\\z")
      ret[:FRAGMENT] = Regexp.new("\\A#{pattern[:FRAGMENT]}\\z")

      ret
    end

    def convert_to_uri(uri)
      if uri.is_a?(URI::Generic)
        uri
      elsif uri = String.try_convert(uri)
        parse(uri)
      else
        raise ArgumentError,
          "bad argument (expected URI object or URI string)"
      end
    end

  end # class Parser
end # module URI
# frozen_string_literal: false
module URI
  class RFC3986_Parser # :nodoc:
    # URI defined in RFC3986
    # this regexp is modified not to host is not empty string
    RFC3986_URI = /\A(?<URI>(?<scheme>[A-Za-z][+\-.0-9A-Za-z]*):(?<hier-part>\/\/(?<authority>(?:(?<userinfo>(?:%\h\h|[!$&-.0-;=A-Z_a-z~])*)@)?(?<host>(?<IP-literal>\[(?:(?<IPv6address>(?:\h{1,4}:){6}(?<ls32>\h{1,4}:\h{1,4}|(?<IPv4address>(?<dec-octet>[1-9]\d|1\d{2}|2[0-4]\d|25[0-5]|\d)\.\g<dec-octet>\.\g<dec-octet>\.\g<dec-octet>))|::(?:\h{1,4}:){5}\g<ls32>|\h{1,4}?::(?:\h{1,4}:){4}\g<ls32>|(?:(?:\h{1,4}:)?\h{1,4})?::(?:\h{1,4}:){3}\g<ls32>|(?:(?:\h{1,4}:){,2}\h{1,4})?::(?:\h{1,4}:){2}\g<ls32>|(?:(?:\h{1,4}:){,3}\h{1,4})?::\h{1,4}:\g<ls32>|(?:(?:\h{1,4}:){,4}\h{1,4})?::\g<ls32>|(?:(?:\h{1,4}:){,5}\h{1,4})?::\h{1,4}|(?:(?:\h{1,4}:){,6}\h{1,4})?::)|(?<IPvFuture>v\h+\.[!$&-.0-;=A-Z_a-z~]+))\])|\g<IPv4address>|(?<reg-name>(?:%\h\h|[!$&-.0-9;=A-Z_a-z~])+))?(?::(?<port>\d*))?)(?<path-abempty>(?:\/(?<segment>(?:%\h\h|[!$&-.0-;=@-Z_a-z~])*))*)|(?<path-absolute>\/(?:(?<segment-nz>(?:%\h\h|[!$&-.0-;=@-Z_a-z~])+)(?:\/\g<segment>)*)?)|(?<path-rootless>\g<segment-nz>(?:\/\g<segment>)*)|(?<path-empty>))(?:\?(?<query>[^#]*))?(?:\#(?<fragment>(?:%\h\h|[!$&-.0-;=@-Z_a-z~\/?])*))?)\z/
    RFC3986_relative_ref = /\A(?<relative-ref>(?<relative-part>\/\/(?<authority>(?:(?<userinfo>(?:%\h\h|[!$&-.0-;=A-Z_a-z~])*)@)?(?<host>(?<IP-literal>\[(?<IPv6address>(?:\h{1,4}:){6}(?<ls32>\h{1,4}:\h{1,4}|(?<IPv4address>(?<dec-octet>[1-9]\d|1\d{2}|2[0-4]\d|25[0-5]|\d)\.\g<dec-octet>\.\g<dec-octet>\.\g<dec-octet>))|::(?:\h{1,4}:){5}\g<ls32>|\h{1,4}?::(?:\h{1,4}:){4}\g<ls32>|(?:(?:\h{1,4}:){,1}\h{1,4})?::(?:\h{1,4}:){3}\g<ls32>|(?:(?:\h{1,4}:){,2}\h{1,4})?::(?:\h{1,4}:){2}\g<ls32>|(?:(?:\h{1,4}:){,3}\h{1,4})?::\h{1,4}:\g<ls32>|(?:(?:\h{1,4}:){,4}\h{1,4})?::\g<ls32>|(?:(?:\h{1,4}:){,5}\h{1,4})?::\h{1,4}|(?:(?:\h{1,4}:){,6}\h{1,4})?::)|(?<IPvFuture>v\h+\.[!$&-.0-;=A-Z_a-z~]+)\])|\g<IPv4address>|(?<reg-name>(?:%\h\h|[!$&-.0-9;=A-Z_a-z~])+))?(?::(?<port>\d*))?)(?<path-abempty>(?:\/(?<segment>(?:%\h\h|[!$&-.0-;=@-Z_a-z~])*))*)|(?<path-absolute>\/(?:(?<segment-nz>(?:%\h\h|[!$&-.0-;=@-Z_a-z~])+)(?:\/\g<segment>)*)?)|(?<path-noscheme>(?<segment-nz-nc>(?:%\h\h|[!$&-.0-9;=@-Z_a-z~])+)(?:\/\g<segment>)*)|(?<path-empty>))(?:\?(?<query>[^#]*))?(?:\#(?<fragment>(?:%\h\h|[!$&-.0-;=@-Z_a-z~\/?])*))?)\z/
    attr_reader :regexp

    def initialize
      @regexp = default_regexp.each_value(&:freeze).freeze
    end

    def split(uri) #:nodoc:
      begin
        uri = uri.to_str
      rescue NoMethodError
        raise InvalidURIError, "bad URI(is not URI?): #{uri}"
      end
      uri.ascii_only? or
        raise InvalidURIError, "URI must be ascii only #{uri.dump}"
      if m = RFC3986_URI.match(uri)
        query = m["query".freeze]
        scheme = m["scheme".freeze]
        opaque = m["path-rootless".freeze]
        if opaque
          opaque << "?#{query}" if query
          [ scheme,
            nil, # userinfo
            nil, # host
            nil, # port
            nil, # registry
            nil, # path
            opaque,
            nil, # query
            m["fragment".freeze]
          ]
        else # normal
          [ scheme,
            m["userinfo".freeze],
            m["host".freeze],
            m["port".freeze],
            nil, # registry
            (m["path-abempty".freeze] ||
             m["path-absolute".freeze] ||
             m["path-empty".freeze]),
            nil, # opaque
            query,
            m["fragment".freeze]
          ]
        end
      elsif m = RFC3986_relative_ref.match(uri)
        [ nil, # scheme
          m["userinfo".freeze],
          m["host".freeze],
          m["port".freeze],
          nil, # registry,
          (m["path-abempty".freeze] ||
           m["path-absolute".freeze] ||
           m["path-noscheme".freeze] ||
           m["path-empty".freeze]),
          nil, # opaque
          m["query".freeze],
          m["fragment".freeze]
        ]
      else
        raise InvalidURIError, "bad URI(is not URI?): #{uri}"
      end
    end

    def parse(uri) # :nodoc:
      scheme, userinfo, host, port,
        registry, path, opaque, query, fragment = self.split(uri)
      scheme_list = URI.scheme_list
      if scheme && scheme_list.include?(uc = scheme.upcase)
        scheme_list[uc].new(scheme, userinfo, host, port,
                            registry, path, opaque, query,
                            fragment, self)
      else
        Generic.new(scheme, userinfo, host, port,
                    registry, path, opaque, query,
                    fragment, self)
      end
    end


    def join(*uris) # :nodoc:
      uris[0] = convert_to_uri(uris[0])
      uris.inject :merge
    end

    @@to_s = Kernel.instance_method(:to_s)
    def inspect
      @@to_s.bind(self).call
    end

    private

    def default_regexp # :nodoc:
      {
        SCHEME: /\A[A-Za-z][A-Za-z0-9+\-.]*\z/,
        USERINFO: /\A(?:%\h\h|[!$&-.0-;=A-Z_a-z~])*\z/,
        HOST: /\A(?:(?<IP-literal>\[(?:(?<IPv6address>(?:\h{1,4}:){6}(?<ls32>\h{1,4}:\h{1,4}|(?<IPv4address>(?<dec-octet>[1-9]\d|1\d{2}|2[0-4]\d|25[0-5]|\d)\.\g<dec-octet>\.\g<dec-octet>\.\g<dec-octet>))|::(?:\h{1,4}:){5}\g<ls32>|\h{,4}::(?:\h{1,4}:){4}\g<ls32>|(?:(?:\h{1,4}:)?\h{1,4})?::(?:\h{1,4}:){3}\g<ls32>|(?:(?:\h{1,4}:){,2}\h{1,4})?::(?:\h{1,4}:){2}\g<ls32>|(?:(?:\h{1,4}:){,3}\h{1,4})?::\h{1,4}:\g<ls32>|(?:(?:\h{1,4}:){,4}\h{1,4})?::\g<ls32>|(?:(?:\h{1,4}:){,5}\h{1,4})?::\h{1,4}|(?:(?:\h{1,4}:){,6}\h{1,4})?::)|(?<IPvFuture>v\h+\.[!$&-.0-;=A-Z_a-z~]+))\])|\g<IPv4address>|(?<reg-name>(?:%\h\h|[!$&-.0-9;=A-Z_a-z~])*))\z/,
        ABS_PATH: /\A\/(?:%\h\h|[!$&-.0-;=@-Z_a-z~])*(?:\/(?:%\h\h|[!$&-.0-;=@-Z_a-z~])*)*\z/,
        REL_PATH: /\A(?:%\h\h|[!$&-.0-;=@-Z_a-z~])+(?:\/(?:%\h\h|[!$&-.0-;=@-Z_a-z~])*)*\z/,
        QUERY: /\A(?:%\h\h|[!$&-.0-;=@-Z_a-z~\/?])*\z/,
        FRAGMENT: /\A(?:%\h\h|[!$&-.0-;=@-Z_a-z~\/?])*\z/,
        OPAQUE: /\A(?:[^\/].*)?\z/,
        PORT: /\A[\x09\x0a\x0c\x0d ]*\d*[\x09\x0a\x0c\x0d ]*\z/,
      }
    end

    def convert_to_uri(uri)
      if uri.is_a?(URI::Generic)
        uri
      elsif uri = String.try_convert(uri)
        parse(uri)
      else
        raise ArgumentError,
          "bad argument (expected URI object or URI string)"
      end
    end

  end # class Parser
end # module URI
# frozen_string_literal: false
#--
# = uri/common.rb
#
# Author:: Akira Yamada <akira@ruby-lang.org>
# Revision:: $Id: common.rb 61155 2017-12-12 11:56:25Z shyouhei $
# License::
#   You can redistribute it and/or modify it under the same term as Ruby.
#
# See URI for general documentation
#

module URI
  REGEXP = RFC2396_REGEXP
  Parser = RFC2396_Parser
  RFC3986_PARSER = RFC3986_Parser.new

  # URI::Parser.new
  DEFAULT_PARSER = Parser.new
  DEFAULT_PARSER.pattern.each_pair do |sym, str|
    unless REGEXP::PATTERN.const_defined?(sym)
      REGEXP::PATTERN.const_set(sym, str)
    end
  end
  DEFAULT_PARSER.regexp.each_pair do |sym, str|
    const_set(sym, str)
  end

  module Util # :nodoc:
    def make_components_hash(klass, array_hash)
      tmp = {}
      if array_hash.kind_of?(Array) &&
          array_hash.size == klass.component.size - 1
        klass.component[1..-1].each_index do |i|
          begin
            tmp[klass.component[i + 1]] = array_hash[i].clone
          rescue TypeError
            tmp[klass.component[i + 1]] = array_hash[i]
          end
        end

      elsif array_hash.kind_of?(Hash)
        array_hash.each do |key, value|
          begin
            tmp[key] = value.clone
          rescue TypeError
            tmp[key] = value
          end
        end
      else
        raise ArgumentError,
          "expected Array of or Hash of components of #{klass} (#{klass.component[1..-1].join(', ')})"
      end
      tmp[:scheme] = klass.to_s.sub(/\A.*::/, '').downcase

      return tmp
    end
    module_function :make_components_hash
  end

  # module for escaping unsafe characters with codes.
  module Escape
    #
    # == Synopsis
    #
    #   URI.escape(str [, unsafe])
    #
    # == Args
    #
    # +str+::
    #   String to replaces in.
    # +unsafe+::
    #   Regexp that matches all symbols that must be replaced with codes.
    #   By default uses <tt>UNSAFE</tt>.
    #   When this argument is a String, it represents a character set.
    #
    # == Description
    #
    # Escapes the string, replacing all unsafe characters with codes.
    #
    # This method is obsolete and should not be used. Instead, use
    # CGI.escape, URI.encode_www_form or URI.encode_www_form_component
    # depending on your specific use case.
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   enc_uri = URI.escape("http://example.com/?a=\11\15")
    #   p enc_uri
    #   # => "http://example.com/?a=%09%0D"
    #
    #   p URI.unescape(enc_uri)
    #   # => "http://example.com/?a=\t\r"
    #
    #   p URI.escape("@?@!", "!?")
    #   # => "@%3F@%21"
    #
    def escape(*arg)
      warn "URI.escape is obsolete", uplevel: 1 if $VERBOSE
      DEFAULT_PARSER.escape(*arg)
    end
    alias encode escape
    #
    # == Synopsis
    #
    #   URI.unescape(str)
    #
    # == Args
    #
    # +str+::
    #   Unescapes the string.
    #
    # == Description
    #
    # This method is obsolete and should not be used. Instead, use
    # CGI.unescape, URI.decode_www_form or URI.decode_www_form_component
    # depending on your specific use case.
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   enc_uri = URI.escape("http://example.com/?a=\11\15")
    #   p enc_uri
    #   # => "http://example.com/?a=%09%0D"
    #
    #   p URI.unescape(enc_uri)
    #   # => "http://example.com/?a=\t\r"
    #
    def unescape(*arg)
      warn "URI.unescape is obsolete", uplevel: 1 if $VERBOSE
      DEFAULT_PARSER.unescape(*arg)
    end
    alias decode unescape
  end # module Escape

  extend Escape
  include REGEXP

  @@schemes = {}
  # Returns a Hash of the defined schemes
  def self.scheme_list
    @@schemes
  end

  #
  # Base class for all URI exceptions.
  #
  class Error < StandardError; end
  #
  # Not a URI.
  #
  class InvalidURIError < Error; end
  #
  # Not a URI component.
  #
  class InvalidComponentError < Error; end
  #
  # URI is valid, bad usage is not.
  #
  class BadURIError < Error; end

  #
  # == Synopsis
  #
  #   URI::split(uri)
  #
  # == Args
  #
  # +uri+::
  #   String with URI.
  #
  # == Description
  #
  # Splits the string on following parts and returns array with result:
  #
  #   * Scheme
  #   * Userinfo
  #   * Host
  #   * Port
  #   * Registry
  #   * Path
  #   * Opaque
  #   * Query
  #   * Fragment
  #
  # == Usage
  #
  #   require 'uri'
  #
  #   p URI.split("http://www.ruby-lang.org/")
  #   # => ["http", nil, "www.ruby-lang.org", nil, nil, "/", nil, nil, nil]
  #
  def self.split(uri)
    RFC3986_PARSER.split(uri)
  end

  #
  # == Synopsis
  #
  #   URI::parse(uri_str)
  #
  # == Args
  #
  # +uri_str+::
  #   String with URI.
  #
  # == Description
  #
  # Creates one of the URI's subclasses instance from the string.
  #
  # == Raises
  #
  # URI::InvalidURIError
  #   Raised if URI given is not a correct one.
  #
  # == Usage
  #
  #   require 'uri'
  #
  #   uri = URI.parse("http://www.ruby-lang.org/")
  #   p uri
  #   # => #<URI::HTTP:0x202281be URL:http://www.ruby-lang.org/>
  #   p uri.scheme
  #   # => "http"
  #   p uri.host
  #   # => "www.ruby-lang.org"
  #
  # It's recommended to first ::escape the provided +uri_str+ if there are any
  # invalid URI characters.
  #
  def self.parse(uri)
    RFC3986_PARSER.parse(uri)
  end

  #
  # == Synopsis
  #
  #   URI::join(str[, str, ...])
  #
  # == Args
  #
  # +str+::
  #   String(s) to work with, will be converted to RFC3986 URIs before merging.
  #
  # == Description
  #
  # Joins URIs.
  #
  # == Usage
  #
  #   require 'uri'
  #
  #   p URI.join("http://example.com/","main.rbx")
  #   # => #<URI::HTTP:0x2022ac02 URL:http://example.com/main.rbx>
  #
  #   p URI.join('http://example.com', 'foo')
  #   # => #<URI::HTTP:0x01ab80a0 URL:http://example.com/foo>
  #
  #   p URI.join('http://example.com', '/foo', '/bar')
  #   # => #<URI::HTTP:0x01aaf0b0 URL:http://example.com/bar>
  #
  #   p URI.join('http://example.com', '/foo', 'bar')
  #   # => #<URI::HTTP:0x801a92af0 URL:http://example.com/bar>
  #
  #   p URI.join('http://example.com', '/foo/', 'bar')
  #   # => #<URI::HTTP:0x80135a3a0 URL:http://example.com/foo/bar>
  #
  #
  def self.join(*str)
    RFC3986_PARSER.join(*str)
  end

  #
  # == Synopsis
  #
  #   URI::extract(str[, schemes][,&blk])
  #
  # == Args
  #
  # +str+::
  #   String to extract URIs from.
  # +schemes+::
  #   Limit URI matching to a specific schemes.
  #
  # == Description
  #
  # Extracts URIs from a string. If block given, iterates through all matched URIs.
  # Returns nil if block given or array with matches.
  #
  # == Usage
  #
  #   require "uri"
  #
  #   URI.extract("text here http://foo.example.org/bla and here mailto:test@example.com and here also.")
  #   # => ["http://foo.example.com/bla", "mailto:test@example.com"]
  #
  def self.extract(str, schemes = nil, &block)
    warn "URI.extract is obsolete", uplevel: 1 if $VERBOSE
    DEFAULT_PARSER.extract(str, schemes, &block)
  end

  #
  # == Synopsis
  #
  #   URI::regexp([match_schemes])
  #
  # == Args
  #
  # +match_schemes+::
  #   Array of schemes. If given, resulting regexp matches to URIs
  #   whose scheme is one of the match_schemes.
  #
  # == Description
  # Returns a Regexp object which matches to URI-like strings.
  # The Regexp object returned by this method includes arbitrary
  # number of capture group (parentheses).  Never rely on it's number.
  #
  # == Usage
  #
  #   require 'uri'
  #
  #   # extract first URI from html_string
  #   html_string.slice(URI.regexp)
  #
  #   # remove ftp URIs
  #   html_string.sub(URI.regexp(['ftp'])
  #
  #   # You should not rely on the number of parentheses
  #   html_string.scan(URI.regexp) do |*matches|
  #     p $&
  #   end
  #
  def self.regexp(schemes = nil)
    warn "URI.regexp is obsolete", uplevel: 1 if $VERBOSE
    DEFAULT_PARSER.make_regexp(schemes)
  end

  TBLENCWWWCOMP_ = {} # :nodoc:
  256.times do |i|
    TBLENCWWWCOMP_[i.chr] = '%%%02X' % i
  end
  TBLENCWWWCOMP_[' '] = '+'
  TBLENCWWWCOMP_.freeze
  TBLDECWWWCOMP_ = {} # :nodoc:
  256.times do |i|
    h, l = i>>4, i&15
    TBLDECWWWCOMP_['%%%X%X' % [h, l]] = i.chr
    TBLDECWWWCOMP_['%%%x%X' % [h, l]] = i.chr
    TBLDECWWWCOMP_['%%%X%x' % [h, l]] = i.chr
    TBLDECWWWCOMP_['%%%x%x' % [h, l]] = i.chr
  end
  TBLDECWWWCOMP_['+'] = ' '
  TBLDECWWWCOMP_.freeze

  HTML5ASCIIINCOMPAT = defined? Encoding::UTF_7 ? [Encoding::UTF_7, Encoding::UTF_16BE, Encoding::UTF_16LE,
    Encoding::UTF_32BE, Encoding::UTF_32LE] : [] # :nodoc:

  # Encode given +str+ to URL-encoded form data.
  #
  # This method doesn't convert *, -, ., 0-9, A-Z, _, a-z, but does convert SP
  # (ASCII space) to + and converts others to %XX.
  #
  # If +enc+ is given, convert +str+ to the encoding before percent encoding.
  #
  # This is an implementation of
  # http://www.w3.org/TR/2013/CR-html5-20130806/forms.html#url-encoded-form-data
  #
  # See URI.decode_www_form_component, URI.encode_www_form
  def self.encode_www_form_component(str, enc=nil)
    str = str.to_s.dup
    if str.encoding != Encoding::ASCII_8BIT
      if enc && enc != Encoding::ASCII_8BIT
        str.encode!(Encoding::UTF_8, invalid: :replace, undef: :replace)
        str.encode!(enc, fallback: ->(x){"&#{x.ord};"})
      end
      str.force_encoding(Encoding::ASCII_8BIT)
    end
    str.gsub!(/[^*\-.0-9A-Z_a-z]/, TBLENCWWWCOMP_)
    str.force_encoding(Encoding::US_ASCII)
  end

  # Decode given +str+ of URL-encoded form data.
  #
  # This decodes + to SP.
  #
  # See URI.encode_www_form_component, URI.decode_www_form
  def self.decode_www_form_component(str, enc=Encoding::UTF_8)
    raise ArgumentError, "invalid %-encoding (#{str})" if /%(?!\h\h)/ =~ str
    str.b.gsub(/\+|%\h\h/, TBLDECWWWCOMP_).force_encoding(enc)
  end

  # Generate URL-encoded form data from given +enum+.
  #
  # This generates application/x-www-form-urlencoded data defined in HTML5
  # from given an Enumerable object.
  #
  # This internally uses URI.encode_www_form_component(str).
  #
  # This method doesn't convert the encoding of given items, so convert them
  # before call this method if you want to send data as other than original
  # encoding or mixed encoding data. (Strings which are encoded in an HTML5
  # ASCII incompatible encoding are converted to UTF-8.)
  #
  # This method doesn't handle files.  When you send a file, use
  # multipart/form-data.
  #
  # This refers http://url.spec.whatwg.org/#concept-urlencoded-serializer
  #
  #    URI.encode_www_form([["q", "ruby"], ["lang", "en"]])
  #    #=> "q=ruby&lang=en"
  #    URI.encode_www_form("q" => "ruby", "lang" => "en")
  #    #=> "q=ruby&lang=en"
  #    URI.encode_www_form("q" => ["ruby", "perl"], "lang" => "en")
  #    #=> "q=ruby&q=perl&lang=en"
  #    URI.encode_www_form([["q", "ruby"], ["q", "perl"], ["lang", "en"]])
  #    #=> "q=ruby&q=perl&lang=en"
  #
  # See URI.encode_www_form_component, URI.decode_www_form
  def self.encode_www_form(enum, enc=nil)
    enum.map do |k,v|
      if v.nil?
        encode_www_form_component(k, enc)
      elsif v.respond_to?(:to_ary)
        v.to_ary.map do |w|
          str = encode_www_form_component(k, enc)
          unless w.nil?
            str << '='
            str << encode_www_form_component(w, enc)
          end
        end.join('&')
      else
        str = encode_www_form_component(k, enc)
        str << '='
        str << encode_www_form_component(v, enc)
      end
    end.join('&')
  end

  # Decode URL-encoded form data from given +str+.
  #
  # This decodes application/x-www-form-urlencoded data
  # and returns array of key-value array.
  #
  # This refers http://url.spec.whatwg.org/#concept-urlencoded-parser ,
  # so this supports only &-separator, don't support ;-separator.
  #
  #    ary = URI.decode_www_form("a=1&a=2&b=3")
  #    p ary                  #=> [['a', '1'], ['a', '2'], ['b', '3']]
  #    p ary.assoc('a').last  #=> '1'
  #    p ary.assoc('b').last  #=> '3'
  #    p ary.rassoc('a').last #=> '2'
  #    p Hash[ary]            # => {"a"=>"2", "b"=>"3"}
  #
  # See URI.decode_www_form_component, URI.encode_www_form
  def self.decode_www_form(str, enc=Encoding::UTF_8, separator: '&', use__charset_: false, isindex: false)
    raise ArgumentError, "the input of #{self.name}.#{__method__} must be ASCII only string" unless str.ascii_only?
    ary = []
    return ary if str.empty?
    enc = Encoding.find(enc)
    str.b.each_line(separator) do |string|
      string.chomp!(separator)
      key, sep, val = string.partition('=')
      if isindex
        if sep.empty?
          val = key
          key = ''
        end
        isindex = false
      end

      if use__charset_ and key == '_charset_' and e = get_encoding(val)
        enc = e
        use__charset_ = false
      end

      key.gsub!(/\+|%\h\h/, TBLDECWWWCOMP_)
      if val
        val.gsub!(/\+|%\h\h/, TBLDECWWWCOMP_)
      else
        val = ''
      end

      ary << [key, val]
    end
    ary.each do |k, v|
      k.force_encoding(enc)
      k.scrub!
      v.force_encoding(enc)
      v.scrub!
    end
    ary
  end

  private
=begin command for WEB_ENCODINGS_
  curl https://encoding.spec.whatwg.org/encodings.json|
  ruby -rjson -e 'H={}
  h={
    "shift_jis"=>"Windows-31J",
    "euc-jp"=>"cp51932",
    "iso-2022-jp"=>"cp50221",
    "x-mac-cyrillic"=>"macCyrillic",
  }
  JSON($<.read).map{|x|x["encodings"]}.flatten.each{|x|
    Encoding.find(n=h.fetch(n=x["name"].downcase,n))rescue next
    x["labels"].each{|y|H[y]=n}
  }
  puts "{"
  H.each{|k,v|puts %[  #{k.dump}=>#{v.dump},]}
  puts "}"
'
=end
  WEB_ENCODINGS_ = {
    "unicode-1-1-utf-8"=>"utf-8",
    "utf-8"=>"utf-8",
    "utf8"=>"utf-8",
    "866"=>"ibm866",
    "cp866"=>"ibm866",
    "csibm866"=>"ibm866",
    "ibm866"=>"ibm866",
    "csisolatin2"=>"iso-8859-2",
    "iso-8859-2"=>"iso-8859-2",
    "iso-ir-101"=>"iso-8859-2",
    "iso8859-2"=>"iso-8859-2",
    "iso88592"=>"iso-8859-2",
    "iso_8859-2"=>"iso-8859-2",
    "iso_8859-2:1987"=>"iso-8859-2",
    "l2"=>"iso-8859-2",
    "latin2"=>"iso-8859-2",
    "csisolatin3"=>"iso-8859-3",
    "iso-8859-3"=>"iso-8859-3",
    "iso-ir-109"=>"iso-8859-3",
    "iso8859-3"=>"iso-8859-3",
    "iso88593"=>"iso-8859-3",
    "iso_8859-3"=>"iso-8859-3",
    "iso_8859-3:1988"=>"iso-8859-3",
    "l3"=>"iso-8859-3",
    "latin3"=>"iso-8859-3",
    "csisolatin4"=>"iso-8859-4",
    "iso-8859-4"=>"iso-8859-4",
    "iso-ir-110"=>"iso-8859-4",
    "iso8859-4"=>"iso-8859-4",
    "iso88594"=>"iso-8859-4",
    "iso_8859-4"=>"iso-8859-4",
    "iso_8859-4:1988"=>"iso-8859-4",
    "l4"=>"iso-8859-4",
    "latin4"=>"iso-8859-4",
    "csisolatincyrillic"=>"iso-8859-5",
    "cyrillic"=>"iso-8859-5",
    "iso-8859-5"=>"iso-8859-5",
    "iso-ir-144"=>"iso-8859-5",
    "iso8859-5"=>"iso-8859-5",
    "iso88595"=>"iso-8859-5",
    "iso_8859-5"=>"iso-8859-5",
    "iso_8859-5:1988"=>"iso-8859-5",
    "arabic"=>"iso-8859-6",
    "asmo-708"=>"iso-8859-6",
    "csiso88596e"=>"iso-8859-6",
    "csiso88596i"=>"iso-8859-6",
    "csisolatinarabic"=>"iso-8859-6",
    "ecma-114"=>"iso-8859-6",
    "iso-8859-6"=>"iso-8859-6",
    "iso-8859-6-e"=>"iso-8859-6",
    "iso-8859-6-i"=>"iso-8859-6",
    "iso-ir-127"=>"iso-8859-6",
    "iso8859-6"=>"iso-8859-6",
    "iso88596"=>"iso-8859-6",
    "iso_8859-6"=>"iso-8859-6",
    "iso_8859-6:1987"=>"iso-8859-6",
    "csisolatingreek"=>"iso-8859-7",
    "ecma-118"=>"iso-8859-7",
    "elot_928"=>"iso-8859-7",
    "greek"=>"iso-8859-7",
    "greek8"=>"iso-8859-7",
    "iso-8859-7"=>"iso-8859-7",
    "iso-ir-126"=>"iso-8859-7",
    "iso8859-7"=>"iso-8859-7",
    "iso88597"=>"iso-8859-7",
    "iso_8859-7"=>"iso-8859-7",
    "iso_8859-7:1987"=>"iso-8859-7",
    "sun_eu_greek"=>"iso-8859-7",
    "csiso88598e"=>"iso-8859-8",
    "csisolatinhebrew"=>"iso-8859-8",
    "hebrew"=>"iso-8859-8",
    "iso-8859-8"=>"iso-8859-8",
    "iso-8859-8-e"=>"iso-8859-8",
    "iso-ir-138"=>"iso-8859-8",
    "iso8859-8"=>"iso-8859-8",
    "iso88598"=>"iso-8859-8",
    "iso_8859-8"=>"iso-8859-8",
    "iso_8859-8:1988"=>"iso-8859-8",
    "visual"=>"iso-8859-8",
    "csisolatin6"=>"iso-8859-10",
    "iso-8859-10"=>"iso-8859-10",
    "iso-ir-157"=>"iso-8859-10",
    "iso8859-10"=>"iso-8859-10",
    "iso885910"=>"iso-8859-10",
    "l6"=>"iso-8859-10",
    "latin6"=>"iso-8859-10",
    "iso-8859-13"=>"iso-8859-13",
    "iso8859-13"=>"iso-8859-13",
    "iso885913"=>"iso-8859-13",
    "iso-8859-14"=>"iso-8859-14",
    "iso8859-14"=>"iso-8859-14",
    "iso885914"=>"iso-8859-14",
    "csisolatin9"=>"iso-8859-15",
    "iso-8859-15"=>"iso-8859-15",
    "iso8859-15"=>"iso-8859-15",
    "iso885915"=>"iso-8859-15",
    "iso_8859-15"=>"iso-8859-15",
    "l9"=>"iso-8859-15",
    "iso-8859-16"=>"iso-8859-16",
    "cskoi8r"=>"koi8-r",
    "koi"=>"koi8-r",
    "koi8"=>"koi8-r",
    "koi8-r"=>"koi8-r",
    "koi8_r"=>"koi8-r",
    "koi8-ru"=>"koi8-u",
    "koi8-u"=>"koi8-u",
    "dos-874"=>"windows-874",
    "iso-8859-11"=>"windows-874",
    "iso8859-11"=>"windows-874",
    "iso885911"=>"windows-874",
    "tis-620"=>"windows-874",
    "windows-874"=>"windows-874",
    "cp1250"=>"windows-1250",
    "windows-1250"=>"windows-1250",
    "x-cp1250"=>"windows-1250",
    "cp1251"=>"windows-1251",
    "windows-1251"=>"windows-1251",
    "x-cp1251"=>"windows-1251",
    "ansi_x3.4-1968"=>"windows-1252",
    "ascii"=>"windows-1252",
    "cp1252"=>"windows-1252",
    "cp819"=>"windows-1252",
    "csisolatin1"=>"windows-1252",
    "ibm819"=>"windows-1252",
    "iso-8859-1"=>"windows-1252",
    "iso-ir-100"=>"windows-1252",
    "iso8859-1"=>"windows-1252",
    "iso88591"=>"windows-1252",
    "iso_8859-1"=>"windows-1252",
    "iso_8859-1:1987"=>"windows-1252",
    "l1"=>"windows-1252",
    "latin1"=>"windows-1252",
    "us-ascii"=>"windows-1252",
    "windows-1252"=>"windows-1252",
    "x-cp1252"=>"windows-1252",
    "cp1253"=>"windows-1253",
    "windows-1253"=>"windows-1253",
    "x-cp1253"=>"windows-1253",
    "cp1254"=>"windows-1254",
    "csisolatin5"=>"windows-1254",
    "iso-8859-9"=>"windows-1254",
    "iso-ir-148"=>"windows-1254",
    "iso8859-9"=>"windows-1254",
    "iso88599"=>"windows-1254",
    "iso_8859-9"=>"windows-1254",
    "iso_8859-9:1989"=>"windows-1254",
    "l5"=>"windows-1254",
    "latin5"=>"windows-1254",
    "windows-1254"=>"windows-1254",
    "x-cp1254"=>"windows-1254",
    "cp1255"=>"windows-1255",
    "windows-1255"=>"windows-1255",
    "x-cp1255"=>"windows-1255",
    "cp1256"=>"windows-1256",
    "windows-1256"=>"windows-1256",
    "x-cp1256"=>"windows-1256",
    "cp1257"=>"windows-1257",
    "windows-1257"=>"windows-1257",
    "x-cp1257"=>"windows-1257",
    "cp1258"=>"windows-1258",
    "windows-1258"=>"windows-1258",
    "x-cp1258"=>"windows-1258",
    "x-mac-cyrillic"=>"macCyrillic",
    "x-mac-ukrainian"=>"macCyrillic",
    "chinese"=>"gbk",
    "csgb2312"=>"gbk",
    "csiso58gb231280"=>"gbk",
    "gb2312"=>"gbk",
    "gb_2312"=>"gbk",
    "gb_2312-80"=>"gbk",
    "gbk"=>"gbk",
    "iso-ir-58"=>"gbk",
    "x-gbk"=>"gbk",
    "gb18030"=>"gb18030",
    "big5"=>"big5",
    "big5-hkscs"=>"big5",
    "cn-big5"=>"big5",
    "csbig5"=>"big5",
    "x-x-big5"=>"big5",
    "cseucpkdfmtjapanese"=>"cp51932",
    "euc-jp"=>"cp51932",
    "x-euc-jp"=>"cp51932",
    "csiso2022jp"=>"cp50221",
    "iso-2022-jp"=>"cp50221",
    "csshiftjis"=>"Windows-31J",
    "ms932"=>"Windows-31J",
    "ms_kanji"=>"Windows-31J",
    "shift-jis"=>"Windows-31J",
    "shift_jis"=>"Windows-31J",
    "sjis"=>"Windows-31J",
    "windows-31j"=>"Windows-31J",
    "x-sjis"=>"Windows-31J",
    "cseuckr"=>"euc-kr",
    "csksc56011987"=>"euc-kr",
    "euc-kr"=>"euc-kr",
    "iso-ir-149"=>"euc-kr",
    "korean"=>"euc-kr",
    "ks_c_5601-1987"=>"euc-kr",
    "ks_c_5601-1989"=>"euc-kr",
    "ksc5601"=>"euc-kr",
    "ksc_5601"=>"euc-kr",
    "windows-949"=>"euc-kr",
    "utf-16be"=>"utf-16be",
    "utf-16"=>"utf-16le",
    "utf-16le"=>"utf-16le",
  } # :nodoc:

  # :nodoc:
  # return encoding or nil
  # http://encoding.spec.whatwg.org/#concept-encoding-get
  def self.get_encoding(label)
    Encoding.find(WEB_ENCODINGS_[label.to_str.strip.downcase]) rescue nil
  end
end # module URI

module Kernel

  #
  # Returns +uri+ converted to a URI object.
  #
  def URI(uri)
    if uri.is_a?(URI::Generic)
      uri
    elsif uri = String.try_convert(uri)
      URI.parse(uri)
    else
      raise ArgumentError,
        "bad argument (expected URI object or URI string)"
    end
  end
  module_function :URI
end
# frozen_string_literal: true

# = uri/generic.rb
#
# Author:: Akira Yamada <akira@ruby-lang.org>
# License:: You can redistribute it and/or modify it under the same term as Ruby.
# Revision:: $Id: generic.rb 61225 2017-12-14 06:30:22Z naruse $
#
# See URI for general documentation
#

autoload :IPSocket, 'socket'
autoload :IPAddr, 'ipaddr'

module URI

  #
  # Base class for all URI classes.
  # Implements generic URI syntax as per RFC 2396.
  #
  class Generic
    include URI

    #
    # A Default port of nil for URI::Generic
    #
    DEFAULT_PORT = nil

    #
    # Returns default port
    #
    def self.default_port
      self::DEFAULT_PORT
    end

    #
    # Returns default port
    #
    def default_port
      self.class.default_port
    end

    #
    # An Array of the available components for URI::Generic
    #
    COMPONENT = [
      :scheme,
      :userinfo, :host, :port, :registry,
      :path, :opaque,
      :query,
      :fragment
    ].freeze

    #
    # Components of the URI in the order.
    #
    def self.component
      self::COMPONENT
    end

    USE_REGISTRY = false # :nodoc:

    def self.use_registry # :nodoc:
      self::USE_REGISTRY
    end

    #
    # == Synopsis
    #
    # See #new
    #
    # == Description
    #
    # At first, tries to create a new URI::Generic instance using
    # URI::Generic::build. But, if exception URI::InvalidComponentError is raised,
    # then it URI::Escape.escape all URI components and tries again.
    #
    #
    def self.build2(args)
      begin
        return self.build(args)
      rescue InvalidComponentError
        if args.kind_of?(Array)
          return self.build(args.collect{|x|
            if x.is_a?(String)
              DEFAULT_PARSER.escape(x)
            else
              x
            end
          })
        elsif args.kind_of?(Hash)
          tmp = {}
          args.each do |key, value|
            tmp[key] = if value
                DEFAULT_PARSER.escape(value)
              else
                value
              end
          end
          return self.build(tmp)
        end
      end
    end

    #
    # == Synopsis
    #
    # See #new
    #
    # == Description
    #
    # Creates a new URI::Generic instance from components of URI::Generic
    # with check.  Components are: scheme, userinfo, host, port, registry, path,
    # opaque, query and fragment. You can provide arguments either by an Array or a Hash.
    # See #new for hash keys to use or for order of array items.
    #
    def self.build(args)
      if args.kind_of?(Array) &&
          args.size == ::URI::Generic::COMPONENT.size
        tmp = args.dup
      elsif args.kind_of?(Hash)
        tmp = ::URI::Generic::COMPONENT.collect do |c|
          if args.include?(c)
            args[c]
          else
            nil
          end
        end
      else
        component = self.class.component rescue ::URI::Generic::COMPONENT
        raise ArgumentError,
        "expected Array of or Hash of components of #{self.class} (#{component.join(', ')})"
      end

      tmp << nil
      tmp << true
      return self.new(*tmp)
    end
    #
    # == Args
    #
    # +scheme+::
    #   Protocol scheme, i.e. 'http','ftp','mailto' and so on.
    # +userinfo+::
    #   User name and password, i.e. 'sdmitry:bla'
    # +host+::
    #   Server host name
    # +port+::
    #   Server port
    # +registry+::
    #   Registry of naming authorities.
    # +path+::
    #   Path on server
    # +opaque+::
    #   Opaque part
    # +query+::
    #   Query data
    # +fragment+::
    #   A part of URI after '#' sign
    # +parser+::
    #   Parser for internal use [URI::DEFAULT_PARSER by default]
    # +arg_check+::
    #   Check arguments [false by default]
    #
    # == Description
    #
    # Creates a new URI::Generic instance from ``generic'' components without check.
    #
    def initialize(scheme,
                   userinfo, host, port, registry,
                   path, opaque,
                   query,
                   fragment,
                   parser = DEFAULT_PARSER,
                   arg_check = false)
      @scheme = nil
      @user = nil
      @password = nil
      @host = nil
      @port = nil
      @path = nil
      @query = nil
      @opaque = nil
      @fragment = nil
      @parser = parser == DEFAULT_PARSER ? nil : parser

      if arg_check
        self.scheme = scheme
        self.userinfo = userinfo
        self.hostname = host
        self.port = port
        self.path = path
        self.query = query
        self.opaque = opaque
        self.fragment = fragment
      else
        self.set_scheme(scheme)
        self.set_userinfo(userinfo)
        self.set_host(host)
        self.set_port(port)
        self.set_path(path)
        self.query = query
        self.set_opaque(opaque)
        self.fragment=(fragment)
      end
      if registry
        raise InvalidURIError,
          "the scheme #{@scheme} does not accept registry part: #{registry} (or bad hostname?)"
      end

      @scheme
      self.set_path('') if !@path && !@opaque # (see RFC2396 Section 5.2)
      self.set_port(self.default_port) if self.default_port && !@port
    end

    #
    # returns the scheme component of the URI.
    #
    #   URI("http://foo/bar/baz").scheme #=> "http"
    #
    attr_reader :scheme

    # returns the host component of the URI.
    #
    #   URI("http://foo/bar/baz").host #=> "foo"
    #
    # It returns nil if no host component.
    #
    #   URI("mailto:foo@example.org").host #=> nil
    #
    # The component doesn't contains the port number.
    #
    #   URI("http://foo:8080/bar/baz").host #=> "foo"
    #
    # Since IPv6 addresses are wrapped by brackets in URIs,
    # this method returns IPv6 addresses wrapped by brackets.
    # This form is not appropriate to pass socket methods such as TCPSocket.open.
    # If unwrapped host names are required, use "hostname" method.
    #
    #   URI("http://[::1]/bar/baz").host #=> "[::1]"
    #   URI("http://[::1]/bar/baz").hostname #=> "::1"
    #
    attr_reader :host

    # returns the port component of the URI.
    #
    #   URI("http://foo/bar/baz").port #=> "80"
    #
    #   URI("http://foo:8080/bar/baz").port #=> "8080"
    #
    attr_reader :port

    def registry # :nodoc:
      nil
    end

    # returns the path component of the URI.
    #
    #   URI("http://foo/bar/baz").path #=> "/bar/baz"
    #
    attr_reader :path

    # returns the query component of the URI.
    #
    #   URI("http://foo/bar/baz?search=FooBar").query #=> "search=FooBar"
    #
    attr_reader :query

    # returns the opaque part of the URI.
    #
    #   URI("mailto:foo@example.org").opaque #=> "foo@example.org"
    #
    # Portion of the path that does make use of the slash '/'.
    # The path typically refers to the absolute path and the opaque part.
    # (See RFC2396 Section 3 and 5.2.)
    #
    attr_reader :opaque

    # returns the fragment component of the URI.
    #
    #   URI("http://foo/bar/baz?search=FooBar#ponies").fragment #=> "ponies"
    #
    attr_reader :fragment

    # returns the parser to be used.
    #
    # Unless a URI::Parser is defined, then DEFAULT_PARSER is used.
    #
    def parser
      if !defined?(@parser) || !@parser
        DEFAULT_PARSER
      else
        @parser || DEFAULT_PARSER
      end
    end

    # replace self by other URI object
    def replace!(oth)
      if self.class != oth.class
        raise ArgumentError, "expected #{self.class} object"
      end

      component.each do |c|
        self.__send__("#{c}=", oth.__send__(c))
      end
    end
    private :replace!

    #
    # Components of the URI in the order.
    #
    def component
      self.class.component
    end

    #
    # check the scheme +v+ component against the URI::Parser Regexp for :SCHEME
    #
    def check_scheme(v)
      if v && parser.regexp[:SCHEME] !~ v
        raise InvalidComponentError,
          "bad component(expected scheme component): #{v}"
      end

      return true
    end
    private :check_scheme

    # protected setter for the scheme component +v+
    #
    # see also URI::Generic.scheme=
    #
    def set_scheme(v)
      @scheme = v.downcase
    end
    protected :set_scheme

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the scheme component +v+.
    # (with validation)
    #
    # see also URI::Generic.check_scheme
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com")
    #   uri.scheme = "https"
    #   # =>  "https"
    #   uri
    #   #=> #<URI::HTTP:0x000000008e89e8 URL:https://my.example.com>
    #
    def scheme=(v)
      check_scheme(v)
      set_scheme(v)
      v
    end

    #
    # check the +user+ and +password+.
    #
    # If +password+ is not provided, then +user+ is
    # split, using URI::Generic.split_userinfo, to
    # pull +user+ and +password.
    #
    # see also URI::Generic.check_user, URI::Generic.check_password
    #
    def check_userinfo(user, password = nil)
      if !password
        user, password = split_userinfo(user)
      end
      check_user(user)
      check_password(password, user)

      return true
    end
    private :check_userinfo

    #
    # check the user +v+ component for RFC2396 compliance
    # and against the URI::Parser Regexp for :USERINFO
    #
    # Can not have a registry or opaque component defined,
    # with a user component defined.
    #
    def check_user(v)
      if @opaque
        raise InvalidURIError,
          "can not set user with opaque"
      end

      return v unless v

      if parser.regexp[:USERINFO] !~ v
        raise InvalidComponentError,
          "bad component(expected userinfo component or user component): #{v}"
      end

      return true
    end
    private :check_user

    #
    # check the password +v+ component for RFC2396 compliance
    # and against the URI::Parser Regexp for :USERINFO
    #
    # Can not have a registry or opaque component defined,
    # with a user component defined.
    #
    def check_password(v, user = @user)
      if @opaque
        raise InvalidURIError,
          "can not set password with opaque"
      end
      return v unless v

      if !user
        raise InvalidURIError,
          "password component depends user component"
      end

      if parser.regexp[:USERINFO] !~ v
        raise InvalidComponentError,
          "bad password component"
      end

      return true
    end
    private :check_password

    #
    # Sets userinfo, argument is string like 'name:pass'
    #
    def userinfo=(userinfo)
      if userinfo.nil?
        return nil
      end
      check_userinfo(*userinfo)
      set_userinfo(*userinfo)
      # returns userinfo
    end

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the +user+ component.
    # (with validation)
    #
    # see also URI::Generic.check_user
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://john:S3nsit1ve@my.example.com")
    #   uri.user = "sam"
    #   # =>  "sam"
    #   uri
    #   #=> #<URI::HTTP:0x00000000881d90 URL:http://sam:V3ry_S3nsit1ve@my.example.com>
    #
    def user=(user)
      check_user(user)
      set_user(user)
      # returns user
    end

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the +password+ component.
    # (with validation)
    #
    # see also URI::Generic.check_password
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://john:S3nsit1ve@my.example.com")
    #   uri.password = "V3ry_S3nsit1ve"
    #   # =>  "V3ry_S3nsit1ve"
    #   uri
    #   #=> #<URI::HTTP:0x00000000881d90 URL:http://john:V3ry_S3nsit1ve@my.example.com>
    #
    def password=(password)
      check_password(password)
      set_password(password)
      # returns password
    end

    # protect setter for the +user+ component, and +password+ if available.
    # (with validation)
    #
    # see also URI::Generic.userinfo=
    #
    def set_userinfo(user, password = nil)
      unless password
        user, password = split_userinfo(user)
      end
      @user     = user
      @password = password if password

      [@user, @password]
    end
    protected :set_userinfo

    # protected setter for the user component +v+
    #
    # see also URI::Generic.user=
    #
    def set_user(v)
      set_userinfo(v, @password)
      v
    end
    protected :set_user

    # protected setter for the password component +v+
    #
    # see also URI::Generic.password=
    #
    def set_password(v)
      @password = v
      # returns v
    end
    protected :set_password

    # returns the userinfo +ui+ as user, password
    # if properly formatted as 'user:password'
    def split_userinfo(ui)
      return nil, nil unless ui
      user, password = ui.split(':', 2)

      return user, password
    end
    private :split_userinfo

    # escapes 'user:password' +v+ based on RFC 1738 section 3.1
    def escape_userpass(v)
      parser.escape(v, /[@:\/]/o) # RFC 1738 section 3.1 #/
    end
    private :escape_userpass

    # returns the userinfo, either as 'user' or 'user:password'
    def userinfo
      if @user.nil?
        nil
      elsif @password.nil?
        @user
      else
        @user + ':' + @password
      end
    end

    # returns the user component
    def user
      @user
    end

    # returns the password component
    def password
      @password
    end

    #
    # check the host +v+ component for RFC2396 compliance
    # and against the URI::Parser Regexp for :HOST
    #
    # Can not have a registry or opaque component defined,
    # with a host component defined.
    #
    def check_host(v)
      return v unless v

      if @opaque
        raise InvalidURIError,
          "can not set host with registry or opaque"
      elsif parser.regexp[:HOST] !~ v
        raise InvalidComponentError,
          "bad component(expected host component): #{v}"
      end

      return true
    end
    private :check_host

    # protected setter for the host component +v+
    #
    # see also URI::Generic.host=
    #
    def set_host(v)
      @host = v
    end
    protected :set_host

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the host component +v+.
    # (with validation)
    #
    # see also URI::Generic.check_host
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com")
    #   uri.host = "foo.com"
    #   # =>  "foo.com"
    #   uri
    #   #=> #<URI::HTTP:0x000000008e89e8 URL:http://foo.com>
    #
    def host=(v)
      check_host(v)
      set_host(v)
      v
    end

    # extract the host part of the URI and unwrap brackets for IPv6 addresses.
    #
    # This method is same as URI::Generic#host except
    # brackets for IPv6 (and future IP) addresses are removed.
    #
    #   u = URI("http://[::1]/bar")
    #   p u.hostname      #=> "::1"
    #   p u.host          #=> "[::1]"
    #
    def hostname
      v = self.host
      /\A\[(.*)\]\z/ =~ v ? $1 : v
    end

    # set the host part of the URI as the argument with brackets for IPv6 addresses.
    #
    # This method is same as URI::Generic#host= except
    # the argument can be bare IPv6 address.
    #
    #   u = URI("http://foo/bar")
    #   p u.to_s                  #=> "http://foo/bar"
    #   u.hostname = "::1"
    #   p u.to_s                  #=> "http://[::1]/bar"
    #
    # If the argument seems IPv6 address,
    # it is wrapped by brackets.
    #
    def hostname=(v)
      v = "[#{v}]" if /\A\[.*\]\z/ !~ v && /:/ =~ v
      self.host = v
    end

    #
    # check the port +v+ component for RFC2396 compliance
    # and against the URI::Parser Regexp for :PORT
    #
    # Can not have a registry or opaque component defined,
    # with a port component defined.
    #
    def check_port(v)
      return v unless v

      if @opaque
        raise InvalidURIError,
          "can not set port with registry or opaque"
      elsif !v.kind_of?(Integer) && parser.regexp[:PORT] !~ v
        raise InvalidComponentError,
          "bad component(expected port component): #{v.inspect}"
      end

      return true
    end
    private :check_port

    # protected setter for the port component +v+
    #
    # see also URI::Generic.port=
    #
    def set_port(v)
      v = v.empty? ? nil : v.to_i unless !v || v.kind_of?(Integer)
      @port = v
    end
    protected :set_port

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the port component +v+.
    # (with validation)
    #
    # see also URI::Generic.check_port
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com")
    #   uri.port = 8080
    #   # =>  8080
    #   uri
    #   #=> #<URI::HTTP:0x000000008e89e8 URL:http://my.example.com:8080>
    #
    def port=(v)
      check_port(v)
      set_port(v)
      port
    end

    def check_registry(v) # :nodoc:
      raise InvalidURIError, "can not set registry"
    end
    private :check_registry

    def set_registry(v) #:nodoc:
      raise InvalidURIError, "can not set registry"
    end
    protected :set_registry

    def registry=(v)
      raise InvalidURIError, "can not set registry"
    end

    #
    # check the path +v+ component for RFC2396 compliance
    # and against the URI::Parser Regexp
    # for :ABS_PATH and :REL_PATH
    #
    # Can not have a opaque component defined,
    # with a path component defined.
    #
    def check_path(v)
      # raise if both hier and opaque are not nil, because:
      # absoluteURI   = scheme ":" ( hier_part | opaque_part )
      # hier_part     = ( net_path | abs_path ) [ "?" query ]
      if v && @opaque
        raise InvalidURIError,
          "path conflicts with opaque"
      end

      # If scheme is ftp, path may be relative.
      # See RFC 1738 section 3.2.2, and RFC 2396.
      if @scheme && @scheme != "ftp"
        if v && v != '' && parser.regexp[:ABS_PATH] !~ v
          raise InvalidComponentError,
            "bad component(expected absolute path component): #{v}"
        end
      else
        if v && v != '' && parser.regexp[:ABS_PATH] !~ v &&
           parser.regexp[:REL_PATH] !~ v
          raise InvalidComponentError,
            "bad component(expected relative path component): #{v}"
        end
      end

      return true
    end
    private :check_path

    # protected setter for the path component +v+
    #
    # see also URI::Generic.path=
    #
    def set_path(v)
      @path = v
    end
    protected :set_path

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the path component +v+.
    # (with validation)
    #
    # see also URI::Generic.check_path
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com/pub/files")
    #   uri.path = "/faq/"
    #   # =>  "/faq/"
    #   uri
    #   #=> #<URI::HTTP:0x000000008e89e8 URL:http://my.example.com/faq/>
    #
    def path=(v)
      check_path(v)
      set_path(v)
      v
    end

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the query component +v+.
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com/?id=25")
    #   uri.query = "id=1"
    #   # =>  "id=1"
    #   uri
    #   #=> #<URI::HTTP:0x000000008e89e8 URL:http://my.example.com/?id=1>
    #
    def query=(v)
      return @query = nil unless v
      raise InvalidURIError, "query conflicts with opaque" if @opaque

      x = v.to_str
      v = x.dup if x.equal? v
      v.encode!(Encoding::UTF_8) rescue nil
      v.delete!("\t\r\n")
      v.force_encoding(Encoding::ASCII_8BIT)
      v.gsub!(/(?!%\h\h|[!$-&(-;=?-_a-~])./n.freeze){'%%%02X' % $&.ord}
      v.force_encoding(Encoding::US_ASCII)
      @query = v
    end

    #
    # check the opaque +v+ component for RFC2396 compliance and
    # against the URI::Parser Regexp for :OPAQUE
    #
    # Can not have a host, port, user or path component defined,
    # with an opaque component defined.
    #
    def check_opaque(v)
      return v unless v

      # raise if both hier and opaque are not nil, because:
      # absoluteURI   = scheme ":" ( hier_part | opaque_part )
      # hier_part     = ( net_path | abs_path ) [ "?" query ]
      if @host || @port || @user || @path  # userinfo = @user + ':' + @password
        raise InvalidURIError,
          "can not set opaque with host, port, userinfo or path"
      elsif v && parser.regexp[:OPAQUE] !~ v
        raise InvalidComponentError,
          "bad component(expected opaque component): #{v}"
      end

      return true
    end
    private :check_opaque

    # protected setter for the opaque component +v+
    #
    # see also URI::Generic.opaque=
    #
    def set_opaque(v)
      @opaque = v
    end
    protected :set_opaque

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the opaque component +v+.
    # (with validation)
    #
    # see also URI::Generic.check_opaque
    #
    def opaque=(v)
      check_opaque(v)
      set_opaque(v)
      v
    end

    #
    # check the fragment +v+ component against the URI::Parser Regexp for :FRAGMENT
    #
    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the fragment component +v+.
    # (with validation)
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com/?id=25#time=1305212049")
    #   uri.fragment = "time=1305212086"
    #   # =>  "time=1305212086"
    #   uri
    #   #=> #<URI::HTTP:0x000000007a81f8 URL:http://my.example.com/?id=25#time=1305212086>
    #
    def fragment=(v)
      return @fragment = nil unless v

      x = v.to_str
      v = x.dup if x.equal? v
      v.encode!(Encoding::UTF_8) rescue nil
      v.delete!("\t\r\n")
      v.force_encoding(Encoding::ASCII_8BIT)
      v.gsub!(/(?!%\h\h|[!-~])./n){'%%%02X' % $&.ord}
      v.force_encoding(Encoding::US_ASCII)
      @fragment = v
    end

    #
    # Checks if URI has a path
    #
    def hierarchical?
      if @path
        true
      else
        false
      end
    end

    #
    # Checks if URI is an absolute one
    #
    def absolute?
      if @scheme
        true
      else
        false
      end
    end
    alias absolute absolute?

    #
    # Checks if URI is relative
    #
    def relative?
      !absolute?
    end

    #
    # returns an Array of the path split on '/'
    #
    def split_path(path)
      path.split("/", -1)
    end
    private :split_path

    #
    # Merges a base path +base+, with relative path +rel+,
    # returns a modified base path.
    #
    def merge_path(base, rel)

      # RFC2396, Section 5.2, 5)
      # RFC2396, Section 5.2, 6)
      base_path = split_path(base)
      rel_path  = split_path(rel)

      # RFC2396, Section 5.2, 6), a)
      base_path << '' if base_path.last == '..'
      while i = base_path.index('..')
        base_path.slice!(i - 1, 2)
      end

      if (first = rel_path.first) and first.empty?
        base_path.clear
        rel_path.shift
      end

      # RFC2396, Section 5.2, 6), c)
      # RFC2396, Section 5.2, 6), d)
      rel_path.push('') if rel_path.last == '.' || rel_path.last == '..'
      rel_path.delete('.')

      # RFC2396, Section 5.2, 6), e)
      tmp = []
      rel_path.each do |x|
        if x == '..' &&
            !(tmp.empty? || tmp.last == '..')
          tmp.pop
        else
          tmp << x
        end
      end

      add_trailer_slash = !tmp.empty?
      if base_path.empty?
        base_path = [''] # keep '/' for root directory
      elsif add_trailer_slash
        base_path.pop
      end
      while x = tmp.shift
        if x == '..'
          # RFC2396, Section 4
          # a .. or . in an absolute path has no special meaning
          base_path.pop if base_path.size > 1
        else
          # if x == '..'
          #   valid absolute (but abnormal) path "/../..."
          # else
          #   valid absolute path
          # end
          base_path << x
          tmp.each {|t| base_path << t}
          add_trailer_slash = false
          break
        end
      end
      base_path.push('') if add_trailer_slash

      return base_path.join('/')
    end
    private :merge_path

    #
    # == Args
    #
    # +oth+::
    #    URI or String
    #
    # == Description
    #
    # Destructive form of #merge
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com")
    #   uri.merge!("/main.rbx?page=1")
    #   p uri
    #   # =>  #<URI::HTTP:0x2021f3b0 URL:http://my.example.com/main.rbx?page=1>
    #
    def merge!(oth)
      t = merge(oth)
      if self == t
        nil
      else
        replace!(t)
        self
      end
    end

    #
    # == Args
    #
    # +oth+::
    #    URI or String
    #
    # == Description
    #
    # Merges two URI's.
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com")
    #   p uri.merge("/main.rbx?page=1")
    #   # =>  #<URI::HTTP:0x2021f3b0 URL:http://my.example.com/main.rbx?page=1>
    #
    def merge(oth)
      rel = parser.send(:convert_to_uri, oth)

      if rel.absolute?
        #raise BadURIError, "both URI are absolute" if absolute?
        # hmm... should return oth for usability?
        return rel
      end

      unless self.absolute?
        raise BadURIError, "both URI are relative"
      end

      base = self.dup

      authority = rel.userinfo || rel.host || rel.port

      # RFC2396, Section 5.2, 2)
      if (rel.path.nil? || rel.path.empty?) && !authority && !rel.query
        base.fragment=(rel.fragment) if rel.fragment
        return base
      end

      base.query = nil
      base.fragment=(nil)

      # RFC2396, Section 5.2, 4)
      if !authority
        base.set_path(merge_path(base.path, rel.path)) if base.path && rel.path
      else
        # RFC2396, Section 5.2, 4)
        base.set_path(rel.path) if rel.path
      end

      # RFC2396, Section 5.2, 7)
      base.set_userinfo(rel.userinfo) if rel.userinfo
      base.set_host(rel.host)         if rel.host
      base.set_port(rel.port)         if rel.port
      base.query = rel.query       if rel.query
      base.fragment=(rel.fragment) if rel.fragment

      return base
    end # merge
    alias + merge

    # :stopdoc:
    def route_from_path(src, dst)
      case dst
      when src
        # RFC2396, Section 4.2
        return ''
      when %r{(?:\A|/)\.\.?(?:/|\z)}
        # dst has abnormal absolute path,
        # like "/./", "/../", "/x/../", ...
        return dst.dup
      end

      src_path = src.scan(%r{[^/]*/})
      dst_path = dst.scan(%r{[^/]*/?})

      # discard same parts
      while !dst_path.empty? && dst_path.first == src_path.first
        src_path.shift
        dst_path.shift
      end

      tmp = dst_path.join

      # calculate
      if src_path.empty?
        if tmp.empty?
          return './'
        elsif dst_path.first.include?(':') # (see RFC2396 Section 5)
          return './' + tmp
        else
          return tmp
        end
      end

      return '../' * src_path.size + tmp
    end
    private :route_from_path
    # :startdoc:

    # :stopdoc:
    def route_from0(oth)
      oth = parser.send(:convert_to_uri, oth)
      if self.relative?
        raise BadURIError,
          "relative URI: #{self}"
      end
      if oth.relative?
        raise BadURIError,
          "relative URI: #{oth}"
      end

      if self.scheme != oth.scheme
        return self, self.dup
      end
      rel = URI::Generic.new(nil, # it is relative URI
                             self.userinfo, self.host, self.port,
                             nil, self.path, self.opaque,
                             self.query, self.fragment, parser)

      if rel.userinfo != oth.userinfo ||
          rel.host.to_s.downcase != oth.host.to_s.downcase ||
          rel.port != oth.port

        if self.userinfo.nil? && self.host.nil?
          return self, self.dup
        end

        rel.set_port(nil) if rel.port == oth.default_port
        return rel, rel
      end
      rel.set_userinfo(nil)
      rel.set_host(nil)
      rel.set_port(nil)

      if rel.path && rel.path == oth.path
        rel.set_path('')
        rel.query = nil if rel.query == oth.query
        return rel, rel
      elsif rel.opaque && rel.opaque == oth.opaque
        rel.set_opaque('')
        rel.query = nil if rel.query == oth.query
        return rel, rel
      end

      # you can modify `rel', but can not `oth'.
      return oth, rel
    end
    private :route_from0
    # :startdoc:

    #
    # == Args
    #
    # +oth+::
    #    URI or String
    #
    # == Description
    #
    # Calculates relative path from oth to self
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse('http://my.example.com/main.rbx?page=1')
    #   p uri.route_from('http://my.example.com')
    #   #=> #<URI::Generic:0x20218858 URL:/main.rbx?page=1>
    #
    def route_from(oth)
      # you can modify `rel', but can not `oth'.
      begin
        oth, rel = route_from0(oth)
      rescue
        raise $!.class, $!.message
      end
      if oth == rel
        return rel
      end

      rel.set_path(route_from_path(oth.path, self.path))
      if rel.path == './' && self.query
        # "./?foo" -> "?foo"
        rel.set_path('')
      end

      return rel
    end

    alias - route_from

    #
    # == Args
    #
    # +oth+::
    #    URI or String
    #
    # == Description
    #
    # Calculates relative path to oth from self
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse('http://my.example.com')
    #   p uri.route_to('http://my.example.com/main.rbx?page=1')
    #   #=> #<URI::Generic:0x2020c2f6 URL:/main.rbx?page=1>
    #
    def route_to(oth)
      parser.send(:convert_to_uri, oth).route_from(self)
    end

    #
    # Returns normalized URI.
    #
    #   require 'uri'
    #
    #   URI("HTTP://my.EXAMPLE.com").normalize
    #   #=> #<URI::HTTP http://my.example.com/>
    #
    # Normalization here means:
    #
    # * scheme and host are converted to lowercase,
    # * an empty path component is set to "/".
    #
    def normalize
      uri = dup
      uri.normalize!
      uri
    end

    #
    # Destructive version of #normalize
    #
    def normalize!
      if path.empty?
        set_path('/')
      end
      if scheme && scheme != scheme.downcase
        set_scheme(self.scheme.downcase)
      end
      if host && host != host.downcase
        set_host(self.host.downcase)
      end
    end

    #
    # Constructs String from URI
    #
    def to_s
      str = ''.dup
      if @scheme
        str << @scheme
        str << ':'
      end

      if @opaque
        str << @opaque
      else
        if @host || %w[file postgres].include?(@scheme)
          str << '//'
        end
        if self.userinfo
          str << self.userinfo
          str << '@'
        end
        if @host
          str << @host
        end
        if @port && @port != self.default_port
          str << ':'
          str << @port.to_s
        end
        str << @path
        if @query
          str << '?'
          str << @query
        end
      end
      if @fragment
        str << '#'
        str << @fragment
      end
      str
    end

    #
    # Compares two URIs
    #
    def ==(oth)
      if self.class == oth.class
        self.normalize.component_ary == oth.normalize.component_ary
      else
        false
      end
    end

    def hash
      self.component_ary.hash
    end

    def eql?(oth)
      self.class == oth.class &&
      parser == oth.parser &&
      self.component_ary.eql?(oth.component_ary)
    end

=begin

--- URI::Generic#===(oth)

=end
#    def ===(oth)
#      raise NotImplementedError
#    end

=begin
=end


    # returns an Array of the components defined from the COMPONENT Array
    def component_ary
      component.collect do |x|
        self.send(x)
      end
    end
    protected :component_ary

    # == Args
    #
    # +components+::
    #    Multiple Symbol arguments defined in URI::HTTP
    #
    # == Description
    #
    # Selects specified components from URI
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse('http://myuser:mypass@my.example.com/test.rbx')
    #   p uri.select(:userinfo, :host, :path)
    #   # => ["myuser:mypass", "my.example.com", "/test.rbx"]
    #
    def select(*components)
      components.collect do |c|
        if component.include?(c)
          self.send(c)
        else
          raise ArgumentError,
            "expected of components of #{self.class} (#{self.class.component.join(', ')})"
        end
      end
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    #
    # == Args
    #
    # +v+::
    #    URI or String
    #
    # == Description
    #
    # attempts to parse other URI +oth+,
    # returns [parsed_oth, self]
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("http://my.example.com")
    #   uri.coerce("http://foo.com")
    #   #=> [#<URI::HTTP:0x00000000bcb028 URL:http://foo.com/>, #<URI::HTTP:0x00000000d92178 URL:http://my.example.com>]
    #
    def coerce(oth)
      case oth
      when String
        oth = parser.parse(oth)
      else
        super
      end

      return oth, self
    end

    # returns a proxy URI.
    # The proxy URI is obtained from environment variables such as http_proxy,
    # ftp_proxy, no_proxy, etc.
    # If there is no proper proxy, nil is returned.
    #
    # If the optional parameter, +env+, is specified, it is used instead of ENV.
    #
    # Note that capitalized variables (HTTP_PROXY, FTP_PROXY, NO_PROXY, etc.)
    # are examined too.
    #
    # But http_proxy and HTTP_PROXY is treated specially under CGI environment.
    # It's because HTTP_PROXY may be set by Proxy: header.
    # So HTTP_PROXY is not used.
    # http_proxy is not used too if the variable is case insensitive.
    # CGI_HTTP_PROXY can be used instead.
    def find_proxy(env=ENV)
      raise BadURIError, "relative URI: #{self}" if self.relative?
      name = self.scheme.downcase + '_proxy'
      proxy_uri = nil
      if name == 'http_proxy' && env.include?('REQUEST_METHOD') # CGI?
        # HTTP_PROXY conflicts with *_proxy for proxy settings and
        # HTTP_* for header information in CGI.
        # So it should be careful to use it.
        pairs = env.reject {|k, v| /\Ahttp_proxy\z/i !~ k }
        case pairs.length
        when 0 # no proxy setting anyway.
          proxy_uri = nil
        when 1
          k, _ = pairs.shift
          if k == 'http_proxy' && env[k.upcase] == nil
            # http_proxy is safe to use because ENV is case sensitive.
            proxy_uri = env[name]
          else
            proxy_uri = nil
          end
        else # http_proxy is safe to use because ENV is case sensitive.
          proxy_uri = env.to_hash[name]
        end
        if !proxy_uri
          # Use CGI_HTTP_PROXY.  cf. libwww-perl.
          proxy_uri = env["CGI_#{name.upcase}"]
        end
      elsif name == 'http_proxy'
        unless proxy_uri = env[name]
          if proxy_uri = env[name.upcase]
            warn 'The environment variable HTTP_PROXY is discouraged.  Use http_proxy.', uplevel: 1
          end
        end
      else
        proxy_uri = env[name] || env[name.upcase]
      end

      if proxy_uri.nil? || proxy_uri.empty?
        return nil
      end

      if self.hostname
        begin
          addr = IPSocket.getaddress(self.hostname)
          return nil if /\A127\.|\A::1\z/ =~ addr
        rescue SocketError
        end
      end

      name = 'no_proxy'
      if no_proxy = env[name] || env[name.upcase]
        return nil unless URI::Generic.use_proxy?(self.hostname, addr, self.port, no_proxy)
      end
      URI.parse(proxy_uri)
    end

    def self.use_proxy?(hostname, addr, port, no_proxy) # :nodoc:
      no_proxy.scan(/(?!\.)([^:,\s]+)(?::(\d+))?/) {|p_host, p_port|
        if !p_port || port == p_port.to_i
          if /(\A|\.)#{Regexp.quote p_host}\z/i =~ hostname
            return false
          elsif addr
            begin
              return false if IPAddr.new(p_host).include?(addr)
            rescue IPAddr::InvalidAddressError
              next
            end
          end
        end
      }
      true
    end
  end
end
module URI

  # The default port for HTTPS URIs is 443, and the scheme is 'https:' rather
  # than 'http:'. Other than that, HTTPS URIs are identical to HTTP URIs;
  # see URI::HTTP.
  class HTTPS < HTTP
    # A Default port of 443 for URI::HTTPS
    DEFAULT_PORT = 443
  end
  @@schemes['HTTPS'] = HTTPS
end

module URI

  #
  # FTP URI syntax is defined by RFC1738 section 3.2.
  #
  # This class will be redesigned because of difference of implementations;
  # the structure of its path. draft-hoffman-ftp-uri-04 is a draft but it
  # is a good summary about the de facto spec.
  # http://tools.ietf.org/html/draft-hoffman-ftp-uri-04
  #
  class FTP < Generic
    # A Default port of 21 for URI::FTP
    DEFAULT_PORT = 21

    #
    # An Array of the available components for URI::FTP
    #
    COMPONENT = [
      :scheme,
      :userinfo, :host, :port,
      :path, :typecode
    ].freeze

    #
    # Typecode is "a", "i" or "d".
    #
    # * "a" indicates a text file (the FTP command was ASCII)
    # * "i" indicates a binary file (FTP command IMAGE)
    # * "d" indicates the contents of a directory should be displayed
    #
    TYPECODE = ['a', 'i', 'd'].freeze

    # Typecode prefix
    #  ';type='
    TYPECODE_PREFIX = ';type='.freeze

    def self.new2(user, password, host, port, path,
                  typecode = nil, arg_check = true) # :nodoc:
      # Do not use this method!  Not tested.  [Bug #7301]
      # This methods remains just for compatibility,
      # Keep it undocumented until the active maintainer is assigned.
      typecode = nil if typecode.size == 0
      if typecode && !TYPECODE.include?(typecode)
        raise ArgumentError,
          "bad typecode is specified: #{typecode}"
      end

      # do escape

      self.new('ftp',
               [user, password],
               host, port, nil,
               typecode ? path + TYPECODE_PREFIX + typecode : path,
               nil, nil, nil, arg_check)
    end

    #
    # == Description
    #
    # Creates a new URI::FTP object from components, with syntax checking.
    #
    # The components accepted are +userinfo+, +host+, +port+, +path+ and
    # +typecode+.
    #
    # The components should be provided either as an Array, or as a Hash
    # with keys formed by preceding the component names with a colon.
    #
    # If an Array is used, the components must be passed in the order
    # [userinfo, host, port, path, typecode]
    #
    # If the path supplied is absolute, it will be escaped in order to
    # make it absolute in the URI. Examples:
    #
    #     require 'uri'
    #
    #     uri = URI::FTP.build(['user:password', 'ftp.example.com', nil,
    #       '/path/file.zip', 'i'])
    #     puts uri.to_s  ->  ftp://user:password@ftp.example.com/%2Fpath/file.zip;type=i
    #
    #     uri2 = URI::FTP.build({:host => 'ftp.example.com',
    #       :path => 'ruby/src'})
    #     puts uri2.to_s  ->  ftp://ftp.example.com/ruby/src
    #
    def self.build(args)

      # Fix the incoming path to be generic URL syntax
      # FTP path  ->  URL path
      # foo/bar       /foo/bar
      # /foo/bar      /%2Ffoo/bar
      #
      if args.kind_of?(Array)
        args[3] = '/' + args[3].sub(/^\//, '%2F')
      else
        args[:path] = '/' + args[:path].sub(/^\//, '%2F')
      end

      tmp = Util::make_components_hash(self, args)

      if tmp[:typecode]
        if tmp[:typecode].size == 1
          tmp[:typecode] = TYPECODE_PREFIX + tmp[:typecode]
        end
        tmp[:path] << tmp[:typecode]
      end

      return super(tmp)
    end

    #
    # == Description
    #
    # Creates a new URI::FTP object from generic URL components with no
    # syntax checking.
    #
    # Unlike build(), this method does not escape the path component as
    # required by RFC1738; instead it is treated as per RFC2396.
    #
    # Arguments are +scheme+, +userinfo+, +host+, +port+, +registry+, +path+,
    # +opaque+, +query+ and +fragment+, in that order.
    #
    def initialize(scheme,
                   userinfo, host, port, registry,
                   path, opaque,
                   query,
                   fragment,
                   parser = nil,
                   arg_check = false)
      raise InvalidURIError unless path
      path = path.sub(/^\//,'')
      path.sub!(/^%2F/,'/')
      super(scheme, userinfo, host, port, registry, path, opaque,
            query, fragment, parser, arg_check)
      @typecode = nil
      if tmp = @path.index(TYPECODE_PREFIX)
        typecode = @path[tmp + TYPECODE_PREFIX.size..-1]
        @path = @path[0..tmp - 1]

        if arg_check
          self.typecode = typecode
        else
          self.set_typecode(typecode)
        end
      end
    end

    # typecode accessor
    #
    # see URI::FTP::COMPONENT
    attr_reader :typecode

    # validates typecode +v+,
    # returns a +true+ or +false+ boolean
    #
    def check_typecode(v)
      if TYPECODE.include?(v)
        return true
      else
        raise InvalidComponentError,
          "bad typecode(expected #{TYPECODE.join(', ')}): #{v}"
      end
    end
    private :check_typecode

    # Private setter for the typecode +v+
    #
    # see also URI::FTP.typecode=
    #
    def set_typecode(v)
      @typecode = v
    end
    protected :set_typecode

    #
    # == Args
    #
    # +v+::
    #    String
    #
    # == Description
    #
    # public setter for the typecode +v+.
    # (with validation)
    #
    # see also URI::FTP.check_typecode
    #
    # == Usage
    #
    #   require 'uri'
    #
    #   uri = URI.parse("ftp://john@ftp.example.com/my_file.img")
    #   #=> #<URI::FTP:0x00000000923650 URL:ftp://john@ftp.example.com/my_file.img>
    #   uri.typecode = "i"
    #   # =>  "i"
    #   uri
    #   #=> #<URI::FTP:0x00000000923650 URL:ftp://john@ftp.example.com/my_file.img;type=i>
    #
    def typecode=(typecode)
      check_typecode(typecode)
      set_typecode(typecode)
      typecode
    end

    def merge(oth) # :nodoc:
      tmp = super(oth)
      if self != tmp
        tmp.set_typecode(oth.typecode)
      end

      return tmp
    end

    # Returns the path from an FTP URI.
    #
    # RFC 1738 specifically states that the path for an FTP URI does not
    # include the / which separates the URI path from the URI host. Example:
    #
    # +ftp://ftp.example.com/pub/ruby+
    #
    # The above URI indicates that the client should connect to
    # ftp.example.com then cd pub/ruby from the initial login directory.
    #
    # If you want to cd to an absolute directory, you must include an
    # escaped / (%2F) in the path. Example:
    #
    # +ftp://ftp.example.com/%2Fpub/ruby+
    #
    # This method will then return "/pub/ruby"
    #
    def path
      return @path.sub(/^\//,'').sub(/^%2F/,'/')
    end

    # Private setter for the path of the URI::FTP
    def set_path(v)
      super("/" + v.sub(/^\//, "%2F"))
    end
    protected :set_path

    # Returns a String representation of the URI::FTP
    def to_s
      save_path = nil
      if @typecode
        save_path = @path
        @path = @path + TYPECODE_PREFIX + @typecode
      end
      str = super
      if @typecode
        @path = save_path
      end

      return str
    end
  end
  @@schemes['FTP'] = FTP
end

module URI

  #
  # LDAP URI SCHEMA (described in RFC2255)
  # ldap://<host>/<dn>[?<attrs>[?<scope>[?<filter>[?<extensions>]]]]
  #
  class LDAP < Generic

    # A Default port of 389 for URI::LDAP
    DEFAULT_PORT = 389

    # An Array of the available components for URI::LDAP
    COMPONENT = [
      :scheme,
      :host, :port,
      :dn,
      :attributes,
      :scope,
      :filter,
      :extensions,
    ].freeze

    # Scopes available for the starting point.
    #
    # * SCOPE_BASE - the Base DN
    # * SCOPE_ONE  - one level under the Base DN, not including the base DN and
    #                not including any entries under this.
    # * SCOPE_SUB  - subtress, all entries at all levels
    #
    SCOPE = [
      SCOPE_ONE = 'one',
      SCOPE_SUB = 'sub',
      SCOPE_BASE = 'base',
    ].freeze

    #
    # == Description
    #
    # Create a new URI::LDAP object from components, with syntax checking.
    #
    # The components accepted are host, port, dn, attributes,
    # scope, filter, and extensions.
    #
    # The components should be provided either as an Array, or as a Hash
    # with keys formed by preceding the component names with a colon.
    #
    # If an Array is used, the components must be passed in the order
    # [host, port, dn, attributes, scope, filter, extensions].
    #
    # Example:
    #
    #     newuri = URI::LDAP.build({:host => 'ldap.example.com',
    #       :dn> => '/dc=example'})
    #
    #     newuri = URI::LDAP.build(["ldap.example.com", nil,
    #       "/dc=example;dc=com", "query", nil, nil, nil])
    #
    def self.build(args)
      tmp = Util::make_components_hash(self, args)

      if tmp[:dn]
        tmp[:path] = tmp[:dn]
      end

      query = []
      [:extensions, :filter, :scope, :attributes].collect do |x|
        next if !tmp[x] && query.size == 0
        query.unshift(tmp[x])
      end

      tmp[:query] = query.join('?')

      return super(tmp)
    end

    #
    # == Description
    #
    # Create a new URI::LDAP object from generic URI components as per
    # RFC 2396. No LDAP-specific syntax checking is performed.
    #
    # Arguments are +scheme+, +userinfo+, +host+, +port+, +registry+, +path+,
    # +opaque+, +query+ and +fragment+, in that order.
    #
    # Example:
    #
    #     uri = URI::LDAP.new("ldap", nil, "ldap.example.com", nil,
    #       "/dc=example;dc=com", "query", nil, nil, nil, nil)
    #
    #
    # See also URI::Generic.new
    #
    def initialize(*arg)
      super(*arg)

      if @fragment
        raise InvalidURIError, 'bad LDAP URL'
      end

      parse_dn
      parse_query
    end

    # private method to cleanup +dn+ from using the +path+ component attribute
    def parse_dn
      @dn = @path[1..-1]
    end
    private :parse_dn

    # private method to cleanup +attributes+, +scope+, +filter+ and +extensions+,
    # from using the +query+ component attribute
    def parse_query
      @attributes = nil
      @scope      = nil
      @filter     = nil
      @extensions = nil

      if @query
        attrs, scope, filter, extensions = @query.split('?')

        @attributes = attrs if attrs && attrs.size > 0
        @scope      = scope if scope && scope.size > 0
        @filter     = filter if filter && filter.size > 0
        @extensions = extensions if extensions && extensions.size > 0
      end
    end
    private :parse_query

    # private method to assemble +query+ from +attributes+, +scope+, +filter+ and +extensions+.
    def build_path_query
      @path = '/' + @dn

      query = []
      [@extensions, @filter, @scope, @attributes].each do |x|
        next if !x && query.size == 0
        query.unshift(x)
      end
      @query = query.join('?')
    end
    private :build_path_query

    # returns dn.
    def dn
      @dn
    end

    # private setter for dn +val+
    def set_dn(val)
      @dn = val
      build_path_query
      @dn
    end
    protected :set_dn

    # setter for dn +val+
    def dn=(val)
      set_dn(val)
      val
    end

    # returns attributes.
    def attributes
      @attributes
    end

    # private setter for attributes +val+
    def set_attributes(val)
      @attributes = val
      build_path_query
      @attributes
    end
    protected :set_attributes

    # setter for attributes +val+
    def attributes=(val)
      set_attributes(val)
      val
    end

    # returns scope.
    def scope
      @scope
    end

    # private setter for scope +val+
    def set_scope(val)
      @scope = val
      build_path_query
      @scope
    end
    protected :set_scope

    # setter for scope +val+
    def scope=(val)
      set_scope(val)
      val
    end

    # returns filter.
    def filter
      @filter
    end

    # private setter for filter +val+
    def set_filter(val)
      @filter = val
      build_path_query
      @filter
    end
    protected :set_filter

    # setter for filter +val+
    def filter=(val)
      set_filter(val)
      val
    end

    # returns extensions.
    def extensions
      @extensions
    end

    # private setter for extensions +val+
    def set_extensions(val)
      @extensions = val
      build_path_query
      @extensions
    end
    protected :set_extensions

    # setter for extensions +val+
    def extensions=(val)
      set_extensions(val)
      val
    end

    # Checks if URI has a path
    # For URI::LDAP this will return +false+
    def hierarchical?
      false
    end
  end

  @@schemes['LDAP'] = LDAP
end

module URI

  # The default port for LDAPS URIs is 636, and the scheme is 'ldaps:' rather
  # than 'ldap:'. Other than that, LDAPS URIs are identical to LDAP URIs;
  # see URI::LDAP.
  class LDAPS < LDAP
    # A Default port of 636 for URI::LDAPS
    DEFAULT_PORT = 636
  end
  @@schemes['LDAPS'] = LDAPS
end

module URI

  #
  # RFC6068, The mailto URL scheme
  #
  class MailTo < Generic
    include REGEXP

    # A Default port of nil for URI::MailTo
    DEFAULT_PORT = nil

    # An Array of the available components for URI::MailTo
    COMPONENT = [ :scheme, :to, :headers ].freeze

    # :stopdoc:
    #  "hname" and "hvalue" are encodings of an RFC 822 header name and
    #  value, respectively. As with "to", all URL reserved characters must
    #  be encoded.
    #
    #  "#mailbox" is as specified in RFC 822 [RFC822]. This means that it
    #  consists of zero or more comma-separated mail addresses, possibly
    #  including "phrase" and "comment" components. Note that all URL
    #  reserved characters in "to" must be encoded: in particular,
    #  parentheses, commas, and the percent sign ("%"), which commonly occur
    #  in the "mailbox" syntax.
    #
    #  Within mailto URLs, the characters "?", "=", "&" are reserved.

    # ; RFC 6068
    # hfields      = "?" hfield *( "&" hfield )
    # hfield       = hfname "=" hfvalue
    # hfname       = *qchar
    # hfvalue      = *qchar
    # qchar        = unreserved / pct-encoded / some-delims
    # some-delims  = "!" / "$" / "'" / "(" / ")" / "*"
    #              / "+" / "," / ";" / ":" / "@"
    #
    # ; RFC3986
    # unreserved   = ALPHA / DIGIT / "-" / "." / "_" / "~"
    # pct-encoded  = "%" HEXDIG HEXDIG
    HEADER_REGEXP  = /\A(?<hfield>(?:%\h\h|[!$'-.0-;@-Z_a-z~])*=(?:%\h\h|[!$'-.0-;@-Z_a-z~])*)(?:&\g<hfield>)*\z/
    # practical regexp for email address
    # http://www.whatwg.org/specs/web-apps/current-work/multipage/states-of-the-type-attribute.html#valid-e-mail-address
    EMAIL_REGEXP = /\A[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z/
    # :startdoc:

    #
    # == Description
    #
    # Creates a new URI::MailTo object from components, with syntax checking.
    #
    # Components can be provided as an Array or Hash. If an Array is used,
    # the components must be supplied as [to, headers].
    #
    # If a Hash is used, the keys are the component names preceded by colons.
    #
    # The headers can be supplied as a pre-encoded string, such as
    # "subject=subscribe&cc=address", or as an Array of Arrays like
    # [['subject', 'subscribe'], ['cc', 'address']]
    #
    # Examples:
    #
    #    require 'uri'
    #
    #    m1 = URI::MailTo.build(['joe@example.com', 'subject=Ruby'])
    #    puts m1.to_s  ->  mailto:joe@example.com?subject=Ruby
    #
    #    m2 = URI::MailTo.build(['john@example.com', [['Subject', 'Ruby'], ['Cc', 'jack@example.com']]])
    #    puts m2.to_s  ->  mailto:john@example.com?Subject=Ruby&Cc=jack@example.com
    #
    #    m3 = URI::MailTo.build({:to => 'listman@example.com', :headers => [['subject', 'subscribe']]})
    #    puts m3.to_s  ->  mailto:listman@example.com?subject=subscribe
    #
    def self.build(args)
      tmp = Util.make_components_hash(self, args)

      case tmp[:to]
      when Array
        tmp[:opaque] = tmp[:to].join(',')
      when String
        tmp[:opaque] = tmp[:to].dup
      else
        tmp[:opaque] = ''
      end

      if tmp[:headers]
        query =
          case tmp[:headers]
          when Array
            tmp[:headers].collect { |x|
              if x.kind_of?(Array)
                x[0] + '=' + x[1..-1].join
              else
                x.to_s
              end
            }.join('&')
          when Hash
            tmp[:headers].collect { |h,v|
              h + '=' + v
            }.join('&')
          else
            tmp[:headers].to_s
          end
        unless query.empty?
          tmp[:opaque] << '?' << query
        end
      end

      super(tmp)
    end

    #
    # == Description
    #
    # Creates a new URI::MailTo object from generic URL components with
    # no syntax checking.
    #
    # This method is usually called from URI::parse, which checks
    # the validity of each component.
    #
    def initialize(*arg)
      super(*arg)

      @to = nil
      @headers = []

      # The RFC3986 parser does not normally populate opaque
      @opaque = "?#{@query}" if @query && !@opaque

      unless @opaque
        raise InvalidComponentError,
          "missing opaque part for mailto URL"
      end
      to, header = @opaque.split('?', 2)
      # allow semicolon as a addr-spec separator
      # http://support.microsoft.com/kb/820868
      unless /\A(?:[^@,;]+@[^@,;]+(?:\z|[,;]))*\z/ =~ to
        raise InvalidComponentError,
          "unrecognised opaque part for mailtoURL: #{@opaque}"
      end

      if arg[10] # arg_check
        self.to = to
        self.headers = header
      else
        set_to(to)
        set_headers(header)
      end
    end

    # The primary e-mail address of the URL, as a String
    attr_reader :to

    # E-mail headers set by the URL, as an Array of Arrays
    attr_reader :headers

    # check the to +v+ component
    def check_to(v)
      return true unless v
      return true if v.size == 0

      v.split(/[,;]/).each do |addr|
        # check url safety as path-rootless
        if /\A(?:%\h\h|[!$&-.0-;=@-Z_a-z~])*\z/ !~ addr
          raise InvalidComponentError,
            "an address in 'to' is invalid as URI #{addr.dump}"
        end

        # check addr-spec
        # don't s/\+/ /g
        addr.gsub!(/%\h\h/, URI::TBLDECWWWCOMP_)
        if EMAIL_REGEXP !~ addr
          raise InvalidComponentError,
            "an address in 'to' is invalid as uri-escaped addr-spec #{addr.dump}"
        end
      end

      true
    end
    private :check_to

    # private setter for to +v+
    def set_to(v)
      @to = v
    end
    protected :set_to

    # setter for to +v+
    def to=(v)
      check_to(v)
      set_to(v)
      v
    end

    # check the headers +v+ component against either
    # * HEADER_REGEXP
    def check_headers(v)
      return true unless v
      return true if v.size == 0
      if HEADER_REGEXP !~ v
        raise InvalidComponentError,
          "bad component(expected opaque component): #{v}"
      end

      true
    end
    private :check_headers

    # private setter for headers +v+
    def set_headers(v)
      @headers = []
      if v
        v.split('&').each do |x|
          @headers << x.split(/=/, 2)
        end
      end
    end
    protected :set_headers

    # setter for headers +v+
    def headers=(v)
      check_headers(v)
      set_headers(v)
      v
    end

    # Constructs String from URI
    def to_s
      @scheme + ':' +
        if @to
          @to
        else
          ''
        end +
        if @headers.size > 0
          '?' + @headers.collect{|x| x.join('=')}.join('&')
        else
          ''
        end +
        if @fragment
          '#' + @fragment
        else
          ''
        end
    end

    # Returns the RFC822 e-mail text equivalent of the URL, as a String.
    #
    # Example:
    #
    #   require 'uri'
    #
    #   uri = URI.parse("mailto:ruby-list@ruby-lang.org?Subject=subscribe&cc=myaddr")
    #   uri.to_mailtext
    #   # => "To: ruby-list@ruby-lang.org\nSubject: subscribe\nCc: myaddr\n\n\n"
    #
    def to_mailtext
      to = URI.decode_www_form_component(@to)
      head = ''
      body = ''
      @headers.each do |x|
        case x[0]
        when 'body'
          body = URI.decode_www_form_component(x[1])
        when 'to'
          to << ', ' + URI.decode_www_form_component(x[1])
        else
          head << URI.decode_www_form_component(x[0]).capitalize + ': ' +
            URI.decode_www_form_component(x[1])  + "\n"
        end
      end

      "To: #{to}
#{head}
#{body}
"
    end
    alias to_rfc822text to_mailtext
  end

  @@schemes['MAILTO'] = MailTo
end
