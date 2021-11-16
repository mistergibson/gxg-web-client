# format.rb: Written by Tadayoshi Funaba 1999-2009
# $Id: format.rb,v 2.43 2008-01-17 20:16:31+09 tadf Exp $

class Date

  module Format # :nodoc:

    MONTHS = {
      'january'  => 1, 'february' => 2, 'march'    => 3, 'april'    => 4,
      'may'      => 5, 'june'     => 6, 'july'     => 7, 'august'   => 8,
      'september'=> 9, 'october'  =>10, 'november' =>11, 'december' =>12
    }

    DAYS = {
      'sunday'   => 0, 'monday'   => 1, 'tuesday'  => 2, 'wednesday'=> 3,
      'thursday' => 4, 'friday'   => 5, 'saturday' => 6
    }

    ABBR_MONTHS = {
      'jan'      => 1, 'feb'      => 2, 'mar'      => 3, 'apr'      => 4,
      'may'      => 5, 'jun'      => 6, 'jul'      => 7, 'aug'      => 8,
      'sep'      => 9, 'oct'      =>10, 'nov'      =>11, 'dec'      =>12
    }

    ABBR_DAYS = {
      'sun'      => 0, 'mon'      => 1, 'tue'      => 2, 'wed'      => 3,
      'thu'      => 4, 'fri'      => 5, 'sat'      => 6
    }

    ZONES = {
      'ut'  =>  0*3600, 'gmt' =>  0*3600, 'est' => -5*3600, 'edt' => -4*3600,
      'cst' => -6*3600, 'cdt' => -5*3600, 'mst' => -7*3600, 'mdt' => -6*3600,
      'pst' => -8*3600, 'pdt' => -7*3600,
      'a'   =>  1*3600, 'b'   =>  2*3600, 'c'   =>  3*3600, 'd'   =>  4*3600,
      'e'   =>  5*3600, 'f'   =>  6*3600, 'g'   =>  7*3600, 'h'   =>  8*3600,
      'i'   =>  9*3600, 'k'   => 10*3600, 'l'   => 11*3600, 'm'   => 12*3600,
      'n'   => -1*3600, 'o'   => -2*3600, 'p'   => -3*3600, 'q'   => -4*3600,
      'r'   => -5*3600, 's'   => -6*3600, 't'   => -7*3600, 'u'   => -8*3600,
      'v'   => -9*3600, 'w'   =>-10*3600, 'x'   =>-11*3600, 'y'   =>-12*3600,
      'z'   =>  0*3600,

      'utc' =>  0*3600, 'wet' =>  0*3600,
      'at'  => -2*3600, 'brst'=> -2*3600, 'ndt' => -(2*3600+1800),
      'art' => -3*3600, 'adt' => -3*3600, 'brt' => -3*3600, 'clst'=> -3*3600,
      'nst' => -(3*3600+1800),
      'ast' => -4*3600, 'clt' => -4*3600,
      'akdt'=> -8*3600, 'ydt' => -8*3600,
      'akst'=> -9*3600, 'hadt'=> -9*3600, 'hdt' => -9*3600, 'yst' => -9*3600,
      'ahst'=>-10*3600, 'cat' =>-10*3600, 'hast'=>-10*3600, 'hst' =>-10*3600,
      'nt'  =>-11*3600,
      'idlw'=>-12*3600,
      'bst' =>  1*3600, 'cet' =>  1*3600, 'fwt' =>  1*3600, 'met' =>  1*3600,
      'mewt'=>  1*3600, 'mez' =>  1*3600, 'swt' =>  1*3600, 'wat' =>  1*3600,
      'west'=>  1*3600,
      'cest'=>  2*3600, 'eet' =>  2*3600, 'fst' =>  2*3600, 'mest'=>  2*3600,
      'mesz'=>  2*3600, 'sast'=>  2*3600, 'sst' =>  2*3600,
      'bt'  =>  3*3600, 'eat' =>  3*3600, 'eest'=>  3*3600, 'msk' =>  3*3600,
      'msd' =>  4*3600, 'zp4' =>  4*3600,
      'zp5' =>  5*3600, 'ist' =>  (5*3600+1800),
      'zp6' =>  6*3600,
      'wast'=>  7*3600,
      'cct' =>  8*3600, 'sgt' =>  8*3600, 'wadt'=>  8*3600,
      'jst' =>  9*3600, 'kst' =>  9*3600,
      'east'=> 10*3600, 'gst' => 10*3600,
      'eadt'=> 11*3600,
      'idle'=> 12*3600, 'nzst'=> 12*3600, 'nzt' => 12*3600,
      'nzdt'=> 13*3600,

      'afghanistan'           =>   16200, 'alaskan'               =>  -32400,
      'arab'                  =>   10800, 'arabian'               =>   14400,
      'arabic'                =>   10800, 'atlantic'              =>  -14400,
      'aus central'           =>   34200, 'aus eastern'           =>   36000,
      'azores'                =>   -3600, 'canada central'        =>  -21600,
      'cape verde'            =>   -3600, 'caucasus'              =>   14400,
      'cen. australia'        =>   34200, 'central america'       =>  -21600,
      'central asia'          =>   21600, 'central europe'        =>    3600,
      'central european'      =>    3600, 'central pacific'       =>   39600,
      'central'               =>  -21600, 'china'                 =>   28800,
      'dateline'              =>  -43200, 'e. africa'             =>   10800,
      'e. australia'          =>   36000, 'e. europe'             =>    7200,
      'e. south america'      =>  -10800, 'eastern'               =>  -18000,
      'egypt'                 =>    7200, 'ekaterinburg'          =>   18000,
      'fiji'                  =>   43200, 'fle'                   =>    7200,
      'greenland'             =>  -10800, 'greenwich'             =>       0,
      'gtb'                   =>    7200, 'hawaiian'              =>  -36000,
      'india'                 =>   19800, 'iran'                  =>   12600,
      'jerusalem'             =>    7200, 'korea'                 =>   32400,
      'mexico'                =>  -21600, 'mid-atlantic'          =>   -7200,
      'mountain'              =>  -25200, 'myanmar'               =>   23400,
      'n. central asia'       =>   21600, 'nepal'                 =>   20700,
      'new zealand'           =>   43200, 'newfoundland'          =>  -12600,
      'north asia east'       =>   28800, 'north asia'            =>   25200,
      'pacific sa'            =>  -14400, 'pacific'               =>  -28800,
      'romance'               =>    3600, 'russian'               =>   10800,
      'sa eastern'            =>  -10800, 'sa pacific'            =>  -18000,
      'sa western'            =>  -14400, 'samoa'                 =>  -39600,
      'se asia'               =>   25200, 'malay peninsula'       =>   28800,
      'south africa'          =>    7200, 'sri lanka'             =>   21600,
      'taipei'                =>   28800, 'tasmania'              =>   36000,
      'tokyo'                 =>   32400, 'tonga'                 =>   46800,
      'us eastern'            =>  -18000, 'us mountain'           =>  -25200,
      'vladivostok'           =>   36000, 'w. australia'          =>   28800,
      'w. central africa'     =>    3600, 'w. europe'             =>    3600,
      'west asia'             =>   18000, 'west pacific'          =>   36000,
      'yakutsk'               =>   32400
    }

    [MONTHS, DAYS, ABBR_MONTHS, ABBR_DAYS, ZONES].each do |x|
      x.freeze
    end

    class Bag # :nodoc:

      def initialize
        @elem = {}
      end

      def method_missing(t, *args, &block)
        t = t.to_s
        set = t.chomp!('=')
        t = t.intern
        if set
          @elem[t] = args[0]
        else
          @elem[t]
        end
      end

      def to_hash
        @elem.reject{|k, v| /\A_/ =~ k.to_s || v.nil?}
      end

    end

  end

  def strftime(fmt='%F')
    Time.now.strftime(fmt)
  end

# alias_method :format, :strftime

  def asctime() strftime('%c') end

  alias_method :ctime, :asctime

  def iso8601() strftime('%F') end

  def rfc3339() strftime('%FT%T%:z') end

  def xmlschema() iso8601 end # :nodoc:

  def rfc2822() strftime('%a, %-d %b %Y %T %z') end

  alias_method :rfc822, :rfc2822

  def httpdate() new_offset(0).strftime('%a, %d %b %Y %T GMT') end # :nodoc:

  def jisx0301
    if jd < 2405160
      strftime('%F')
    else
      case jd
      when 2405160...2419614
        g = 'M%02d' % (year - 1867)
      when 2419614...2424875
        g = 'T%02d' % (year - 1911)
      when 2424875...2447535
        g = 'S%02d' % (year - 1925)
      else
        g = 'H%02d' % (year - 1988)
      end
      g + strftime('.%m.%d')
    end
  end

=begin
  def beat(n=0)
    i, f = (new_offset(HOURS_IN_DAY).day_fraction * 1000).divmod(1)
    ('@%03d' % i) +
      if n < 1
        ''
      else
        '.%0*d' % [n, (f / Rational(1, 10**n)).round]
      end
  end
=end

  def self.num_pattern? (s) # :nodoc:
    /\A%[EO]?[CDdeFGgHIjkLlMmNQRrSsTUuVvWwXxYy\d]/ =~ s || /\A\d/ =~ s
  end

  private_class_method :num_pattern?

  def self._strptime_i(str, fmt, e) # :nodoc:
    fmt.scan(/%([EO]?(?::{1,3}z|.))|(.)/m) do |s, c|
      a = $&
      if s
        case s
        when 'A', 'a'
          return unless str.sub!(/\A(#{Format::DAYS.keys.join('|')})/io, '') ||
                        str.sub!(/\A(#{Format::ABBR_DAYS.keys.join('|')})/io, '')
          val = Format::DAYS[$1.downcase] || Format::ABBR_DAYS[$1.downcase]
          return unless val
          e.wday = val
        when 'B', 'b', 'h'
          return unless str.sub!(/\A(#{Format::MONTHS.keys.join('|')})/io, '') ||
                        str.sub!(/\A(#{Format::ABBR_MONTHS.keys.join('|')})/io, '')
          val = Format::MONTHS[$1.downcase] || Format::ABBR_MONTHS[$1.downcase]
          return unless val
          e.mon = val
        when 'C', 'EC'
          return unless str.sub!(if num_pattern?($')
                                 then /\A([-+]?\d{1,2})/
                                 else /\A([-+]?\d{1,})/
                                 end, '')
          val = $1.to_i
          e._cent = val
        when 'c', 'Ec'
          return unless _strptime_i(str, '%a %b %e %H:%M:%S %Y', e)
        when 'D'
          return unless _strptime_i(str, '%m/%d/%y', e)
        when 'd', 'e', 'Od', 'Oe'
          return unless str.sub!(/\A( \d|\d{1,2})/, '')
          val = $1.to_i
          return unless (1..31) === val
          e.mday = val
        when 'F'
          return unless _strptime_i(str, '%Y-%m-%d', e)
        when 'G'
          return unless str.sub!(if num_pattern?($')
                                 then /\A([-+]?\d{1,4})/
                                 else /\A([-+]?\d{1,})/
                                 end, '')
          val = $1.to_i
          e.cwyear = val
        when 'g'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (0..99) === val
          e.cwyear = val
          e._cent ||= if val >= 69 then 19 else 20 end
        when 'H', 'k', 'OH'
          return unless str.sub!(/\A( \d|\d{1,2})/, '')
          val = $1.to_i
          return unless (0..24) === val
          e.hour = val
        when 'I', 'l', 'OI'
          return unless str.sub!(/\A( \d|\d{1,2})/, '')
          val = $1.to_i
          return unless (1..12) === val
          e.hour = val
        when 'j'
          return unless str.sub!(/\A(\d{1,3})/, '')
          val = $1.to_i
          return unless (1..366) === val
          e.yday = val
        when 'L'
          return unless str.sub!(if num_pattern?($')
                                 then /\A([-+]?\d{1,3})/
                                 else /\A([-+]?\d{1,})/
                                 end, '')
#         val = Rational($1.to_i, 10**3)
          val = Rational($1.to_i, 10**$1.size)
          e.sec_fraction = val
        when 'M', 'OM'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (0..59) === val
          e.min = val
        when 'm', 'Om'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (1..12) === val
          e.mon = val
        when 'N'
          return unless str.sub!(if num_pattern?($')
                                 then /\A([-+]?\d{1,9})/
                                 else /\A([-+]?\d{1,})/
                                 end, '')
#         val = Rational($1.to_i, 10**9)
          val = Rational($1.to_i, 10**$1.size)
          e.sec_fraction = val
        when 'n', 't'
          return unless _strptime_i(str, "\s", e)
        when 'P', 'p'
          return unless str.sub!(/\A([ap])(?:m\b|\.m\.)/i, '')
          e._merid = if $1.downcase == 'a' then 0 else 12 end
        when 'Q'
          return unless str.sub!(/\A(-?\d{1,})/, '')
          val = Rational($1.to_i, 10**3)
          e.seconds = val
        when 'R'
          return unless _strptime_i(str, '%H:%M', e)
        when 'r'
          return unless _strptime_i(str, '%I:%M:%S %p', e)
        when 'S', 'OS'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (0..60) === val
          e.sec = val
        when 's'
          return unless str.sub!(/\A(-?\d{1,})/, '')
          val = $1.to_i
          e.seconds = val
        when 'T'
          return unless _strptime_i(str, '%H:%M:%S', e)
        when 'U', 'W', 'OU', 'OW'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (0..53) === val
          e.__send__(if s[-1,1] == 'U' then :wnum0= else :wnum1= end, val)
        when 'u', 'Ou'
          return unless str.sub!(/\A(\d{1})/, '')
          val = $1.to_i
          return unless (1..7) === val
          e.cwday = val
        when 'V', 'OV'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (1..53) === val
          e.cweek = val
        when 'v'
          return unless _strptime_i(str, '%e-%b-%Y', e)
        when 'w'
          return unless str.sub!(/\A(\d{1})/, '')
          val = $1.to_i
          return unless (0..6) === val
          e.wday = val
        when 'X', 'EX'
          return unless _strptime_i(str, '%H:%M:%S', e)
        when 'x', 'Ex'
          return unless _strptime_i(str, '%m/%d/%y', e)
        when 'Y', 'EY'
          return unless str.sub!(if num_pattern?($')
                                 then /\A([-+]?\d{1,4})/
                                 else /\A([-+]?\d{1,})/
                                 end, '')
          val = $1.to_i
          e.year = val
        when 'y', 'Ey', 'Oy'
          return unless str.sub!(/\A(\d{1,2})/, '')
          val = $1.to_i
          return unless (0..99) === val
          e.year = val
          e._cent ||= if val >= 69 then 19 else 20 end
        when 'Z', /\A:{0,3}z/
          return unless str.sub!(/\A((?:gmt|utc?)?[-+]\d+(?:[,.:]\d+(?::\d+)?)?
                                    |[[:alpha:].\s]+(?:standard|daylight)\s+time\b
                                    |[[:alpha:]]+(?:\s+dst)?\b
                                    )/ix, '')
          val = $1
          e.zone = val
          offset = zone_to_diff(val)
          e.offset = offset
        when '%'
          return unless str.sub!(/\A%/, '')
        when '+'
          return unless _strptime_i(str, '%a %b %e %H:%M:%S %Z %Y', e)
        else
          return unless str.sub!(Regexp.new('\\A' + Regexp.quote(a)), '')
        end
      else
        case c
        when /\A\s/
          str.sub!(/\A\s+/, '')
        else
          return unless str.sub!(Regexp.new('\\A' + Regexp.quote(a)), '')
        end
      end
    end
  end

  private_class_method :_strptime_i

  def self._strptime(str, fmt='%F')
    str = str.dup
    e = Format::Bag.new
    return unless _strptime_i(str, fmt, e)

    if e._cent
      if e.cwyear
        e.cwyear += e._cent * 100
      end
      if e.year
        e.  year += e._cent * 100
      end
    end

    if e._merid
      if e.hour
        e.hour %= 12
        e.hour += e._merid
      end
    end

    unless str.empty?
      e.leftover = str
    end

    e.to_hash
  end

  def self.s3e(e, y, m, d, bc=false)
    unless String === m
      m = m.to_s
    end

    if y && m && !d
      y, m, d = d, y, m
    end

    if y == nil
      if d && d.size > 2
        y = d
        d = nil
      end
      if d && d[0,1] == "'"
        y = d
        d = nil
      end
    end

    if y
      y.scan(/(\d+)(.+)?/)
      if $2
        y, d = d, $1
      end
    end

    if m
      if m[0,1] == "'" || m.size > 2
        y, m, d = m, d, y # us -> be
      end
    end

    if d
      if d[0,1] == "'" || d.size > 2
        y, d = d, y
      end
    end

    if y
      y =~ /([-+])?(\d+)/
      if $1 || $2.size > 2
        c = false
      end
      iy = $&.to_i
      if bc
        iy = -iy + 1
      end
      e.year = iy
    end

    if m
      m =~ /\d+/
      e.mon = $&.to_i
    end

    if d
      d =~ /\d+/
      e.mday = $&.to_i
    end

    if c != nil
      e._comp = c
    end

  end

  private_class_method :s3e

  def self._parse_day(str, e) # :nodoc:
    if str.sub!(/\b(#{Format::ABBR_DAYS.keys.join('|')})[^-\d\s]*/io, ' ')
      e.wday = Format::ABBR_DAYS[$1.downcase]
      true
=begin
    elsif str.sub!(/\b(?!\dth)(su|mo|tu|we|th|fr|sa)\b/i, ' ')
      e.wday = %w(su mo tu we th fr sa).index($1.downcase)
      true
=end
    end
  end

  def self._parse_time(str, e) # :nodoc:
    if str.sub!(
                /(
                   (?:
                     \d+\s*:\s*\d+
                     (?:
                       \s*:\s*\d+(?:[,.]\d*)?
                     )?
                   |
                     \d+\s*h(?:\s*\d+m?(?:\s*\d+s?)?)?
                   )
                   (?:
                     \s*
                     [ap](?:m\b|\.m\.)
                   )?
                 |
                   \d+\s*[ap](?:m\b|\.m\.)
                 )
                 (?:
                   \s*
                   (
                     (?:gmt|utc?)?[-+]\d+(?:[,.:]\d+(?::\d+)?)?
                   |
                     [[:alpha:].\s]+(?:standard|daylight)\stime\b
                   |
                     [[:alpha:]]+(?:\sdst)?\b
                   )
                 )?
                /ix,
                ' ')

      t = $1
      e.zone = $2 if $2

      t =~ /\A(\d+)h?
              (?:\s*:?\s*(\d+)m?
                (?:
                  \s*:?\s*(\d+)(?:[,.](\d+))?s?
                )?
              )?
            (?:\s*([ap])(?:m\b|\.m\.))?/ix

      e.hour = $1.to_i
      e.min = $2.to_i if $2
      e.sec = $3.to_i if $3
      e.sec_fraction = Rational($4.to_i, 10**$4.size) if $4

      if $5
        e.hour %= 12
        if $5.downcase == 'p'
          e.hour += 12
        end
      end
      true
    end
  end

=begin
  def self._parse_beat(str, e) # :nodoc:
    if str.sub!(/@\s*(\d+)(?:[,.](\d*))?/, ' ')
      beat = Rational($1.to_i)
      beat += Rational($2.to_i, 10**$2.size) if $2
      secs = Rational(beat, 1000)
      h, min, s, fr = self.day_fraction_to_time(secs)
      e.hour = h
      e.min = min
      e.sec = s
      e.sec_fraction = fr * 86400
      e.zone = '+01:00'
      true
    end
  end
=end

  def self._parse_eu(str, e) # :nodoc:
    if str.sub!(
                /'?(\d+)[^-\d\s]*
                 \s*
                 (#{Format::ABBR_MONTHS.keys.join('|')})[^-\d\s']*
                 (?:
                   \s*
                   (c(?:e|\.e\.)|b(?:ce|\.c\.e\.)|a(?:d|\.d\.)|b(?:c|\.c\.))?
                   \s*
                   ('?-?\d+(?:(?:st|nd|rd|th)\b)?)
                 )?
                /iox,
                ' ') # '
      s3e(e, $4, Format::ABBR_MONTHS[$2.downcase], $1,
          $3 && $3[0,1].downcase == 'b')
      true
    end
  end

  def self._parse_us(str, e) # :nodoc:
    if str.sub!(
                /\b(#{Format::ABBR_MONTHS.keys.join('|')})[^-\d\s']*
                 \s*
                 ('?\d+)[^-\d\s']*
                 (?:
                   \s*
                   (c(?:e|\.e\.)|b(?:ce|\.c\.e\.)|a(?:d|\.d\.)|b(?:c|\.c\.))?
                   \s*
                   ('?-?\d+)
                 )?
                /iox,
                ' ') # '
      s3e(e, $4, Format::ABBR_MONTHS[$1.downcase], $2,
          $3 && $3[0,1].downcase == 'b')
      true
    end
  end

  def self._parse_iso(str, e) # :nodoc:
    if str.sub!(/('?[-+]?\d+)-(\d+)-('?-?\d+)/, ' ')
      s3e(e, $1, $2, $3)
      true
    end
  end

  def self._parse_iso2(str, e) # :nodoc:
    if str.sub!(/\b(\d{2}|\d{4})?-?w(\d{2})(?:-?(\d))?\b/i, ' ')
      e.cwyear = $1.to_i if $1
      e.cweek = $2.to_i
      e.cwday = $3.to_i if $3
      true
    elsif str.sub!(/-w-(\d)\b/i, ' ')
      e.cwday = $1.to_i
      true
    elsif str.sub!(/--(\d{2})?-(\d{2})\b/, ' ')
      e.mon = $1.to_i if $1
      e.mday = $2.to_i
      true
    elsif str.sub!(/--(\d{2})(\d{2})?\b/, ' ')
      e.mon = $1.to_i
      e.mday = $2.to_i if $2
      true
    elsif /[,.](\d{2}|\d{4})-\d{3}\b/ !~ str &&
        str.sub!(/\b(\d{2}|\d{4})-(\d{3})\b/, ' ')
      e.year = $1.to_i
      e.yday = $2.to_i
      true
    elsif /\d-\d{3}\b/ !~ str &&
        str.sub!(/\b-(\d{3})\b/, ' ')
      e.yday = $1.to_i
      true
    end
  end

  def self._parse_jis(str, e) # :nodoc:
    if str.sub!(/\b([mtsh])(\d+)\.(\d+)\.(\d+)/i, ' ')
      era = { 'm'=>1867,
              't'=>1911,
              's'=>1925,
              'h'=>1988
          }[$1.downcase]
      e.year = $2.to_i + era
      e.mon = $3.to_i
      e.mday = $4.to_i
      true
    end
  end

  def self._parse_vms(str, e) # :nodoc:
    if str.sub!(/('?-?\d+)-(#{Format::ABBR_MONTHS.keys.join('|')})[^-]*
                -('?-?\d+)/iox, ' ')
      s3e(e, $3, Format::ABBR_MONTHS[$2.downcase], $1)
      true
    elsif str.sub!(/\b(#{Format::ABBR_MONTHS.keys.join('|')})[^-]*
                -('?-?\d+)(?:-('?-?\d+))?/iox, ' ')
      s3e(e, $3, Format::ABBR_MONTHS[$1.downcase], $2)
      true
    end
  end

  def self._parse_sla(str, e) # :nodoc:
    if str.sub!(%r|('?-?\d+)/\s*('?\d+)(?:\D\s*('?-?\d+))?|, ' ') # '
      s3e(e, $1, $2, $3)
      true
    end
  end

  def self._parse_dot(str, e) # :nodoc:
    if str.sub!(%r|('?-?\d+)\.\s*('?\d+)\.\s*('?-?\d+)|, ' ') # '
      s3e(e, $1, $2, $3)
      true
    end
  end

  def self._parse_year(str, e) # :nodoc:
    if str.sub!(/'(\d+)\b/, ' ')
      e.year = $1.to_i
      true
    end
  end

  def self._parse_mon(str, e) # :nodoc:
    if str.sub!(/\b(#{Format::ABBR_MONTHS.keys.join('|')})\S*/io, ' ')
      e.mon = Format::ABBR_MONTHS[$1.downcase]
      true
    end
  end

  def self._parse_mday(str, e) # :nodoc:
    if str.sub!(/(\d+)(st|nd|rd|th)\b/i, ' ')
      e.mday = $1.to_i
      true
    end
  end

  def self._parse_ddd(str, e) # :nodoc:
    if str.sub!(
                /([-+]?)(\d{2,14})
                  (?:
                    \s*
                    t?
                    \s*
                    (\d{2,6})?(?:[,.](\d*))?
                  )?
                  (?:
                    \s*
                    (
                      z\b
                    |
                      [-+]\d{1,4}\b
                    |
                      \[[-+]?\d[^\]]*\]
                    )
                  )?
                /ix,
                ' ')
      case $2.size
      when 2
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
        else
          e.mday = $2[ 0, 2].to_i
        end
      when 4
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
          e.min  = $2[-4, 2].to_i
        else
          e.mon  = $2[ 0, 2].to_i
          e.mday = $2[ 2, 2].to_i
        end
      when 6
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
          e.min  = $2[-4, 2].to_i
          e.hour = $2[-6, 2].to_i
        else
          e.year = ($1 + $2[ 0, 2]).to_i
          e.mon  = $2[ 2, 2].to_i
          e.mday = $2[ 4, 2].to_i
        end
      when 8, 10, 12, 14
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
          e.min  = $2[-4, 2].to_i
          e.hour = $2[-6, 2].to_i
          e.mday = $2[-8, 2].to_i
          if $2.size >= 10
            e.mon  = $2[-10, 2].to_i
          end
          if $2.size == 12
            e.year = ($1 + $2[-12, 2]).to_i
          end
          if $2.size == 14
            e.year = ($1 + $2[-14, 4]).to_i
            e._comp = false
          end
        else
          e.year = ($1 + $2[ 0, 4]).to_i
          e.mon  = $2[ 4, 2].to_i
          e.mday = $2[ 6, 2].to_i
          e.hour = $2[ 8, 2].to_i if $2.size >= 10
          e.min  = $2[10, 2].to_i if $2.size >= 12
          e.sec  = $2[12, 2].to_i if $2.size >= 14
          e._comp = false
        end
      when 3
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
          e.min  = $2[-3, 1].to_i
        else
          e.yday = $2[ 0, 3].to_i
        end
      when 5
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
          e.min  = $2[-4, 2].to_i
          e.hour = $2[-5, 1].to_i
        else
          e.year = ($1 + $2[ 0, 2]).to_i
          e.yday = $2[ 2, 3].to_i
        end
      when 7
        if $3.nil? && $4
          e.sec  = $2[-2, 2].to_i
          e.min  = $2[-4, 2].to_i
          e.hour = $2[-6, 2].to_i
          e.mday = $2[-7, 1].to_i
        else
          e.year = ($1 + $2[ 0, 4]).to_i
          e.yday = $2[ 4, 3].to_i
        end
      end
      if $3
        if $4
          case $3.size
          when 2, 4, 6
            e.sec  = $3[-2, 2].to_i
            e.min  = $3[-4, 2].to_i if $3.size >= 4
            e.hour = $3[-6, 2].to_i if $3.size >= 6
          end
        else
          case $3.size
          when 2, 4, 6
            e.hour = $3[ 0, 2].to_i
            e.min  = $3[ 2, 2].to_i if $3.size >= 4
            e.sec  = $3[ 4, 2].to_i if $3.size >= 6
          end
        end
      end
      if $4
        e.sec_fraction = Rational($4.to_i, 10**$4.size)
      end
      if $5
        e.zone = $5
        if e.zone[0,1] == '['
          o, n, = e.zone[1..-2].split(':')
          e.zone = n || o
          if /\A\d/ =~ o
            o = format('+%s', o)
          end
          e.offset = zone_to_diff(o)
        end
      end
      true
    end
  end

  private_class_method :_parse_day, :_parse_time, # :_parse_beat,
        :_parse_eu, :_parse_us, :_parse_iso, :_parse_iso2,
        :_parse_jis, :_parse_vms, :_parse_sla, :_parse_dot,
        :_parse_year, :_parse_mon, :_parse_mday, :_parse_ddd

  def self._parse(str, comp=true)
    # Newer MRI version (written in C converts non-strings to strings
    # and also has other checks like all ascii.
    str = str.to_str if !str.kind_of?(::String) && str.respond_to?(:to_str)
    str = str.dup

    e = Format::Bag.new

    e._comp = comp

    str.gsub!(/[^-+',.\/:@[:alnum:]\[\]]+/, ' ')

    _parse_time(str, e) # || _parse_beat(str, e)
    _parse_day(str, e)

    _parse_eu(str, e)     ||
    _parse_us(str, e)     ||
    _parse_iso(str, e)    ||
    _parse_jis(str, e)    ||
    _parse_vms(str, e)    ||
    _parse_sla(str, e)    ||
    _parse_dot(str, e)    ||
    _parse_iso2(str, e)   ||
    _parse_year(str, e)   ||
    _parse_mon(str, e)    ||
    _parse_mday(str, e)   ||
    _parse_ddd(str, e)

    if str.sub!(/\b(bc\b|bce\b|b\.c\.|b\.c\.e\.)/i, ' ')
      if e.year
        e.year = -e.year + 1
      end
    end

    if str.sub!(/\A\s*(\d{1,2})\s*\z/, ' ')
      if e.hour && !e.mday
        v = $1.to_i
        if (1..31) === v
          e.mday = v
        end
      end
      if e.mday && !e.hour
        v = $1.to_i
        if (0..24) === v
          e.hour = v
        end
      end
    end

    if e._comp
      if e.cwyear
        if e.cwyear >= 0 && e.cwyear <= 99
          e.cwyear += if e.cwyear >= 69
                      then 1900 else 2000 end
        end
      end
      if e.year
        if e.year >= 0 && e.year <= 99
          e.year += if e.year >= 69
                    then 1900 else 2000 end
        end
      end
    end

    e.offset ||= zone_to_diff(e.zone) if e.zone

    e.to_hash
  end

  def self._iso8601(str) # :nodoc:
    h = {}
    if /\A\s*
      (?:
          (?<year>[-+]?\d{2,} | -) - (?<mon>\d{2})? - (?<mday>\d{2})
        | (?<year>[-+]?\d{2,})? - (?<yday>\d{3})
        | (?<cwyear>\d{4}|\d{2})? - w(?<cweek>\d{2}) - (?<cwday>\d)
        | -w- (?<cwday2>\d)
      )
      (?:
        t
        (?<hour>\d{2}) : (?<min>\d{2}) (?: :(?<sec>\d{2})(?:[,.](?<sec_fraction>\d+))?)?
        (?<zone>z | [-+]\d{2}(?::?\d{2})?)?
      )?
      \s*\z/ix =~ str

      if mday
        h[:mday] = i mday
        h[:year] = comp_year69(year) if year != "-"

        if mon
          h[:mon] = i mon
        else
          return {} if year != "-"
        end
      elsif yday
        h[:yday] = i yday
        h[:year] = comp_year69(year) if year
      elsif cwday
        h[:cweek] = i cweek
        h[:cwday] = i cwday
        h[:cwyear] = comp_year69(cwyear) if cwyear
      elsif cwday2
        h[:cwday] = i cwday2
      end

      if hour
        h[:hour] = i hour
        h[:min] = i min
        h[:sec] = i sec if sec
      end

      h[:sec_fraction] = Rational(sec_fraction.to_i, 10**sec_fraction.size) if sec_fraction # JRuby bug fix!
      set_zone(h, zone)

    elsif /\A\s*
      (?:
          (?<year>[-+]?(?:\d{4}|\d{2})|--) (?<mon>\d{2}|-) (?<mday>\d{2})
        | (?<year>[-+]?(?:\d{4}|\d{2})) (?<yday>\d{3})
        | -(?<yday2>\d{3})
        | (?<cwyear>\d{4}|\d{2}|-) w(?<cweek>\d{2}|-) (?<cwday>\d)
      )
      (?:
        t?
        (?<hour>\d{2}) (?<min>\d{2}) (?:(?<sec>\d{2})(?:[,.](?<sec_fraction>\d+))?)?
        (?<zone>z | [-+]\d{2}(?:\d{2})?)?
      )?
      \s*\z/ix =~ str

      if mday
        h[:mday] = i mday
        h[:year] = comp_year69(year) if year != "--"
        if mon != "-"
          h[:mon] = i mon
        else
          return {} if year != "--"
        end
      elsif yday
        h[:yday] = i yday
        h[:year] = comp_year69(year)
      elsif yday2
        h[:yday] = i yday2
      elsif cwday
        h[:cweek] = i cweek if cweek != "-"
        h[:cwday] = i cwday
        h[:cwyear] = comp_year69(cwyear) if cwyear != "-"
      end

      if hour
        h[:hour] = i hour
        h[:min] = i min
        h[:sec] = i sec if sec
      end

      h[:sec_fraction] = Rational(sec_fraction.to_i, 10**sec_fraction.size) if sec_fraction # JRuby bug fix!
      set_zone(h, zone)

    elsif /\A\s*
      (?<hour>\d{2})
      (?:
        : (?<min>\d{2})
        (?:
          :(?<sec>\d{2})(?:[,.](?<sec_fraction>\d+))?
          (?<zone>z | [-+]\d{2}(?: :?\d{2})?)?
        )?
      |
        (?<min>\d{2})
        (?:
          (?<sec>\d{2})(?:[,.](?<sec_fraction>\d+))?
          (?<zone>z | [-+]\d{2}(?:\d{2})?)?
        )?
      )
      \s*\z/ix =~ str

      h[:hour] = i hour
      h[:min] = i min
      h[:sec] = i sec if sec
      h[:sec_fraction] = Rational(sec_fraction.to_i, 10**sec_fraction.size) if sec_fraction # JRuby bug fix!
      set_zone(h, zone)
    end
    h
  end

  def self._rfc3339(str) # :nodoc:
    if /\A\s*-?\d{4}-\d{2}-\d{2} # allow minus, anyway
        (t|\s)
        \d{2}:\d{2}:\d{2}(\.\d+)?
        (z|[-+]\d{2}:\d{2})\s*\z/ix =~ str
      _parse(str)
    else
      {}
    end
  end

  def self._xmlschema(str) # :nodoc:
    if /\A\s*(-?\d{4,})(?:-(\d{2})(?:-(\d{2}))?)?
        (?:t
          (\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?)?
        (z|[-+]\d{2}:\d{2})?\s*\z/ix =~ str
      e = Format::Bag.new
      e.year = $1.to_i
      e.mon = $2.to_i if $2
      e.mday = $3.to_i if $3
      e.hour = $4.to_i if $4
      e.min = $5.to_i if $5
      e.sec = $6.to_i if $6
      e.sec_fraction = Rational($7.to_i, 10**$7.size) if $7
      if $8
        e.zone = $8
        e.offset = zone_to_diff($8)
      end
      e.to_hash
    elsif /\A\s*(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?
        (z|[-+]\d{2}:\d{2})?\s*\z/ix =~ str
      e = Format::Bag.new
      e.hour = $1.to_i if $1
      e.min = $2.to_i if $2
      e.sec = $3.to_i if $3
      e.sec_fraction = Rational($4.to_i, 10**$4.size) if $4
      if $5
        e.zone = $5
        e.offset = zone_to_diff($5)
      end
      e.to_hash
    elsif /\A\s*(?:--(\d{2})(?:-(\d{2}))?|---(\d{2}))
        (z|[-+]\d{2}:\d{2})?\s*\z/ix =~ str
      e = Format::Bag.new
      e.mon = $1.to_i if $1
      e.mday = $2.to_i if $2
      e.mday = $3.to_i if $3
      if $4
        e.zone = $4
        e.offset = zone_to_diff($4)
      end
      e.to_hash
    else
      {}
    end
  end

  def self._rfc2822(str) # :nodoc:
    if /\A\s*(?:(?:#{Format::ABBR_DAYS.keys.join('|')})\s*,\s+)?
        \d{1,2}\s+
        (?:#{Format::ABBR_MONTHS.keys.join('|')})\s+
        -?(\d{2,})\s+ # allow minus, anyway
        \d{2}:\d{2}(:\d{2})?\s*
        (?:[-+]\d{4}|ut|gmt|e[sd]t|c[sd]t|m[sd]t|p[sd]t|[a-ik-z])\s*\z/iox =~ str
      e = _parse(str, false)
      if $1.size < 4
        if e[:year] < 50
          e[:year] += 2000
        elsif e[:year] < 1000
          e[:year] += 1900
        end
      end
      e
    else
      {}
    end
  end

  class << self; alias_method :_rfc822, :_rfc2822 end

  def self._httpdate(str) # :nodoc:
    if /\A\s*(#{Format::ABBR_DAYS.keys.join('|')})\s*,\s+
        \d{2}\s+
        (#{Format::ABBR_MONTHS.keys.join('|')})\s+
        -?\d{4}\s+ # allow minus, anyway
        \d{2}:\d{2}:\d{2}\s+
        gmt\s*\z/iox =~ str
      _rfc2822(str)
    elsif /\A\s*(#{Format::DAYS.keys.join('|')})\s*,\s+
        \d{2}\s*-\s*
        (#{Format::ABBR_MONTHS.keys.join('|')})\s*-\s*
        \d{2}\s+
        \d{2}:\d{2}:\d{2}\s+
        gmt\s*\z/iox =~ str
      _parse(str)
    elsif /\A\s*(#{Format::ABBR_DAYS.keys.join('|')})\s+
        (#{Format::ABBR_MONTHS.keys.join('|')})\s+
        \d{1,2}\s+
        \d{2}:\d{2}:\d{2}\s+
        \d{4}\s*\z/iox =~ str
      _parse(str)
    else
      {}
    end
  end

  def self._jisx0301(str) # :nodoc:
    if /\A\s*[mtsh]?\d{2}\.\d{2}\.\d{2}
        (t
        (\d{2}:\d{2}(:\d{2}([,.]\d*)?)?
        (z|[-+]\d{2}(:?\d{2})?)?)?)?\s*\z/ix =~ str
      if /\A\s*\d/ =~ str
        _parse(str.sub(/\A\s*(\d)/, 'h\1'))
      else
        _parse(str)
      end
    else
      _iso8601(str)
    end
  end

  t = Module.new do

    private

    def zone_to_diff(zone) # :nodoc:
      zone = zone.downcase
      if zone.sub!(/\s+(standard|daylight)\s+time\z/, '')
        dst = $1 == 'daylight'
      else
        dst = zone.sub!(/\s+dst\z/, '')
      end
      if Format::ZONES.include?(zone)
        offset = Format::ZONES[zone]
        offset += 3600 if dst
      elsif zone.sub!(/\A(?:gmt|utc?)?([-+])/, '')
        sign = $1
        if zone.include?(':')
          hour, min, sec, = zone.split(':')
        elsif zone.include?(',') || zone.include?('.')
          hour, fr, = zone.split(/[,.]/)
          min = Rational(fr.to_i, 10**fr.size) * 60
        else
          case zone.size
          when 3
            hour = zone[0,1]
            min = zone[1,2]
          else
            hour = zone[0,2]
            min = zone[2,2]
            sec = zone[4,2]
          end
        end
        offset = hour.to_i * 3600 + min.to_i * 60 + sec.to_i
        offset *= -1 if sign == '-'
      end
      offset
    end

  end

  extend  t
  include t

  extend Module.new {
    private
    def set_zone(h, zone)
      if zone
        h[:zone] = zone
        h[:offset] = zone_to_diff(zone)
      end
    end

    def comp_year69(year)
      y = i year
      if year.length < 4
        if y >= 69
          y + 1900
        else
          y + 2000
        end
      else
        y
      end
    end

    def i(str)
      Integer(str, 10)
    end
  }
end

class DateTime < Date

  def strftime(fmt='%FT%T%:z')
    super(fmt)
  end

  def self._strptime(str, fmt='%FT%T%z')
    super(str, fmt)
  end

  def iso8601_timediv(n) # :nodoc:
    n = n.to_i
    strftime('T%T' +
             if n < 1
               ''
             else
               '.%0*d' % [n, (sec_fraction * 10**n).round]
             end +
             '%:z')
  end

  private :iso8601_timediv

  def iso8601(n=0)
    super() + iso8601_timediv(n)
  end

  def rfc3339(n=0) iso8601(n) end

  def xmlschema(n=0) iso8601(n) end # :nodoc:

  def jisx0301(n=0)
    super() + iso8601_timediv(n)
  end

end
#
# date.rb - date and time library
#
# Author: Tadayoshi Funaba 1998-2011
#
# Documentation: William Webber <william@williamwebber.com>
#
#--
# $Id: date.rb,v 2.37 2008-01-17 20:16:31+09 tadf Exp $
#++
#
# == Overview
#
# This file provides two classes for working with
# dates and times.
#
# The first class, Date, represents dates.
# It works with years, months, weeks, and days.
# See the Date class documentation for more details.
#
# The second, DateTime, extends Date to include hours,
# minutes, seconds, and fractions of a second.  It
# provides basic support for time zones.  See the
# DateTime class documentation for more details.
#
# === Ways of calculating the date.
#
# In common usage, the date is reckoned in years since or
# before the Common Era (CE/BCE, also known as AD/BC), then
# as a month and day-of-the-month within the current year.
# This is known as the *Civil* *Date*, and abbreviated
# as +civil+ in the Date class.
#
# Instead of year, month-of-the-year,  and day-of-the-month,
# the date can also be reckoned in terms of year and
# day-of-the-year.  This is known as the *Ordinal* *Date*,
# and is abbreviated as +ordinal+ in the Date class.  (Note
# that referring to this as the Julian date is incorrect.)
#
# The date can also be reckoned in terms of year, week-of-the-year,
# and day-of-the-week.  This is known as the *Commercial*
# *Date*, and is abbreviated as +commercial+ in the
# Date class.  The commercial week runs Monday (day-of-the-week
# 1) to Sunday (day-of-the-week 7), in contrast to the civil
# week which runs Sunday (day-of-the-week 0) to Saturday
# (day-of-the-week 6).  The first week of the commercial year
# starts on the Monday on or before January 1, and the commercial
# year itself starts on this Monday, not January 1.
#
# For scientific purposes, it is convenient to refer to a date
# simply as a day count, counting from an arbitrary initial
# day.  The date first chosen for this was January 1, 4713 BCE.
# A count of days from this date is the *Julian* *Day* *Number*
# or *Julian* *Date*, which is abbreviated as +jd+ in the
# Date class.  This is in local time, and counts from midnight
# on the initial day.  The stricter usage is in UTC, and counts
# from midday on the initial day.  This is referred to in the
# Date class as the *Astronomical* *Julian* *Day* *Number*, and
# abbreviated as +ajd+.  In the Date class, the Astronomical
# Julian Day Number includes fractional days.
#
# Another absolute day count is the *Modified* *Julian* *Day*
# *Number*, which takes November 17, 1858 as its initial day.
# This is abbreviated as +mjd+ in the Date class.  There
# is also an *Astronomical* *Modified* *Julian* *Day* *Number*,
# which is in UTC and includes fractional days.  This is
# abbreviated as +amjd+ in the Date class.  Like the Modified
# Julian Day Number (and unlike the Astronomical Julian
# Day Number), it counts from midnight.
#
# Alternative calendars such as the Chinese Lunar Calendar,
# the Islamic Calendar, or the French Revolutionary Calendar
# are not supported by the Date class; nor are calendars that
# are based on an Era different from the Common Era, such as
# the Japanese Imperial Calendar or the Republic of China
# Calendar.
#
# === Calendar Reform
#
# The standard civil year is 365 days long.  However, the
# solar year is fractionally longer than this.  To account
# for this, a *leap* *year* is occasionally inserted.  This
# is a year with 366 days, the extra day falling on February 29.
# In the early days of the civil calendar, every fourth
# year without exception was a leap year.  This way of
# reckoning leap years is the *Julian* *Calendar*.
#
# However, the solar year is marginally shorter than 365 1/4
# days, and so the *Julian* *Calendar* gradually ran slow
# over the centuries.  To correct this, every 100th year
# (but not every 400th year) was excluded as a leap year.
# This way of reckoning leap years, which we use today, is
# the *Gregorian* *Calendar*.
#
# The Gregorian Calendar was introduced at different times
# in different regions.  The day on which it was introduced
# for a particular region is the *Day* *of* *Calendar*
# *Reform* for that region.  This is abbreviated as +sg+
# (for Start of Gregorian calendar) in the Date class.
#
# Two such days are of particular
# significance.  The first is October 15, 1582, which was
# the Day of Calendar Reform for Italy and most Catholic
# countries.  The second is September 14, 1752, which was
# the Day of Calendar Reform for England and its colonies
# (including what is now the United States).  These two
# dates are available as the constants Date::ITALY and
# Date::ENGLAND, respectively.  (By comparison, Germany and
# Holland, less Catholic than Italy but less stubborn than
# England, changed over in 1698; Sweden in 1753; Russia not
# till 1918, after the Revolution; and Greece in 1923.  Many
# Orthodox churches still use the Julian Calendar.  A complete
# list of Days of Calendar Reform can be found at
# http://www.polysyllabic.com/GregConv.html.)
#
# Switching from the Julian to the Gregorian calendar
# involved skipping a number of days to make up for the
# accumulated lag, and the later the switch was (or is)
# done, the more days need to be skipped.  So in 1582 in Italy,
# 4th October was followed by 15th October, skipping 10 days; in 1752
# in England, 2nd September was followed by 14th September, skipping
# 11 days; and if I decided to switch from Julian to Gregorian
# Calendar this midnight, I would go from 27th July 2003 (Julian)
# today to 10th August 2003 (Gregorian) tomorrow, skipping
# 13 days.  The Date class is aware of this gap, and a supposed
# date that would fall in the middle of it is regarded as invalid.
#
# The Day of Calendar Reform is relevant to all date representations
# involving years.  It is not relevant to the Julian Day Numbers,
# except for converting between them and year-based representations.
#
# In the Date and DateTime classes, the Day of Calendar Reform or
# +sg+ can be specified a number of ways.  First, it can be as
# the Julian Day Number of the Day of Calendar Reform.  Second,
# it can be using the constants Date::ITALY or Date::ENGLAND; these
# are in fact the Julian Day Numbers of the Day of Calendar Reform
# of the respective regions.  Third, it can be as the constant
# Date::JULIAN, which means to always use the Julian Calendar.
# Finally, it can be as the constant Date::GREGORIAN, which means
# to always use the Gregorian Calendar.
#
# Note: in the Julian Calendar, New Years Day was March 25.  The
# Date class does not follow this convention.
#
# === Time Zones
#
# DateTime objects support a simple representation
# of time zones.  Time zones are represented as an offset
# from UTC, as a fraction of a day.  This offset is the
# how much local time is later (or earlier) than UTC.
# UTC offset 0 is centred on England (also known as GMT).
# As you travel east, the offset increases until you
# reach the dateline in the middle of the Pacific Ocean;
# as you travel west, the offset decreases.  This offset
# is abbreviated as +of+ in the Date class.
#
# This simple representation of time zones does not take
# into account the common practice of Daylight Savings
# Time or Summer Time.
#
# Most DateTime methods return the date and the
# time in local time.  The two exceptions are
# #ajd() and #amjd(), which return the date and time
# in UTC time, including fractional days.
#
# The Date class does not support time zone offsets, in that
# there is no way to create a Date object with a time zone.
# However, methods of the Date class when used by a
# DateTime instance will use the time zone offset of this
# instance.
#
# == Examples of use
#
# === Print out the date of every Sunday between two dates.
#
#     def print_sundays(d1, d2)
#         d1 +=1 while (d1.wday != 0)
#         d1.step(d2, 7) do |date|
#             puts "#{Date::MONTHNAMES[date.mon]} #{date.day}"
#         end
#     end
#
#     print_sundays(Date::civil(2003, 4, 8), Date::civil(2003, 5, 23))
#
# === Calculate how many seconds to go till midnight on New Year's Day.
#
#     def secs_to_new_year(now = DateTime::now())
#         new_year = DateTime.new(now.year + 1, 1, 1)
#         dif = new_year - now
#         hours, mins, secs, ignore_fractions = Date::day_fraction_to_time(dif)
#         return hours * 60 * 60 + mins * 60 + secs
#     end
#
#     puts secs_to_new_year()

require 'date/format'

# Class representing a date.
#
# See the documentation to the file date.rb for an overview.
#
# Internally, the date is represented as an Astronomical
# Julian Day Number, +ajd+.  The Day of Calendar Reform, +sg+, is
# also stored, for conversions to other date formats.  (There
# is also an +of+ field for a time zone offset, but this
# is only for the use of the DateTime subclass.)
#
# A new Date object is created using one of the object creation
# class methods named after the corresponding date format, and the
# arguments appropriate to that date format; for instance,
# Date::civil() (aliased to Date::new()) with year, month,
# and day-of-month, or Date::ordinal() with year and day-of-year.
# All of these object creation class methods also take the
# Day of Calendar Reform as an optional argument.
#
# Date objects are immutable once created.
#
# Once a Date has been created, date values
# can be retrieved for the different date formats supported
# using instance methods.  For instance, #mon() gives the
# Civil month, #cwday() gives the Commercial day of the week,
# and #yday() gives the Ordinal day of the year.  Date values
# can be retrieved in any format, regardless of what format
# was used to create the Date instance.
#
# The Date class includes the Comparable module, allowing
# date objects to be compared and sorted, ranges of dates
# to be created, and so forth.
class Date

  include Comparable

  # Full month names, in English.  Months count from 1 to 12; a
  # month's numerical representation indexed into this array
  # gives the name of that month (hence the first element is nil).
  MONTHNAMES = [nil] + %w(January February March April May June July
                          August September October November December)

  # Full names of days of the week, in English.  Days of the week
  # count from 0 to 6 (except in the commercial week); a day's numerical
  # representation indexed into this array gives the name of that day.
  DAYNAMES = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

  # Abbreviated month names, in English.
  ABBR_MONTHNAMES = [nil] + %w(Jan Feb Mar Apr May Jun
                               Jul Aug Sep Oct Nov Dec)

  # Abbreviated day names, in English.
  ABBR_DAYNAMES = %w(Sun Mon Tue Wed Thu Fri Sat)

  [MONTHNAMES, DAYNAMES, ABBR_MONTHNAMES, ABBR_DAYNAMES].each do |xs|
    xs.each{|x| x.freeze unless x.nil?}.freeze
  end

  JODA = org.joda.time

  class Infinity < Numeric # :nodoc:

    include Comparable

    def initialize(d=1) @d = d <=> 0 end

    def d() @d end

    protected :d

    def zero? () false end
    def finite? () false end
    def infinite? () d.nonzero? end
    def nan? () d.zero? end

    def abs() self.class.new end

    def -@ () self.class.new(-d) end
    def +@ () self.class.new(+d) end

    def <=> (other)
      case other
      when Infinity
        d <=> other.d
      when Numeric
        d
      else
        begin
          l, r = other.coerce(self)
          l <=> r
        rescue NoMethodError
          nil
        end
      end
    end

    def coerce(other)
      case other
      when Numeric
        [-d, d]
      else
        super
      end
    end

    def to_s
      @d == 1 ? "Inf" : "-Inf"
    end
  end

  # The Julian Day Number of the Day of Calendar Reform for Italy
  # and the Catholic countries.
  ITALY     = 2299161 # 1582-10-15

  # The Julian Day Number of the Day of Calendar Reform for England
  # and her Colonies.
  ENGLAND   = 2361222 # 1752-09-14

  # A constant used to indicate that a Date should always use the
  # Julian calendar.
  JULIAN    =  Infinity.new

  # A constant used to indicate that a Date should always use the
  # Gregorian calendar.
  GREGORIAN = -Infinity.new

  HALF_DAYS_IN_DAY       = Rational(1, 2) # :nodoc:
  HOURS_IN_DAY           = Rational(1, 24) # :nodoc:
  SECONDS_IN_DAY         = Rational(1, 86400) # :nodoc:

  MJD_EPOCH_IN_AJD       = Rational(4800001, 2) # 1858-11-17 # :nodoc:
  UNIX_EPOCH_IN_AJD      = Rational(4881175, 2) # 1970-01-01 # :nodoc:
  MJD_EPOCH_IN_CJD       = 2400001 # :nodoc:
  UNIX_EPOCH_IN_CJD      = 2440588 # :nodoc:
  LD_EPOCH_IN_CJD        = 2299160 # :nodoc:

  t = Module.new do

    private

    def find_fdoy(y, sg) # :nodoc:
      j = nil
      1.upto(31) do |d|
        break if j = _valid_civil?(y, 1, d, sg)
      end
      j
    end

    def find_ldoy(y, sg) # :nodoc:
      j = nil
      31.downto(1) do |d|
        break if j = _valid_civil?(y, 12, d, sg)
      end
      j
    end

    def find_fdom(y, m, sg) # :nodoc:
      j = nil
      1.upto(31) do |d|
        break if j = _valid_civil?(y, m, d, sg)
      end
      j
    end

    def find_ldom(y, m, sg) # :nodoc:
      j = nil
      31.downto(1) do |d|
        break if j = _valid_civil?(y, m, d, sg)
      end
      j
    end

    # Convert an Ordinal Date to a Julian Day Number.
    #
    # +y+ and +d+ are the year and day-of-year to convert.
    # +sg+ specifies the Day of Calendar Reform.
    #
    # Returns the corresponding Julian Day Number.
    def ordinal_to_jd(y, d, sg=GREGORIAN) # :nodoc:
      find_fdoy(y, sg) + d - 1
    end

    # Convert a Julian Day Number to an Ordinal Date.
    #
    # +jd+ is the Julian Day Number to convert.
    # +sg+ specifies the Day of Calendar Reform.
    #
    # Returns the corresponding Ordinal Date as
    # [year, day_of_year]
    def jd_to_ordinal(jd, sg=GREGORIAN) # :nodoc:
      y = jd_to_civil(jd, sg)[0]
      j = find_fdoy(y, sg)
      doy = jd - j + 1
      return y, doy
    end

    # Convert a Civil Date to a Julian Day Number.
    # +y+, +m+, and +d+ are the year, month, and day of the
    # month.  +sg+ specifies the Day of Calendar Reform.
    #
    # Returns the corresponding Julian Day Number.
    def civil_to_jd(y, m, d, sg=GREGORIAN) # :nodoc:
      if m <= 2
        y -= 1
        m += 12
      end
      a = (y / 100.0).floor
      b = 2 - a + (a / 4.0).floor
      jd = (365.25 * (y + 4716)).floor +
        (30.6001 * (m + 1)).floor +
        d + b - 1524
      if jd < sg
        jd -= b
      end
      jd
    end

    # Convert a Julian Day Number to a Civil Date.  +jd+ is
    # the Julian Day Number. +sg+ specifies the Day of
    # Calendar Reform.
    #
    # Returns the corresponding [year, month, day_of_month]
    # as a three-element array.
    def jd_to_civil(jd, sg=GREGORIAN) # :nodoc:
      if jd < sg
        a = jd
      else
        x = ((jd - 1867216.25) / 36524.25).floor
        a = jd + 1 + x - (x / 4.0).floor
      end
      b = a + 1524
      c = ((b - 122.1) / 365.25).floor
      d = (365.25 * c).floor
      e = ((b - d) / 30.6001).floor
      dom = b - d - (30.6001 * e).floor
      if e <= 13
        m = e - 1
        y = c - 4716
      else
        m = e - 13
        y = c - 4715
      end
      return y, m, dom
    end

    # Convert a Commercial Date to a Julian Day Number.
    #
    # +y+, +w+, and +d+ are the (commercial) year, week of the year,
    # and day of the week of the Commercial Date to convert.
    # +sg+ specifies the Day of Calendar Reform.
    def commercial_to_jd(y, w, d, sg=GREGORIAN) # :nodoc:
      j = find_fdoy(y, sg) + 3
      (j - (((j - 1) + 1) % 7)) +
        7 * (w - 1) +
        (d - 1)
    end

    # Convert a Julian Day Number to a Commercial Date
    #
    # +jd+ is the Julian Day Number to convert.
    # +sg+ specifies the Day of Calendar Reform.
    #
    # Returns the corresponding Commercial Date as
    # [commercial_year, week_of_year, day_of_week]
    def jd_to_commercial(jd, sg=GREGORIAN) # :nodoc:
      a = jd_to_civil(jd - 3, sg)[0]
      y = if jd >= commercial_to_jd(a + 1, 1, 1, sg) then a + 1 else a end
      w = 1 + ((jd - commercial_to_jd(y, 1, 1, sg)) / 7).floor
      d = (jd + 1) % 7
      d = 7 if d == 0
      return y, w, d
    end

    def weeknum_to_jd(y, w, d, f=0, sg=GREGORIAN) # :nodoc:
      a = find_fdoy(y, sg) + 6
      (a - ((a - f) + 1) % 7 - 7) + 7 * w + d
    end

    def jd_to_weeknum(jd, f=0, sg=GREGORIAN) # :nodoc:
      y, m, d = jd_to_civil(jd, sg)
      a = find_fdoy(y, sg) + 6
      w, d = (jd - (a - ((a - f) + 1) % 7) + 7).divmod(7)
      return y, w, d
    end

    def nth_kday_to_jd(y, m, n, k, sg=GREGORIAN) # :nodoc:
      j = if n > 0
            find_fdom(y, m, sg) - 1
          else
            find_ldom(y, m, sg) + 7
          end
      (j - (((j - k) + 1) % 7)) + 7 * n
    end

    def jd_to_nth_kday(jd, sg=GREGORIAN) # :nodoc:
      y, m, d = jd_to_civil(jd, sg)
      j = find_fdom(y, m, sg)
      return y, m, ((jd - j) / 7).floor + 1, jd_to_wday(jd)
    end

    # Convert an Astronomical Julian Day Number to a (civil) Julian
    # Day Number.
    #
    # +ajd+ is the Astronomical Julian Day Number to convert.
    # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
    #
    # Returns the (civil) Julian Day Number as [day_number,
    # fraction] where +fraction+ is always 1/2.
    def ajd_to_jd(ajd, of=0) (ajd + of + HALF_DAYS_IN_DAY).divmod(1) end # :nodoc:

    # Convert a (civil) Julian Day Number to an Astronomical Julian
    # Day Number.
    #
    # +jd+ is the Julian Day Number to convert, and +fr+ is a
    # fractional day.
    # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
    #
    # Returns the Astronomical Julian Day Number as a single
    # numeric value.
    def jd_to_ajd(jd, fr, of=0) jd + fr - of - HALF_DAYS_IN_DAY end # :nodoc:

    # Convert a fractional day +fr+ to [hours, minutes, seconds,
    # fraction_of_a_second]
    def day_fraction_to_time(fr) # :nodoc:
      ss,  fr = fr.divmod(SECONDS_IN_DAY) # 4p
      h,   ss = ss.divmod(3600)
      min, s  = ss.divmod(60)
      return h, min, s, fr * 86400
    end

    # Convert an +h+ hour, +min+ minutes, +s+ seconds period
    # to a fractional day.
    def time_to_day_fraction(h, min, s)
      Rational(h * 3600 + min * 60 + s, 86400) # 4p
    end

    # Convert an Astronomical Modified Julian Day Number to an
    # Astronomical Julian Day Number.
    def amjd_to_ajd(amjd) amjd + MJD_EPOCH_IN_AJD end # :nodoc:

    # Convert an Astronomical Julian Day Number to an
    # Astronomical Modified Julian Day Number.
    def ajd_to_amjd(ajd) ajd - MJD_EPOCH_IN_AJD end # :nodoc:

    # Convert a Modified Julian Day Number to a Julian
    # Day Number.
    def mjd_to_jd(mjd) mjd + MJD_EPOCH_IN_CJD end # :nodoc:

    # Convert a Julian Day Number to a Modified Julian Day
    # Number.
    def jd_to_mjd(jd) jd - MJD_EPOCH_IN_CJD end # :nodoc:

    # Convert a count of the number of days since the adoption
    # of the Gregorian Calendar (in Italy) to a Julian Day Number.
    def ld_to_jd(ld) ld +  LD_EPOCH_IN_CJD end # :nodoc:

    # Convert a Julian Day Number to the number of days since
    # the adoption of the Gregorian Calendar (in Italy).
    def jd_to_ld(jd) jd -  LD_EPOCH_IN_CJD end # :nodoc:

    # Convert a Julian Day Number to the day of the week.
    #
    # Sunday is day-of-week 0; Saturday is day-of-week 6.
    def jd_to_wday(jd) (jd + 1) % 7 end # :nodoc:

    # Is +jd+ a valid Julian Day Number?
    #
    # If it is, returns it.  In fact, any value is treated as a valid
    # Julian Day Number.
    def _valid_jd? (jd, sg=GREGORIAN) jd end # :nodoc:

    # Do the year +y+ and day-of-year +d+ make a valid Ordinal Date?
    # Returns the corresponding Julian Day Number if they do, or
    # nil if they don't.
    #
    # +d+ can be a negative number, in which case it counts backwards
    # from the end of the year (-1 being the last day of the year).
    # No year wraparound is performed, however, so valid values of
    # +d+ are -365 .. -1, 1 .. 365 on a non-leap-year,
    # -366 .. -1, 1 .. 366 on a leap year.
    # A date falling in the period skipped in the Day of Calendar Reform
    # adjustment is not valid.
    #
    # +sg+ specifies the Day of Calendar Reform.
    def _valid_ordinal? (y, d, sg=GREGORIAN) # :nodoc:
      if d < 0
        return unless j = find_ldoy(y, sg)
        ny, nd = jd_to_ordinal(j + d + 1, sg)
        return unless ny == y
        d = nd
      end
      jd = ordinal_to_jd(y, d, sg)
      return unless [y, d] == jd_to_ordinal(jd, sg)
      jd
    end

    # Do year +y+, month +m+, and day-of-month +d+ make a
    # valid Civil Date?  Returns the corresponding Julian
    # Day Number if they do, nil if they don't.
    #
    # +m+ and +d+ can be negative, in which case they count
    # backwards from the end of the year and the end of the
    # month respectively.  No wraparound is performed, however,
    # and invalid values cause an ArgumentError to be raised.
    # A date falling in the period skipped in the Day of Calendar
    # Reform adjustment is not valid.
    #
    # +sg+ specifies the Day of Calendar Reform.
    def _valid_civil? (y, m, d, sg=GREGORIAN) # :nodoc:
      if m < 0
        m += 13
      end
      if d < 0
        return unless j = find_ldom(y, m, sg)
        ny, nm, nd = jd_to_civil(j + d + 1, sg)
        return unless [ny, nm] == [y, m]
        d = nd
      end
      jd = civil_to_jd(y, m, d, sg)
      return unless [y, m, d] == jd_to_civil(jd, sg)
      jd
    end

    # Do year +y+, week-of-year +w+, and day-of-week +d+ make a
    # valid Commercial Date?  Returns the corresponding Julian
    # Day Number if they do, nil if they don't.
    #
    # Monday is day-of-week 1; Sunday is day-of-week 7.
    #
    # +w+ and +d+ can be negative, in which case they count
    # backwards from the end of the year and the end of the
    # week respectively.  No wraparound is performed, however,
    # and invalid values cause an ArgumentError to be raised.
    # A date falling in the period skipped in the Day of Calendar
    # Reform adjustment is not valid.
    #
    # +sg+ specifies the Day of Calendar Reform.
    def _valid_commercial? (y, w, d, sg=GREGORIAN) # :nodoc:
      if d < 0
        d += 8
      end
      if w < 0
        ny, nw, nd =
          jd_to_commercial(commercial_to_jd(y + 1, 1, 1, sg) + w * 7, sg)
        return unless ny == y
        w = nw
      end
      jd = commercial_to_jd(y, w, d, sg)
      return unless [y, w, d] == jd_to_commercial(jd, sg)
      jd
    end

    def _valid_weeknum? (y, w, d, f, sg=GREGORIAN) # :nodoc:
      if d < 0
        d += 7
      end
      if w < 0
        ny, nw, nd, nf =
          jd_to_weeknum(weeknum_to_jd(y + 1, 1, f, f, sg) + w * 7, f, sg)
        return unless ny == y
        w = nw
      end
      jd = weeknum_to_jd(y, w, d, f, sg)
      return unless [y, w, d] == jd_to_weeknum(jd, f, sg)
      jd
    end

    def _valid_nth_kday? (y, m, n, k, sg=GREGORIAN) # :nodoc:
      if k < 0
        k += 7
      end
      if n < 0
        ny, nm = (y * 12 + m).divmod(12)
        nm,    = (nm + 1)    .divmod(1)
        ny, nm, nn, nk =
          jd_to_nth_kday(nth_kday_to_jd(ny, nm, 1, k, sg) + n * 7, sg)
        return unless [ny, nm] == [y, m]
        n = nn
      end
      jd = nth_kday_to_jd(y, m, n, k, sg)
      return unless [y, m, n, k] == jd_to_nth_kday(jd, sg)
      jd
    end

    # Do hour +h+, minute +min+, and second +s+ constitute a valid time?
    #
    # If they do, returns their value as a fraction of a day.  If not,
    # returns nil.
    #
    # The 24-hour clock is used.  Negative values of +h+, +min+, and
    # +sec+ are treating as counting backwards from the end of the
    # next larger unit (e.g. a +min+ of -2 is treated as 58).  No
    # wraparound is performed.
    def _valid_time? (h, min, s) # :nodoc:
      h   += 24 if h   < 0
      min += 60 if min < 0
      s   += 60 if s   < 0
      return unless ((0...24) === h &&
                     (0...60) === min &&
                     (0...60) === s) ||
                     (24 == h &&
                       0 == min &&
                       0 == s)
      time_to_day_fraction(h, min, s)
    end

    def chronology(sg, of=0)
      tz = if JODA::DateTimeZone === of
        of
      elsif of == 0
        return CHRONO_ITALY_UTC if sg == ITALY
        JODA::DateTimeZone::UTC
      else
        raise ArgumentError, "Invalid offset: #{of}" if of <= -1 or of >= 1
        JODA::DateTimeZone.forOffsetMillis((of * 86_400_000).round)
      end

      chrono = if sg == ITALY
        JODA.chrono::GJChronology
      elsif sg == JULIAN
        JODA.chrono::JulianChronology
      elsif sg == GREGORIAN
        JODA.chrono::GregorianChronology
      end

      if chrono
        chrono.getInstance(tz)
      else
        constructor = JODA::Instant.java_class.constructor(Java::long)
        cutover = constructor.new_instance JODA::DateTimeUtils.fromJulianDay(jd_to_ajd(sg, 0))
        JODA.chrono::GJChronology.getInstance(tz, cutover)
      end
    end
  end

  extend  t
  include t

  DEFAULT_TZ = Time.now.strftime('%z')
  DEFAULT_DTZ = Time.now.strftime('%z')
  CHRONO_ITALY_DEFAULT_DTZ = chronology(ITALY, DEFAULT_DTZ)
  CHRONO_ITALY_UTC = JODA.chrono::GJChronology.getInstance(JODA::DateTimeZone::UTC)

  # Is a year a leap year in the Julian calendar?
  #
  # All years divisible by 4 are leap years in the Julian calendar.
  def self.julian_leap? (y) y % 4 == 0 end

  # Is a year a leap year in the Gregorian calendar?
  #
  # All years divisible by 4 are leap years in the Gregorian calendar,
  # except for years divisible by 100 and not by 400.
  def self.gregorian_leap? (y) y % 4 == 0 && y % 100 != 0 || y % 400 == 0 end
  class << self; alias_method :leap?, :gregorian_leap? end

  class << self; alias_method :new!, :new end

  def self.valid_jd? (jd, sg=ITALY)
    !!_valid_jd?(jd, sg)
  end

  def self.valid_ordinal? (y, d, sg=ITALY)
    !!_valid_ordinal?(y, d, sg)
  end

  def self.valid_civil? (y, m, d, sg=ITALY)
    !!_valid_civil?(y, m, d, sg)
  end
  class << self; alias_method :valid_date?, :valid_civil? end

  def self.valid_commercial? (y, w, d, sg=ITALY)
    !!_valid_commercial?(y, w, d, sg)
  end

  def self.valid_weeknum? (y, w, d, f, sg=ITALY) # :nodoc:
    !!_valid_weeknum?(y, w, d, f, sg)
  end
  private_class_method :valid_weeknum?

  def self.valid_nth_kday? (y, m, n, k, sg=ITALY) # :nodoc:
    !!_valid_nth_kday?(y, m, n, k, sg)
  end
  private_class_method :valid_nth_kday?

  def self.valid_time? (h, min, s) # :nodoc:
    !!_valid_time?(h, min, s)
  end
  private_class_method :valid_time?

  # Create a new Date object from a Julian Day Number.
  #
  # +jd+ is the Julian Day Number; if not specified, it defaults to
  # 0.
  # +sg+ specifies the Day of Calendar Reform.
  def self.jd(jd=0, sg=ITALY)
    jd = _valid_jd?(jd, sg)
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end

  # Create a new Date object from an Ordinal Date, specified
  # by year +y+ and day-of-year +d+. +d+ can be negative,
  # in which it counts backwards from the end of the year.
  # No year wraparound is performed, however.  An invalid
  # value for +d+ results in an ArgumentError being raised.
  #
  # +y+ defaults to -4712, and +d+ to 1; this is Julian Day
  # Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.ordinal(y=-4712, d=1, sg=ITALY)
    unless jd = _valid_ordinal?(y, d, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end

  # Create a new Date object for the Civil Date specified by
  # year +y+, month +m+, and day-of-month +d+.
  #
  # +m+ and +d+ can be negative, in which case they count
  # backwards from the end of the year and the end of the
  # month respectively.  No wraparound is performed, however,
  # and invalid values cause an ArgumentError to be raised.
  # can be negative
  #
  # +y+ defaults to -4712, +m+ to 1, and +d+ to 1; this is
  # Julian Day Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.civil(y=-4712, m=1, d=1, sg=ITALY)
    if Fixnum === y and Fixnum === m and Fixnum === d and d > 0
      m += 13 if m < 0
      y -= 1 if y <= 0 and sg > 0 # TODO
      begin
        dt = JODA::DateTime.new(y, m, d, 0, 0, 0, chronology(sg))
      rescue JODA::IllegalFieldValueException, Java::JavaLang::IllegalArgumentException
        raise ArgumentError, 'invalid date'
      end
      new!(dt, 0, sg)
    else
      unless jd = _valid_civil?(y, m, d, sg)
        raise ArgumentError, 'invalid date'
      end
      new!(jd_to_ajd(jd, 0, 0), 0, sg)
    end
  end
  class << self; alias_method :new, :civil end

  # Create a new Date object for the Commercial Date specified by
  # year +y+, week-of-year +w+, and day-of-week +d+.
  #
  # Monday is day-of-week 1; Sunday is day-of-week 7.
  #
  # +w+ and +d+ can be negative, in which case they count
  # backwards from the end of the year and the end of the
  # week respectively.  No wraparound is performed, however,
  # and invalid values cause an ArgumentError to be raised.
  #
  # +y+ defaults to -4712, +w+ to 1, and +d+ to 1; this is
  # Julian Day Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.commercial(y=-4712, w=1, d=1, sg=ITALY)
    unless jd = _valid_commercial?(y, w, d, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end

  def self.weeknum(y=-4712, w=0, d=1, f=0, sg=ITALY)
    unless jd = _valid_weeknum?(y, w, d, f, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end
  private_class_method :weeknum

  def self.nth_kday(y=-4712, m=1, n=1, k=1, sg=ITALY)
    unless jd = _valid_nth_kday?(y, m, n, k, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end
  private_class_method :nth_kday

  def self.rewrite_frags(elem) # :nodoc:
    elem ||= {}
    if seconds = elem[:seconds]
      d,   fr = seconds.divmod(86400)
      h,   fr = fr.divmod(3600)
      min, fr = fr.divmod(60)
      s,   fr = fr.divmod(1)
      offset = elem[:offset]
      unless offset.nil?
        seconds += offset
      end
      elem[:jd] = UNIX_EPOCH_IN_CJD + d
      elem[:hour] = h
      elem[:min] = min
      elem[:sec] = s
      elem[:sec_fraction] = fr
      elem.delete(:seconds)
    end
    elem
  end
  private_class_method :rewrite_frags

  COMPLETE_FRAGS = [
    [:time,       []],
    [nil,         [:jd]],
    [:ordinal,    [:year, :yday]],
    [:civil,      [:year, :mon, :mday]],
    [:commercial, [:cwyear, :cweek, :cwday]],
    [:wday,       [:wday, :__need_jd_filling]],
    [:wnum0,      [:year, :wnum0, :wday]],
    [:wnum1,      [:year, :wnum1, :wday]],
    [nil,         [:cwyear, :cweek, :wday]],
    [nil,         [:year, :wnum0, :cwday]],
    [nil,         [:year, :wnum1, :cwday]]
  ]

  def self.complete_frags(elem) # :nodoc:
    g = COMPLETE_FRAGS.max_by { |kind, fields|
      fields.count { |field| elem.key? field }
    }
    c = g[1].count { |field| elem.key? field }

    if c == 0 and [:hour, :min, :sec].none? { |field| elem.key? field }
      g = nil
    end

    if g && g[0] && g[1].size != c
      d ||= Date.today

      case g[0]
      when :ordinal
        elem[:year] ||= d.year
        elem[:yday] ||= 1
      when :civil
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:mon]  ||= 1
        elem[:mday] ||= 1
      when :commercial
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:cweek] ||= 1
        elem[:cwday] ||= 1
      when :wday
        elem[:jd] ||= (d - d.wday + elem[:wday]).jd
      when :wnum0
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:wnum0] ||= 0
        elem[:wday]  ||= 0
      when :wnum1
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:wnum1] ||= 0
        elem[:wday]  ||= 1
      end
    end

    if self <= DateTime
      if g && g[0] == :time
        d ||= Date.today
        elem[:jd] ||= d.jd
      end

      elem[:hour] ||= 0
      elem[:min]  ||= 0
      elem[:sec]  ||= 0
      # see [ruby-core:47226] and the "fix"
      elem[:sec] = 59 if elem[:sec] == 60
    end

    elem
  end
  private_class_method :complete_frags

  def self.valid_date_frags?(elem, sg) # :nodoc:
    if jd = elem[:jd] and
        jd = _valid_jd?(jd, sg)
      return jd
    end

    year = elem[:year]

    if year and yday = elem[:yday] and
        jd = _valid_ordinal?(year, yday, sg)
      return jd
    end

    if year and mon = elem[:mon] and mday = elem[:mday] and
        jd = _valid_civil?(year, mon, mday, sg)
      return jd
    end

    if cwyear = elem[:cwyear] and cweek = elem[:cweek] and cwday = (elem[:cwday] || elem[:wday].nonzero? || 7) and
        jd = _valid_commercial?(cwyear, cweek, cwday, sg)
      return jd
    end

    if year and wnum0 = elem[:wnum0] and wday = (elem[:wday] || (elem[:cwday] && elem[:cwday] % 7)) and
        jd = _valid_weeknum?(year, wnum0, wday, 0, sg)
      return jd
    end

    if year and wnum1 = elem[:wnum1] and wday = (
        (elem[:wday]  && (elem[:wday]  - 1) % 7) ||
        (elem[:cwday] && (elem[:cwday] - 1) % 7)
      ) and jd = _valid_weeknum?(year, wnum1, wday, 1, sg)
      return jd
    end
  end
  private_class_method :valid_date_frags?

  def self.valid_time_frags? (elem) # :nodoc:
    h, min, s = elem.values_at(:hour, :min, :sec)
    _valid_time?(h, min, s)
  end
  private_class_method :valid_time_frags?

  def self.new_by_frags(elem, sg) # :nodoc:
    # fast path
    if elem and !elem.key?(:jd) and !elem.key?(:yday) and
        year = elem[:year] and mon = elem[:mon] and mday = elem[:mday]
      return Date.civil(year, mon, mday, sg)
    end

    elem = rewrite_frags(elem)
    elem = complete_frags(elem)
    unless jd = valid_date_frags?(elem, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end
  private_class_method :new_by_frags

  # Create a new Date object by parsing from a String
  # according to a specified format.
  #
  # +str+ is a String holding a date representation.
  # +fmt+ is the format that the date is in.  See
  # date/format.rb for details on supported formats.
  #
  # The default +str+ is '-4712-01-01', and the default
  # +fmt+ is '%F', which means Year-Month-Day_of_Month.
  # This gives Julian Day Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  #
  # An ArgumentError will be raised if +str+ cannot be
  # parsed.
  def self.strptime(str='-4712-01-01', fmt='%F', sg=ITALY)
    elem = _strptime(str, fmt)
    new_by_frags(elem, sg)
  end

  # Create a new Date object by parsing from a String,
  # without specifying the format.
  #
  # +str+ is a String holding a date representation.
  # +comp+ specifies whether to interpret 2-digit years
  # as 19XX (>= 69) or 20XX (< 69); the default is not to.
  # The method will attempt to parse a date from the String
  # using various heuristics; see #_parse in date/format.rb
  # for more details.  If parsing fails, an ArgumentError
  # will be raised.
  #
  # The default +str+ is '-4712-01-01'; this is Julian
  # Day Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.parse(str='-4712-01-01', comp=true, sg=ITALY)
    elem = _parse(str, comp)
    new_by_frags(elem, sg)
  end

  def self.iso8601(str='-4712-01-01', sg=ITALY) # :nodoc:
    elem = _iso8601(str)
    new_by_frags(elem, sg)
  end

  def self.rfc3339(str='-4712-01-01T00:00:00+00:00', sg=ITALY) # :nodoc:
    elem = _rfc3339(str)
    new_by_frags(elem, sg)
  end

  def self.xmlschema(str='-4712-01-01', sg=ITALY) # :nodoc:
    elem = _xmlschema(str)
    new_by_frags(elem, sg)
  end

  def self.rfc2822(str='Mon, 1 Jan -4712 00:00:00 +0000', sg=ITALY) # :nodoc:
    elem = _rfc2822(str)
    new_by_frags(elem, sg)
  end
  class << self; alias_method :rfc822, :rfc2822 end

  def self.httpdate(str='Mon, 01 Jan -4712 00:00:00 GMT', sg=ITALY) # :nodoc:
    elem = _httpdate(str)
    new_by_frags(elem, sg)
  end

  def self.jisx0301(str='-4712-01-01', sg=ITALY) # :nodoc:
    elem = _jisx0301(str)
    new_by_frags(elem, sg)
  end

  # *NOTE* this is the documentation for the method new!().  If
  # you are reading this as the documentation for new(), that is
  # because rdoc doesn't fully support the aliasing of the
  # initialize() method.
  # new() is in
  # fact an alias for #civil(): read the documentation for that
  # method instead.
  #
  # Create a new Date object.
  #
  # +ajd+ is the Astronomical Julian Day Number.
  # +of+ is the offset from UTC as a fraction of a day.
  # Both default to 0.
  #
  # +sg+ specifies the Day of Calendar Reform to use for this
  # Date object.
  #
  # Using one of the factory methods such as Date::civil is
  # generally easier and safer.
  def initialize(dt_or_ajd=0, of=0, sg=ITALY, sub_millis=0)
    if Time === dt_or_ajd
      @dt = dt_or_ajd
      @sub_millis = sub_millis
      of ||= Rational(@dt.getChronology.getZone.getOffset(@dt), 86_400_000)
    else
      # cannot use JODA::DateTimeUtils.fromJulianDay since we need to keep ajd as a Rational for precision
      millis, @sub_millis = ((dt_or_ajd - UNIX_EPOCH_IN_AJD) * 86400000).divmod(1)
      raise ArgumentError, "Date out of range: millis=#{millis} (#{millis.class})" unless Fixnum === millis
      @dt = JODA::DateTime.new(millis, chronology(sg, of))
    end

    @of = of # offset
    @sg = sg # start
  end

  attr_reader :dt, :sub_millis
  protected   :dt, :sub_millis

  # Get the date as an Astronomical Julian Day Number.
  def ajd
    # Rational(@dt.getMillis + @sub_millis, 86400000) + 2440587.5
    Rational(210866760000000 + @dt.getMillis + @sub_millis, 86400000)
  end

  # Get the date as an Astronomical Modified Julian Day Number.
  def amjd
    ajd_to_amjd(ajd)
  end

  # Get the date as a Julian Day Number.
  def jd
    (JODA::DateTimeUtils.toJulianDay(@dt.getMillis) + @of.to_f + 0.5).floor
  end

  # Get any fractional day part of the date.
  def day_fraction
    ms = ((hour * 60 + min) * 60 + sec) * 1000 + @dt.getMillisOfSecond + @sub_millis
    Rational(ms, 86_400_000)
  end

  # Get the date as a Modified Julian Day Number.
  def mjd() jd_to_mjd(jd) end

  # Get the date as the number of days since the Day of Calendar
  # Reform (in Italy and the Catholic countries).
  def ld() jd_to_ld(jd) end

  def joda_year_to_date_year(year)
    if year < 0 and julian?
      # Joda-time returns -x for year x BC in JulianChronology (so there is no year 0),
      # while date.rb returns -x+1, following astronomical year numbering (with year 0)
      year + 1
    else
      year
    end
  end
  private :joda_year_to_date_year

  # Get the year of this date.
  def year
    joda_year_to_date_year(@dt.getYear)
  end

  # Get the day-of-the-year of this date.
  #
  # January 1 is day-of-the-year 1
  def yday
    @dt.getDayOfYear
  end

  # Get the month of this date.
  #
  # January is month 1.
  def mon
    @dt.getMonthOfYear
  end
  alias_method :month, :mon

  # Get the day-of-the-month of this date.
  def mday
    @dt.getDayOfMonth
  end
  alias_method :day, :mday

  # Get the hour of this date.
  def hour
    @dt.getHourOfDay
  end

  # Get the minute of this date.
  def min
    @dt.getMinuteOfHour
  end
  alias_method :minute, :min

  # Get the second of this date.
  def sec
    @dt.getSecondOfMinute
  end
  alias_method :second, :sec

  # Get the fraction-of-a-second of this date.
  def sec_fraction
    Rational(@dt.getMillisOfSecond + @sub_millis, 1000)
  end
  alias_method :second_fraction, :sec_fraction

  private :hour, :min, :sec, :sec_fraction,
          :minute, :second, :second_fraction

  def zone() strftime('%:z') end
  private :zone

  # Get the commercial year of this date.  See *Commercial* *Date*
  # in the introduction for how this differs from the normal year.
  def cwyear
    joda_year_to_date_year(@dt.getWeekyear)
  end

  # Get the commercial week of the year of this date.
  def cweek
    @dt.getWeekOfWeekyear
  end

  # Get the commercial day of the week of this date.  Monday is
  # commercial day-of-week 1; Sunday is commercial day-of-week 7.
  def cwday
    @dt.getDayOfWeek
  end

  # Get the week day of this date.  Sunday is day-of-week 0;
  # Saturday is day-of-week 6.
  def wday
    @dt.getDayOfWeek % 7
  end

  DAYNAMES.each_with_index do |n, i|
    define_method(n.downcase + '?'){wday == i}
  end

  def nth_kday? (n, k)
    k == wday && jd === nth_kday_to_jd(year, mon, n, k, start)
  end
  private :nth_kday?

  # Is the current date old-style (Julian Calendar)?
  def julian?
    jd < @sg
  end

  # Is the current date new-style (Gregorian Calendar)?
  def gregorian? () !julian? end

  def fix_style # :nodoc:
    if julian?
    then self.class::JULIAN
    else self.class::GREGORIAN end
  end
  private :fix_style

  # Is this a leap year?
  def leap?
    julian? ? Date.julian_leap?(year) : Date.gregorian_leap?(year)
  end

  # When is the Day of Calendar Reform for this Date object?
  def start
    case @dt.getChronology
    when JODA.chrono::JulianChronology
      JULIAN
    when JODA.chrono::GregorianChronology
      GREGORIAN
    else
      JODA::DateTimeUtils.toJulianDayNumber @dt.getChronology.getGregorianCutover.getMillis
    end
  end

  # Create a copy of this Date object using a new Day of Calendar Reform.
  def new_start(sg=self.class::ITALY)
    self.class.new!(@dt.withChronology(chronology(sg, @of)), @of, sg, @sub_millis)
  end

  # Create a copy of this Date object that uses the Italian/Catholic
  # Day of Calendar Reform.
  def italy() new_start(self.class::ITALY) end

  # Create a copy of this Date object that uses the English/Colonial
  # Day of Calendar Reform.
  def england() new_start(self.class::ENGLAND) end

  # Create a copy of this Date object that always uses the Julian
  # Calendar.
  def julian() new_start(self.class::JULIAN) end

  # Create a copy of this Date object that always uses the Gregorian
  # Calendar.
  def gregorian() new_start(self.class::GREGORIAN) end

  def offset
    Rational(@dt.getChronology.getZone.getOffset(@dt), 86_400_000)
  end

  def new_offset(of=0)
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    self.class.new!(@dt.withChronology(chronology(@sg, of)), of, @sg, @sub_millis)
  end
  private :offset, :new_offset

  # Return a new Date object that is +n+ days later than the
  # current one.
  #
  # +n+ may be a negative value, in which case the new Date
  # is earlier than the current one; however, #-() might be
  # more intuitive.
  #
  # If +n+ is not a Numeric, a TypeError will be thrown.  In
  # particular, two Dates cannot be added to each other.
  def + (n)
    case n
    when Fixnum
      self.class.new!(@dt.plusDays(n), @of, @sg, @sub_millis)
    when Numeric
      ms, sub = (n * 86_400_000).divmod(1)
      sub = 0 if sub == 0 # avoid Rational(0, 1)
      sub_millis = @sub_millis + sub
      if sub_millis >= 1
        sub_millis -= 1
        ms += 1
      end
      self.class.new!(@dt.plus(ms), @of, @sg, sub_millis)
    else
      raise TypeError, 'expected numeric'
    end
  end

  # If +x+ is a Numeric value, create a new Date object that is
  # +x+ days earlier than the current one.
  #
  # If +x+ is a Date, return the number of days between the
  # two dates; or, more precisely, how many days later the current
  # date is than +x+.
  #
  # If +x+ is neither Numeric nor a Date, a TypeError is raised.
  def - (x)
    case x
    when Numeric
      self + (-x)
    when Date
      diff = @dt.getMillis - x.dt.getMillis
      diff_sub = @sub_millis - x.sub_millis
      diff += diff_sub if diff_sub != 0
      Rational(diff, 86_400_000)
    else
      raise TypeError, 'expected numeric or date'
    end
  end

  # Compare this date with another date.
  #
  # +other+ can also be a Numeric value, in which case it is
  # interpreted as an Astronomical Julian Day Number.
  #
  # Comparison is by Astronomical Julian Day Number, including
  # fractional days.  This means that both the time and the
  # timezone offset are taken into account when comparing
  # two DateTime instances.  When comparing a DateTime instance
  # with a Date instance, the time of the latter will be
  # considered as falling on midnight UTC.
  class org::joda::time::DateTime
    java_alias :compareDT, :compareTo, [org.joda.time.ReadableInstant]
  end
  def <=> (other)
    if other.kind_of?(Date)
      # The method compareTo doesn't compare the sub milliseconds so after compare the two dates
      # then we have to compare the sub milliseconds to make sure that both are exactly equal.
      @dt.compareDT(other.dt).nonzero? || @sub_millis <=> other.sub_millis
    else
       __internal_cmp(other)
    end
  end

  private def __internal_cmp(other)
    if other.kind_of? Numeric
      ajd <=> other
    else
      begin
        l, r = other.coerce(self)
        l <=> r
      rescue NoMethodError
        nil
      end
    end
  end

  # The relationship operator for Date.
  #
  # Compares dates by Julian Day Number.  When comparing
  # two DateTime instances, or a DateTime with a Date,
  # the instances will be regarded as equivalent if they
  # fall on the same date in local time.
  def === (other)
    case other
    when Numeric
      jd == other
    when Date
      jd == other.jd
    else
      begin
        l, r = other.coerce(self)
        l === r
      rescue NoMethodError
        false
      end
    end
  end

  def next_day(n=1) self + n end
  def prev_day(n=1) self - n end

  # Return a new Date one day after this one.
  def next() next_day end
  alias_method :succ, :next

  # Return a new Date object that is +n+ months later than
  # the current one.
  #
  # If the day-of-the-month of the current Date is greater
  # than the last day of the target month, the day-of-the-month
  # of the returned Date will be the last day of the target month.
  def >> (n)
    n = n.to_int rescue raise(TypeError, "n must be a Fixnum")
    self.class.new!(@dt.plusMonths(n), @of, @sg, @sub_millis)
  end

  # Return a new Date object that is +n+ months earlier than
  # the current one.
  #
  # If the day-of-the-month of the current Date is greater
  # than the last day of the target month, the day-of-the-month
  # of the returned Date will be the last day of the target month.
  def << (n) self >> -n end

  def next_month(n=1) self >> n end
  def prev_month(n=1) self << n end

  def next_year(n=1)
    self.class.new!(@dt.plusYears(n.to_i), @of, @sg, @sub_millis)
  end

  def prev_year(n=1)
    next_year(-n)
  end

  # Step the current date forward +step+ days at a
  # time (or backward, if +step+ is negative) until
  # we reach +limit+ (inclusive), yielding the resultant
  # date at each step.
  def step(limit, step=1) # :yield: date
=begin
    if step.zero?
      raise ArgumentError, "step can't be 0"
    end
=end
    unless block_given?
      return to_enum(:step, limit, step)
    end
    da = self
    op = %w(- <= >=)[step <=> 0]
    while da.__send__(op, limit)
      yield da
      da += step
    end
    self
  end

  # Step forward one day at a time until we reach +max+
  # (inclusive), yielding each date as we go.
  def upto(max, &block) # :yield: date
    step(max, +1, &block)
  end

  # Step backward one day at a time until we reach +min+
  # (inclusive), yielding each date as we go.
  def downto(min, &block) # :yield: date
    step(min, -1, &block)
  end

  # Is this Date equal to +other+?
  #
  # +other+ must both be a Date object, and represent the same date.
  def eql? (other) Date === other && self == other end

  # Calculate a hash value for this date.
  def hash() @dt.getMillis end

  # Return internal object state as a programmer-readable string.
  def inspect
    s = (hour * 60 + min) * 60 + sec - (@of*86_400).to_i
    ns = ((@dt.getMillisOfSecond + @sub_millis) * 1_000_000)
    ns = ns.to_i if Rational === ns and ns.denominator == 1
    of = "%+d" % (@of * 86_400)
    sg = Date::Infinity === @sg ? @sg.to_s : "%.0f" % @sg
    "#<#{self.class}: #{to_s} ((#{jd}j,#{s}s,#{ns.inspect}n),#{of}s,#{sg}j)>"
  end

  # Return the date as a human-readable string.
  #
  # The format used is YYYY-MM-DD.
  def to_s() format('%.4d-%02d-%02d', year, mon, mday) end # 4p

  # Dump to Marshal format.
  def marshal_dump() [ajd, @of, @sg] end

  # Load from Marshal format.
  def marshal_load(a)
    ajd, of, sg = nil

    case a.size
    when 2 # 1.6.x
      ajd = a[0] - HALF_DAYS_IN_DAY
      of = 0
      sg = a[1]
      sg = sg ? GREGORIAN : JULIAN unless Numeric === sg
    when 3 # 1.8.x, 1.9.2
      ajd, of, sg = a
    when 6
      _, jd, df, sf, of, sg = a
      of = Rational(of, 86_400)
      ajd = jd - HALF_DAYS_IN_DAY
      ajd += Rational(df, 86_400) if df != 0
      ajd += Rational(sf, 86_400_000_000_000) if sf != 0
    else
      raise TypeError, "invalid size"
    end

    initialize(ajd, of, sg)
  end

  def self._load(str)
    ary = Marshal.load(str)
    raise TypeError, "expected an array" unless Array === ary
    obj = allocate
    obj.marshal_load(ary)
    obj
  end

end

# Class representing a date and time.
#
# See the documentation to the file date.rb for an overview.
#
# DateTime objects are immutable once created.
#
# == Other methods.
#
# The following methods are defined in Date, but declared private
# there.  They are made public in DateTime.  They are documented
# here.
#
# === hour()
#
# Get the hour-of-the-day of the time.  This is given
# using the 24-hour clock, counting from midnight.  The first
# hour after midnight is hour 0; the last hour of the day is
# hour 23.
#
# === min()
#
# Get the minute-of-the-hour of the time.
#
# === sec()
#
# Get the second-of-the-minute of the time.
#
# === sec_fraction()
#
# Get the fraction of a second of the time.  This is returned as
# a +Rational+.
#
# === zone()
#
# Get the time zone as a String.  This is representation of the
# time offset such as "+1000", not the true time-zone name.
#
# === offset()
#
# Get the time zone offset as a fraction of a day.  This is returned
# as a +Rational+.
#
# === new_offset(of=0)
#
# Create a new DateTime object, identical to the current one, except
# with a new time zone offset of +of+.  +of+ is the new offset from
# UTC as a fraction of a day.
#
class DateTime < Date

  # Create a new DateTime object corresponding to the specified
  # Julian Day Number +jd+ and hour +h+, minute +min+, second +s+.
  #
  # The 24-hour clock is used.  Negative values of +h+, +min+, and
  # +sec+ are treating as counting backwards from the end of the
  # next larger unit (e.g. a +min+ of -2 is treated as 58).  No
  # wraparound is performed.  If an invalid time portion is specified,
  # an ArgumentError is raised.
  #
  # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
  # +sg+ specifies the Day of Calendar Reform.
  #
  # All day/time values default to 0.
  def self.jd(jd=0, h=0, min=0, s=0, of=0, sg=ITALY)
    unless (jd = _valid_jd?(jd, sg)) &&
           (fr = _valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end

  # Create a new DateTime object corresponding to the specified
  # Ordinal Date and hour +h+, minute +min+, second +s+.
  #
  # The 24-hour clock is used.  Negative values of +h+, +min+, and
  # +sec+ are treating as counting backwards from the end of the
  # next larger unit (e.g. a +min+ of -2 is treated as 58).  No
  # wraparound is performed.  If an invalid time portion is specified,
  # an ArgumentError is raised.
  #
  # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
  # +sg+ specifies the Day of Calendar Reform.
  #
  # +y+ defaults to -4712, and +d+ to 1; this is Julian Day Number
  # day 0.  The time values default to 0.
  def self.ordinal(y=-4712, d=1, h=0, min=0, s=0, of=0, sg=ITALY)
    unless (jd = _valid_ordinal?(y, d, sg)) &&
           (fr = _valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end

  # Create a new DateTime object corresponding to the specified
  # Civil Date and hour +h+, minute +min+, second +s+.
  #
  # The 24-hour clock is used.  Negative values of +h+, +min+, and
  # +sec+ are treating as counting backwards from the end of the
  # next larger unit (e.g. a +min+ of -2 is treated as 58).  No
  # wraparound is performed.  If an invalid time portion is specified,
  # an ArgumentError is raised.
  #
  # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
  # +sg+ specifies the Day of Calendar Reform.
  #
  # +y+ defaults to -4712, +m+ to 1, and +d+ to 1; this is Julian Day
  # Number day 0.  The time values default to 0.
  def self.civil(y=-4712, m=1, d=1, h=0, min=0, s=0, of=0, sg=ITALY)
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end

    if Fixnum === y and Fixnum === m and Fixnum === d and
        Fixnum === h and Fixnum === min and
        (Fixnum === s or (Rational === s and 1000 % s.denominator == 0)) and
        m > 0 and d > 0 and h >= 0 and h < 24 and min >= 0 and s >= 0
      y -= 1 if y <= 0 and sg > 0 # TODO
      ms = 0
      if Rational === s
        s, ms = (s.numerator * 1000 / s.denominator).divmod(1000)
      end
      begin
        dt = JODA::DateTime.new(y, m, d, h, min, s, ms, chronology(sg, of))
      rescue JODA::IllegalFieldValueException, Java::JavaLang::IllegalArgumentException
        raise ArgumentError, 'invalid date'
      end
      new!(dt, of, sg)
    else
      unless (jd = _valid_civil?(y, m, d, sg)) &&
             (fr = _valid_time?(h, min, s))
        raise ArgumentError, 'invalid date'
      end
      new!(jd_to_ajd(jd, fr, of), of, sg)
    end
  end
  class << self; alias_method :new, :civil end

  # Create a new DateTime object corresponding to the specified
  # Commercial Date and hour +h+, minute +min+, second +s+.
  #
  # The 24-hour clock is used.  Negative values of +h+, +min+, and
  # +sec+ are treating as counting backwards from the end of the
  # next larger unit (e.g. a +min+ of -2 is treated as 58).  No
  # wraparound is performed.  If an invalid time portion is specified,
  # an ArgumentError is raised.
  #
  # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
  # +sg+ specifies the Day of Calendar Reform.
  #
  # +y+ defaults to -4712, +w+ to 1, and +d+ to 1; this is
  # Julian Day Number day 0.
  # The time values default to 0.
  def self.commercial(y=-4712, w=1, d=1, h=0, min=0, s=0, of=0, sg=ITALY)
    unless (jd = _valid_commercial?(y, w, d, sg)) &&
           (fr = _valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end

  def self.weeknum(y=-4712, w=0, d=1, f=0, h=0, min=0, s=0, of=0, sg=ITALY) # :nodoc:
    unless (jd = _valid_weeknum?(y, w, d, f, sg)) &&
           (fr = _valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end
  private_class_method :weeknum

  def self.nth_kday(y=-4712, m=1, n=1, k=1, h=0, min=0, s=0, of=0, sg=ITALY) # :nodoc:
    unless (jd = _valid_nth_kday?(y, m, n, k, sg)) &&
           (fr = _valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end
  private_class_method :nth_kday

  def self.new_by_frags(elem, sg) # :nodoc:
    elem = rewrite_frags(elem)
    elem = complete_frags(elem)
    unless (jd = valid_date_frags?(elem, sg)) &&
           (fr = valid_time_frags?(elem))
      raise ArgumentError, 'invalid date'
    end
    fr += (elem[:sec_fraction] || 0) / 86400
    of = Rational(elem[:offset] || 0, 86400)
    if of < -1 || of > 1
      of = 0
      warn "invalid offset is ignored" if $VERBOSE
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end
  private_class_method :new_by_frags

  # Create a new DateTime object by parsing from a String
  # according to a specified format.
  #
  # +str+ is a String holding a date-time representation.
  # +fmt+ is the format that the date-time is in.  See
  # date/format.rb for details on supported formats.
  #
  # The default +str+ is '-4712-01-01T00:00:00+00:00', and the default
  # +fmt+ is '%FT%T%z'.  This gives midnight on Julian Day Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  #
  # An ArgumentError will be raised if +str+ cannot be
  # parsed.
  def self.strptime(str='-4712-01-01T00:00:00+00:00', fmt='%FT%T%z', sg=ITALY)
    elem = _strptime(str, fmt)
    new_by_frags(elem, sg)
  end

  # Create a new DateTime object by parsing from a String,
  # without specifying the format.
  #
  # +str+ is a String holding a date-time representation.
  # +comp+ specifies whether to interpret 2-digit years
  # as 19XX (>= 69) or 20XX (< 69); the default is not to.
  # The method will attempt to parse a date-time from the String
  # using various heuristics; see #_parse in date/format.rb
  # for more details.  If parsing fails, an ArgumentError
  # will be raised.
  #
  # The default +str+ is '-4712-01-01T00:00:00+00:00'; this is Julian
  # Day Number day 0.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.parse(str='-4712-01-01T00:00:00+00:00', comp=true, sg=ITALY)
    elem = _parse(str, comp)
    new_by_frags(elem, sg)
  end

  def self.iso8601(str='-4712-01-01T00:00:00+00:00', sg=ITALY) # :nodoc:
    elem = _iso8601(str)
    new_by_frags(elem, sg)
  end

  def self.rfc3339(str='-4712-01-01T00:00:00+00:00', sg=ITALY) # :nodoc:
    elem = _rfc3339(str)
    new_by_frags(elem, sg)
  end

  def self.xmlschema(str='-4712-01-01T00:00:00+00:00', sg=ITALY) # :nodoc:
    elem = _xmlschema(str)
    new_by_frags(elem, sg)
  end

  def self.rfc2822(str='Mon, 1 Jan -4712 00:00:00 +0000', sg=ITALY) # :nodoc:
    elem = _rfc2822(str)
    new_by_frags(elem, sg)
  end
  class << self; alias_method :rfc822, :rfc2822 end

  def self.httpdate(str='Mon, 01 Jan -4712 00:00:00 GMT', sg=ITALY) # :nodoc:
    elem = _httpdate(str)
    new_by_frags(elem, sg)
  end

  def self.jisx0301(str='-4712-01-01T00:00:00+00:00', sg=ITALY) # :nodoc:
    elem = _jisx0301(str)
    new_by_frags(elem, sg)
  end

  public :hour, :min, :sec, :sec_fraction, :zone, :offset, :new_offset,
         :minute, :second, :second_fraction

  def to_s # 4p
    format('%.4d-%02d-%02dT%02d:%02d:%02d%s',
           year, mon, mday, hour, min, sec, zone)
  end

end

class Time

  def to_time
    getlocal
  end

  def to_date
    Date.civil(year, mon, mday, Date::GREGORIAN)
  end

  def to_datetime(sg = Date::ITALY, klass = DateTime)
    of = Rational(utc_offset, 86400)
    s = [sec, 59].min
    ms, sub_millis = nsec.divmod(1_000_000) # expects ns precision for Time
    sub_millis = Rational(sub_millis, 1_000_000) if sub_millis != 0
    dt = Date::JODA::DateTime.new(1000 * to_i + ms, Date.send(:chronology, sg, of))
    klass.new!(dt, of, sg, sub_millis)
  end

end

class Date

  def to_time
    Time.local(year, mon, mday)
  end

  def to_date
    self
  end

  def to_datetime
    DateTime.new!(@dt.withTimeAtStartOfDay, @of, @sg)
  end

  # Create a new Date object representing today.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.today(sg=ITALY)
    t = Time.now
    civil(t.year, t.mon, t.mday, sg)
  end

  # Create a new DateTime object representing the current time.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.now(sg=ITALY)
    dtz = (ENV['TZ'] == DEFAULT_TZ) ? DEFAULT_DTZ : org.jruby::RubyTime.getLocalTimeZone(JRuby.runtime)

    if dtz == DEFAULT_DTZ and sg == ITALY
      new!(JODA::DateTime.new(CHRONO_ITALY_DEFAULT_DTZ), nil, sg)
    else
      new!(JODA::DateTime.new(chronology(sg, dtz)), nil, sg)
    end
  end
  private_class_method :now

end

class DateTime < Date

  def to_time
    Time.new(year, mon, mday, hour, min, sec + sec_fraction, (@of * 86400).to_i).getlocal
  end

  def to_date
    Date.civil(year, mon, mday, @sg)
  end

  def to_datetime
    self
  end

  private_class_method :today
  public_class_method  :now

end
#