#
require 'time'
require 'date'
#
module Chronic
  class Anchor
    #
  end
  #
  module Handlers
    module_function

    # Handle month/day
    def handle_m_d(month, day, time_tokens, options)
      month.start = self.now
      span = month.this(options[:context])
      year, month = span.begin.year, span.begin.month
      day_start = Chronic.time_class.local(year, month, day)

      day_or_time(day_start, time_tokens, options)
    end

    # Handle repeater-month-name/scalar-day
    def handle_rmn_sd(tokens, options)
      month = tokens[0].get_tag(RepeaterMonthName)
      day = tokens[1].get_tag(ScalarDay).type

      return if month_overflow?(self.now.year, month.index, day)

      handle_m_d(month, day, tokens[2..tokens.size], options)
    end

    # Handle repeater-month-name/scalar-day with separator-on
    def handle_rmn_sd_on(tokens, options)
      if tokens.size > 3
        month = tokens[2].get_tag(RepeaterMonthName)
        day = tokens[3].get_tag(ScalarDay).type
        token_range = 0..1
      else
        month = tokens[1].get_tag(RepeaterMonthName)
        day = tokens[2].get_tag(ScalarDay).type
        token_range = 0..0
      end

      return if month_overflow?(self.now.year, month.index, day)

      handle_m_d(month, day, tokens[token_range], options)
    end

    # Handle repeater-month-name/ordinal-day
    def handle_rmn_od(tokens, options)
      month = tokens[0].get_tag(RepeaterMonthName)
      day = tokens[1].get_tag(OrdinalDay).type

      return if month_overflow?(self.now.year, month.index, day)

      handle_m_d(month, day, tokens[2..tokens.size], options)
    end

    # Handle ordinal this month
    def handle_od_rm(tokens, options)
      day = tokens[0].get_tag(OrdinalDay).type
      month = tokens[2].get_tag(RepeaterMonth)
      handle_m_d(month, day, tokens[3..tokens.size], options)
    end

    # Handle ordinal-day/repeater-month-name
    def handle_od_rmn(tokens, options)
      month = tokens[1].get_tag(RepeaterMonthName)
      day = tokens[0].get_tag(OrdinalDay).type

      return if month_overflow?(self.now.year, month.index, day)

      handle_m_d(month, day, tokens[2..tokens.size], options)
    end

    def handle_sy_rmn_od(tokens, options)
      year = tokens[0].get_tag(ScalarYear).type
      month = tokens[1].get_tag(RepeaterMonthName).index
      day = tokens[2].get_tag(OrdinalDay).type
      time_tokens = tokens.last(tokens.size - 3)

      return if month_overflow?(year, month, day)

      begin
        day_start = Chronic.time_class.local(year, month, day)
        day_or_time(day_start, time_tokens, options)
      rescue ArgumentError
        nil
      end
    end

    # Handle scalar-day/repeater-month-name
    def handle_sd_rmn(tokens, options)
      month = tokens[1].get_tag(RepeaterMonthName)
      day = tokens[0].get_tag(ScalarDay).type

      return if month_overflow?(self.now.year, month.index, day)

      handle_m_d(month, day, tokens[2..tokens.size], options)
    end

    # Handle repeater-month-name/ordinal-day with separator-on
    def handle_rmn_od_on(tokens, options)
      if tokens.size > 3
        month = tokens[2].get_tag(RepeaterMonthName)
        day = tokens[3].get_tag(OrdinalDay).type
        token_range = 0..1
      else
        month = tokens[1].get_tag(RepeaterMonthName)
        day = tokens[2].get_tag(OrdinalDay).type
        token_range = 0..0
      end

      return if month_overflow?(self.now.year, month.index, day)

      handle_m_d(month, day, tokens[token_range], options)
    end

    # Handle repeater-month-name/scalar-year
    def handle_rmn_sy(tokens, options)
      month = tokens[0].get_tag(RepeaterMonthName).index
      year = tokens[1].get_tag(ScalarYear).type

      if month == 12
        next_month_year = year + 1
        next_month_month = 1
      else
        next_month_year = year
        next_month_month = month + 1
      end

      begin
        end_time = Chronic.time_class.local(next_month_year, next_month_month)
        Span.new(Chronic.time_class.local(year, month), end_time)
      rescue ArgumentError
        nil
      end
    end

    # Handle generic timestamp (ruby 1.8)
    def handle_generic(tokens, options)
      t = Chronic.time_class.parse(options[:text])
      Span.new(t, t + 1)
    rescue ArgumentError => e
      raise e unless e.message =~ /out of range/
    end

    # Handle repeater-month-name/scalar-day/scalar-year
    def handle_rmn_sd_sy(tokens, options)
      month = tokens[0].get_tag(RepeaterMonthName).index
      day = tokens[1].get_tag(ScalarDay).type
      year = tokens[2].get_tag(ScalarYear).type
      time_tokens = tokens.last(tokens.size - 3)

      return if month_overflow?(year, month, day)

      begin
        day_start = Chronic.time_class.local(year, month, day)
        day_or_time(day_start, time_tokens, options)
      rescue ArgumentError
        nil
      end
    end

    # Handle repeater-month-name/ordinal-day/scalar-year
    def handle_rmn_od_sy(tokens, options)
      month = tokens[0].get_tag(RepeaterMonthName).index
      day = tokens[1].get_tag(OrdinalDay).type
      year = tokens[2].get_tag(ScalarYear).type
      time_tokens = tokens.last(tokens.size - 3)

      return if month_overflow?(year, month, day)

      begin
        day_start = Chronic.time_class.local(year, month, day)
        day_or_time(day_start, time_tokens, options)
      rescue ArgumentError
        nil
      end
    end

    # Handle oridinal-day/repeater-month-name/scalar-year
    def handle_od_rmn_sy(tokens, options)
      day = tokens[0].get_tag(OrdinalDay).type
      month = tokens[1].get_tag(RepeaterMonthName).index
      year = tokens[2].get_tag(ScalarYear).type
      time_tokens = tokens.last(tokens.size - 3)

      return if month_overflow?(year, month, day)

      begin
        day_start = Chronic.time_class.local(year, month, day)
        day_or_time(day_start, time_tokens, options)
      rescue ArgumentError
        nil
      end
    end

    # Handle scalar-day/repeater-month-name/scalar-year
    def handle_sd_rmn_sy(tokens, options)
      new_tokens = [tokens[1], tokens[0], tokens[2]]
      time_tokens = tokens.last(tokens.size - 3)
      handle_rmn_sd_sy(new_tokens + time_tokens, options)
    end

    # Handle scalar-month/scalar-day/scalar-year (endian middle)
    def handle_sm_sd_sy(tokens, options)
      month = tokens[0].get_tag(ScalarMonth).type
      day = tokens[1].get_tag(ScalarDay).type
      year = tokens[2].get_tag(ScalarYear).type
      time_tokens = tokens.last(tokens.size - 3)

      return if month_overflow?(year, month, day)

      begin
        day_start = Chronic.time_class.local(year, month, day)
        day_or_time(day_start, time_tokens, options)
      rescue ArgumentError
        nil
      end
    end

    # Handle scalar-day/scalar-month/scalar-year (endian little)
    def handle_sd_sm_sy(tokens, options)
      new_tokens = [tokens[1], tokens[0], tokens[2]]
      time_tokens = tokens.last(tokens.size - 3)
      handle_sm_sd_sy(new_tokens + time_tokens, options)
    end

    # Handle scalar-year/scalar-month/scalar-day
    def handle_sy_sm_sd(tokens, options)
      new_tokens = [tokens[1], tokens[2], tokens[0]]
      time_tokens = tokens.last(tokens.size - 3)
      handle_sm_sd_sy(new_tokens + time_tokens, options)
    end

    # Handle scalar-month/scalar-day
    def handle_sm_sd(tokens, options)
      month = tokens[0].get_tag(ScalarMonth).type
      day = tokens[1].get_tag(ScalarDay).type
      year = self.now.year
      time_tokens = tokens.last(tokens.size - 2)

      return if month_overflow?(year, month, day)

      begin
        day_start = Chronic.time_class.local(year, month, day)
        day_start = Chronic.time_class.local(year + 1, month, day) if options[:context] == :future && day_start < now
        day_or_time(day_start, time_tokens, options)
      rescue ArgumentError
        nil
      end
    end

    # Handle scalar-day/scalar-month
    def handle_sd_sm(tokens, options)
      new_tokens = [tokens[1], tokens[0]]
      time_tokens = tokens.last(tokens.size - 2)
      handle_sm_sd(new_tokens + time_tokens, options)
    end

    def handle_year_and_month(year, month)
      if month == 12
        next_month_year = year + 1
        next_month_month = 1
      else
        next_month_year = year
        next_month_month = month + 1
      end

      begin
        end_time = Chronic.time_class.local(next_month_year, next_month_month)
        Span.new(Chronic.time_class.local(year, month), end_time)
      rescue ArgumentError
        nil
      end
    end

    # Handle scalar-month/scalar-year
    def handle_sm_sy(tokens, options)
      month = tokens[0].get_tag(ScalarMonth).type
      year = tokens[1].get_tag(ScalarYear).type
      handle_year_and_month(year, month)
    end

    # Handle scalar-year/scalar-month
    def handle_sy_sm(tokens, options)
      year = tokens[0].get_tag(ScalarYear).type
      month = tokens[1].get_tag(ScalarMonth).type
      handle_year_and_month(year, month)
    end

    # Handle RepeaterDayName RepeaterMonthName OrdinalDay
    def handle_rdn_rmn_od(tokens, options)
      month = tokens[1].get_tag(RepeaterMonthName)
      day = tokens[2].get_tag(OrdinalDay).type
      time_tokens = tokens.last(tokens.size - 3)
      year = self.now.year

      return if month_overflow?(year, month.index, day)

      begin
        if time_tokens.empty?
          start_time = Chronic.time_class.local(year, month.index, day)
          end_time = time_with_rollover(year, month.index, day + 1)
          Span.new(start_time, end_time)
        else
          day_start = Chronic.time_class.local(year, month.index, day)
          day_or_time(day_start, time_tokens, options)
        end
      rescue ArgumentError
        nil
      end
    end

    # Handle RepeaterDayName RepeaterMonthName OrdinalDay ScalarYear
    def handle_rdn_rmn_od_sy(tokens, options)
      month = tokens[1].get_tag(RepeaterMonthName)
      day = tokens[2].get_tag(OrdinalDay).type
      year = tokens[3].get_tag(ScalarYear).type

      return if month_overflow?(year, month.index, day)

      begin
        start_time = Chronic.time_class.local(year, month.index, day)
        end_time = time_with_rollover(year, month.index, day + 1)
        Span.new(start_time, end_time)
      rescue ArgumentError
        nil
      end
    end

    # Handle RepeaterDayName OrdinalDay
    def handle_rdn_od(tokens, options)
      day = tokens[1].get_tag(OrdinalDay).type
      time_tokens = tokens.last(tokens.size - 2)
      year = self.now.year
      month = self.now.month
      if options[:context] == :future
        self.now.day > day ? month += 1 : month
      end

      return if month_overflow?(year, month, day)

      begin
        if time_tokens.empty?
          start_time = Chronic.time_class.local(year, month, day)
          end_time = time_with_rollover(year, month, day + 1)
          Span.new(start_time, end_time)
        else
          day_start = Chronic.time_class.local(year, month, day)
          day_or_time(day_start, time_tokens, options)
        end
      rescue ArgumentError
        nil
      end
    end

    # Handle RepeaterDayName RepeaterMonthName ScalarDay
    def handle_rdn_rmn_sd(tokens, options)
      month = tokens[1].get_tag(RepeaterMonthName)
      day = tokens[2].get_tag(ScalarDay).type
      time_tokens = tokens.last(tokens.size - 3)
      year = self.now.year

      return if month_overflow?(year, month.index, day)

      begin
        if time_tokens.empty?
          start_time = Chronic.time_class.local(year, month.index, day)
          end_time = time_with_rollover(year, month.index, day + 1)
          Span.new(start_time, end_time)
        else
          day_start = Chronic.time_class.local(year, month.index, day)
          day_or_time(day_start, time_tokens, options)
        end
      rescue ArgumentError
        nil
      end
    end

    # Handle RepeaterDayName RepeaterMonthName ScalarDay ScalarYear
    def handle_rdn_rmn_sd_sy(tokens, options)
      month = tokens[1].get_tag(RepeaterMonthName)
      day = tokens[2].get_tag(ScalarDay).type
      year = tokens[3].get_tag(ScalarYear).type

      return if month_overflow?(year, month.index, day)

      begin
        start_time = Chronic.time_class.local(year, month.index, day)
        end_time = time_with_rollover(year, month.index, day + 1)
        Span.new(start_time, end_time)
      rescue ArgumentError
        nil
      end
    end

    def handle_sm_rmn_sy(tokens, options)
      day = tokens[0].get_tag(ScalarDay).type
      month = tokens[1].get_tag(RepeaterMonthName).index
      year = tokens[2].get_tag(ScalarYear).type
      if tokens.size > 3
        time = get_anchor([tokens.last], options).begin
        h, m, s = time.hour, time.min, time.sec
        time = Chronic.time_class.local(year, month, day, h, m, s)
        end_time = Chronic.time_class.local(year, month, day + 1, h, m, s)
      else
        time = Chronic.time_class.local(year, month, day)
        day += 1 unless day >= 31
        end_time = Chronic.time_class.local(year, month, day)
      end
      Span.new(time, end_time)
    end

    # anchors

    # Handle repeaters
    def handle_r(tokens, options)
      dd_tokens = dealias_and_disambiguate_times(tokens, options)
      get_anchor(dd_tokens, options)
    end

    # Handle repeater/grabber/repeater
    def handle_r_g_r(tokens, options)
      new_tokens = [tokens[1], tokens[0], tokens[2]]
      handle_r(new_tokens, options)
    end

    # arrows

    # Handle scalar/repeater/pointer helper
    def handle_srp(tokens, span, options)
      distance = tokens[0].get_tag(Scalar).type
      repeater = tokens[1].get_tag(Repeater)
      pointer = tokens[2].get_tag(Pointer).type

      repeater.offset(span, distance, pointer) if repeater.respond_to?(:offset)
    end

    # Handle scalar/repeater/pointer
    def handle_s_r_p(tokens, options)
      span = Span.new(self.now, self.now + 1)

      handle_srp(tokens, span, options)
    end

    # Handle pointer/scalar/repeater
    def handle_p_s_r(tokens, options)
      new_tokens = [tokens[1], tokens[2], tokens[0]]
      handle_s_r_p(new_tokens, options)
    end

    # Handle scalar/repeater/pointer/anchor
    def handle_s_r_p_a(tokens, options)
      anchor_span = get_anchor(tokens[3..tokens.size - 1], options)
      handle_srp(tokens, anchor_span, options)
    end

    def handle_s_r_a_s_r_p_a(tokens, options)
      anchor_span = get_anchor(tokens[4..tokens.size - 1], options)

      span = handle_srp(tokens[0..1]+tokens[4..6], anchor_span, options)
      handle_srp(tokens[2..3]+tokens[4..6], span, options)
    end

    # narrows

    # Handle oridinal repeaters
    def handle_orr(tokens, outer_span, options)
      repeater = tokens[1].get_tag(Repeater)
      repeater.start = outer_span.begin - 1
      ordinal = tokens[0].get_tag(Ordinal).type
      span = nil

      ordinal.times do
        span = repeater.next(:future)

        if span.begin >= outer_span.end
          span = nil
          break
        end
      end

      span
    end

    # Handle ordinal/repeater/separator/repeater
    def handle_o_r_s_r(tokens, options)
      outer_span = get_anchor([tokens[3]], options)
      handle_orr(tokens[0..1], outer_span, options)
    end

    # Handle ordinal/repeater/grabber/repeater
    def handle_o_r_g_r(tokens, options)
      outer_span = get_anchor(tokens[2..3], options)
      handle_orr(tokens[0..1], outer_span, options)
    end

    # support methods

    def day_or_time(day_start, time_tokens, options)
      outer_span = Span.new(day_start, day_start + (24 * 60 * 60))

      unless time_tokens.empty?
        self.now = outer_span.begin
        get_anchor(dealias_and_disambiguate_times(time_tokens, options), options.merge(:context => :future))
      else
        outer_span
      end
    end

    def get_anchor(tokens, options)
      grabber = Grabber.new(:this)
      pointer = :future
      repeaters = get_repeaters(tokens)
      repeaters.size.times { tokens.pop }

      if tokens.first && tokens.first.get_tag(Grabber)
        grabber = tokens.shift.get_tag(Grabber)
      end

      head = repeaters.shift
      head.start = self.now

      case grabber.type
      when :last
        outer_span = head.next(:past)
      when :this
        if options[:context] != :past and repeaters.size > 0
          outer_span = head.this(:none)
        else
          outer_span = head.this(options[:context])
        end
      when :next
        outer_span = head.next(:future)
      else
        raise "Invalid grabber"
      end

      if Chronic.debug
        puts "Handler-class: #{head.class}"
        puts "--#{outer_span}"
      end

      find_within(repeaters, outer_span, pointer)
    end

    def get_repeaters(tokens)
      tokens.map { |token| token.get_tag(Repeater) }.compact.sort.reverse
    end

    def month_overflow?(year, month, day)
      if ::Date.leap?(year)
        day > RepeaterMonth::MONTH_DAYS_LEAP[month - 1]
      else
        day > RepeaterMonth::MONTH_DAYS[month - 1]
      end
    rescue ArgumentError
      false
    end

    # Recursively finds repeaters within other repeaters.
    # Returns a Span representing the innermost time span
    # or nil if no repeater union could be found
    def find_within(tags, span, pointer)
      puts "--#{span}" if Chronic.debug
      return span if tags.empty?

      head = tags.shift
      head.start = (pointer == :future ? span.begin : span.end)
      h = head.this(:none)

      if span.cover?(h.begin) || span.cover?(h.end)
        find_within(tags, h, pointer)
      end
    end

    def time_with_rollover(year, month, day)
      date_parts =
        if month_overflow?(year, month, day)
          if month == 12
            [year + 1, 1, 1]
          else
            [year, month + 1, 1]
          end
        else
          [year, month, day]
        end
      Chronic.time_class.local(*date_parts)
    end

    def dealias_and_disambiguate_times(tokens, options)
      # handle aliases of am/pm
      # 5:00 in the morning -> 5:00 am
      # 7:00 in the evening -> 7:00 pm

      day_portion_index = nil
      tokens.each_with_index do |t, i|
        if t.get_tag(RepeaterDayPortion)
          day_portion_index = i
          break
        end
      end

      time_index = nil
      tokens.each_with_index do |t, i|
        if t.get_tag(RepeaterTime)
          time_index = i
          break
        end
      end

      if day_portion_index && time_index
        t1 = tokens[day_portion_index]
        t1tag = t1.get_tag(RepeaterDayPortion)

        case t1tag.type
        when :morning
          puts '--morning->am' if Chronic.debug
          t1.untag(RepeaterDayPortion)
          t1.tag(RepeaterDayPortion.new(:am))
        when :afternoon, :evening, :night
          puts "--#{t1tag.type}->pm" if Chronic.debug
          t1.untag(RepeaterDayPortion)
          t1.tag(RepeaterDayPortion.new(:pm))
        end
      end

      # handle ambiguous times if :ambiguous_time_range is specified
      if options[:ambiguous_time_range] != :none
        ambiguous_tokens = []

        tokens.each_with_index do |token, i|
          ambiguous_tokens << token
          next_token = tokens[i + 1]

          if token.get_tag(RepeaterTime) && token.get_tag(RepeaterTime).type.ambiguous? && (!next_token || !next_token.get_tag(RepeaterDayPortion))
            distoken = Token.new('disambiguator')

            distoken.tag(RepeaterDayPortion.new(options[:ambiguous_time_range]))
            ambiguous_tokens << distoken
          end
        end

        tokens = ambiguous_tokens
      end

      tokens
    end

  end

end
#
module Chronic
  class Parser
    include Handlers

    # Hash of default configuration options.
    DEFAULT_OPTIONS = {
      :context => :future,
      :now => nil,
      :hours24 => nil,
      :guess => true,
      :ambiguous_time_range => 6,
      :endian_precedence    => [:middle, :little],
      :ambiguous_year_future_bias => 50
    }

    attr_accessor :now
    attr_reader :options

    # options - An optional Hash of configuration options:
    #        :context - If your string represents a birthday, you can set
    #                   this value to :past and if an ambiguous string is
    #                   given, it will assume it is in the past.
    #        :now - Time, all computations will be based off of time
    #               instead of Time.now.
    #        :hours24 - Time will be parsed as it would be 24 hour clock.
    #        :guess - By default the parser will guess a single point in time
    #                 for the given date or time. If you'd rather have the
    #                 entire time span returned, set this to false
    #                 and a Chronic::Span will be returned. Setting :guess to :end
    #                 will return last time from Span, to :middle for middle (same as just true)
    #                 and :begin for first time from span.
    #        :ambiguous_time_range - If an Integer is given, ambiguous times
    #                  (like 5:00) will be assumed to be within the range of
    #                  that time in the AM to that time in the PM. For
    #                  example, if you set it to `7`, then the parser will
    #                  look for the time between 7am and 7pm. In the case of
    #                  5:00, it would assume that means 5:00pm. If `:none`
    #                  is given, no assumption will be made, and the first
    #                  matching instance of that time will be used.
    #        :endian_precedence - By default, Chronic will parse "03/04/2011"
    #                 as the fourth day of the third month. Alternatively you
    #                 can tell Chronic to parse this as the third day of the
    #                 fourth month by setting this to [:little, :middle].
    #        :ambiguous_year_future_bias - When parsing two digit years
    #                 (ie 79) unlike Rubys Time class, Chronic will attempt
    #                 to assume the full year using this figure. Chronic will
    #                 look x amount of years into the future and past. If the
    #                 two digit year is `now + x years` it's assumed to be the
    #                 future, `now - x years` is assumed to be the past.
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @now = options.delete(:now) || Chronic.time_class.now
    end

    # Parse "text" with the given options
    # Returns either a Time or Chronic::Span, depending on the value of options[:guess]
    def parse(text)
      tokens = tokenize(text, options)
      span = tokens_to_span(tokens, options.merge(:text => text))

      puts "+#{'-' * 51}\n| #{tokens}\n+#{'-' * 51}" if Chronic.debug

      guess(span, options[:guess]) if span
    end

    # Clean up the specified text ready for parsing.
    #
    # Clean up the string by stripping unwanted characters, converting
    # idioms to their canonical form, converting number words to numbers
    # (three => 3), and converting ordinal words to numeric
    # ordinals (third => 3rd)
    #
    # text - The String text to normalize.
    #
    # Examples:
    #
    #   Chronic.pre_normalize('first day in May')
    #     #=> "1st day in may"
    #
    #   Chronic.pre_normalize('tomorrow after noon')
    #     #=> "next day future 12:00"
    #
    #   Chronic.pre_normalize('one hundred and thirty six days from now')
    #     #=> "136 days future this second"
    #
    # Returns a new String ready for Chronic to parse.
    def pre_normalize(text)
      text = text.to_s.downcase
      text = text.gsub(/\b(\d{2})\.(\d{2})\.(\d{4})\b/, '\3 / \2 / \1')
      text = text.gsub(/\b([ap])\.m\.?/, '\1m')
      text = text.gsub(/(\s+|:\d{2}|:\d{2}\.\d{3})\-(\d{2}:?\d{2})\b/, '\1tzminus\2')
      text = text.gsub(/\./, ':')
      text = text.gsub(/([ap]):m:?/, '\1m')
      text = text.gsub(/['"]/, '')
      text = text.gsub(/,/, ' ')
      text = text.gsub(/^second /, '2nd ')
      text = text.gsub(/\bsecond (of|day|month|hour|minute|second)\b/, '2nd \1')
      text = Numerizer.numerize(text)
      text = text.gsub(/([\/\-\,\@])/) { ' ' + $1 + ' ' }
      text = text.gsub(/(?:^|\s)0(\d+:\d+\s*pm?\b)/, ' \1')
      text = text.gsub(/\btoday\b/, 'this day')
      text = text.gsub(/\btomm?orr?ow\b/, 'next day')
      text = text.gsub(/\byesterday\b/, 'last day')
      text = text.gsub(/\bnoon\b/, '12:00pm')
      text = text.gsub(/\bmidnight\b/, '24:00')
      text = text.gsub(/\bnow\b/, 'this second')
      text = text.gsub('quarter', '15')
      text = text.gsub('half', '30')
      text = text.gsub(/(\d{1,2}) (to|till|prior to|before)\b/, '\1 minutes past')
      text = text.gsub(/(\d{1,2}) (after|past)\b/, '\1 minutes future')
      text = text.gsub(/\b(?:ago|before(?: now)?)\b/, 'past')
      text = text.gsub(/\bthis (?:last|past)\b/, 'last')
      text = text.gsub(/\b(?:in|during) the (morning)\b/, '\1')
      text = text.gsub(/\b(?:in the|during the|at) (afternoon|evening|night)\b/, '\1')
      text = text.gsub(/\btonight\b/, 'this night')
      text = text.gsub(/\b\d+:?\d*[ap]\b/,'\0m')
      text = text.gsub(/\b(\d{2})(\d{2})(am|pm)\b/, '\1:\2\3')
      text = text.gsub(/(\d)([ap]m|oclock)\b/, '\1 \2')
      text = text.gsub(/\b(hence|after|from)\b/, 'future')
      text = text.gsub(/^\s?an? /i, '1 ')
      text = text.gsub(/\b(\d{4}):(\d{2}):(\d{2})\b/, '\1 / \2 / \3') # DTOriginal
      text = text.gsub(/\b0(\d+):(\d{2}):(\d{2}) ([ap]m)\b/, '\1:\2:\3 \4')
      text
    end

    # Guess a specific time within the given span.
    #
    # span - The Chronic::Span object to calcuate a guess from.
    #
    # Returns a new Time object.
    def guess(span, mode = :middle)
      return span if not mode
      return span.begin + span.width / 2 if span.width > 1 and (mode == true or mode == :middle)
      return span.end if mode == :end
      span.begin
    end

    # List of Handler definitions. See Chronic.parse for a list of options this
    # method accepts.
    #
    # options - An optional Hash of configuration options.
    #
    # Returns a Hash of Handler definitions.
    def definitions(options = {})
      options[:endian_precedence] ||= [:middle, :little]

      @@definitions ||= {
        :time => [
          Handler.new([:repeater_time, :repeater_day_portion?], nil)
        ],

        :date => [
          Handler.new([:repeater_day_name, :repeater_month_name, :scalar_day, :repeater_time, [:separator_slash?, :separator_dash?], :time_zone, :scalar_year], :handle_generic),
          Handler.new([:repeater_day_name, :repeater_month_name, :scalar_day], :handle_rdn_rmn_sd),
          Handler.new([:repeater_day_name, :repeater_month_name, :scalar_day, :scalar_year], :handle_rdn_rmn_sd_sy),
          Handler.new([:repeater_day_name, :repeater_month_name, :ordinal_day], :handle_rdn_rmn_od),
          Handler.new([:repeater_day_name, :repeater_month_name, :ordinal_day, :scalar_year], :handle_rdn_rmn_od_sy),
          Handler.new([:repeater_day_name, :repeater_month_name, :scalar_day, :separator_at?, 'time?'], :handle_rdn_rmn_sd),
          Handler.new([:repeater_day_name, :repeater_month_name, :ordinal_day, :separator_at?, 'time?'], :handle_rdn_rmn_od),
          Handler.new([:repeater_day_name, :ordinal_day, :separator_at?, 'time?'], :handle_rdn_od),
          Handler.new([:scalar_year, [:separator_slash, :separator_dash], :scalar_month, [:separator_slash, :separator_dash], :scalar_day, :repeater_time, :time_zone], :handle_generic),
          Handler.new([:ordinal_day], :handle_generic),
          Handler.new([:repeater_month_name, :scalar_day, :scalar_year], :handle_rmn_sd_sy),
          Handler.new([:repeater_month_name, :ordinal_day, :scalar_year], :handle_rmn_od_sy),
          Handler.new([:repeater_month_name, :scalar_day, :scalar_year, :separator_at?, 'time?'], :handle_rmn_sd_sy),
          Handler.new([:repeater_month_name, :ordinal_day, :scalar_year, :separator_at?, 'time?'], :handle_rmn_od_sy),
          Handler.new([:repeater_month_name, [:separator_slash?, :separator_dash?], :scalar_day, :separator_at?, 'time?'], :handle_rmn_sd),
          Handler.new([:repeater_time, :repeater_day_portion?, :separator_on?, :repeater_month_name, :scalar_day], :handle_rmn_sd_on),
          Handler.new([:repeater_month_name, :ordinal_day, :separator_at?, 'time?'], :handle_rmn_od),
          Handler.new([:ordinal_day, :repeater_month_name, :scalar_year, :separator_at?, 'time?'], :handle_od_rmn_sy),
          Handler.new([:ordinal_day, :repeater_month_name, :separator_at?, 'time?'], :handle_od_rmn),
          Handler.new([:ordinal_day, :grabber?, :repeater_month, :separator_at?, 'time?'], :handle_od_rm),
          Handler.new([:scalar_year, :repeater_month_name, :ordinal_day], :handle_sy_rmn_od),
          Handler.new([:repeater_time, :repeater_day_portion?, :separator_on?, :repeater_month_name, :ordinal_day], :handle_rmn_od_on),
          Handler.new([:repeater_month_name, :scalar_year], :handle_rmn_sy),
          Handler.new([:scalar_day, :repeater_month_name, :scalar_year, :separator_at?, 'time?'], :handle_sd_rmn_sy),
          Handler.new([:scalar_day, [:separator_slash?, :separator_dash?], :repeater_month_name, :separator_at?, 'time?'], :handle_sd_rmn),
          Handler.new([:scalar_year, [:separator_slash, :separator_dash], :scalar_month, [:separator_slash, :separator_dash], :scalar_day, :separator_at?, 'time?'], :handle_sy_sm_sd),
          Handler.new([:scalar_year, [:separator_slash, :separator_dash], :scalar_month], :handle_sy_sm),
          Handler.new([:scalar_month, [:separator_slash, :separator_dash], :scalar_year], :handle_sm_sy),
          Handler.new([:scalar_day, [:separator_slash, :separator_dash], :repeater_month_name, [:separator_slash, :separator_dash], :scalar_year, :repeater_time?], :handle_sm_rmn_sy),
          Handler.new([:scalar_year, [:separator_slash, :separator_dash], :scalar_month, [:separator_slash, :separator_dash], :scalar?, :time_zone], :handle_generic),
        ],

        :anchor => [
          Handler.new([:separator_on?, :grabber?, :repeater, :separator_at?, :repeater?, :repeater?], :handle_r),
          Handler.new([:grabber?, :repeater, :repeater, :separator?, :repeater?, :repeater?], :handle_r),
          Handler.new([:repeater, :grabber, :repeater], :handle_r_g_r)
        ],

        :arrow => [
          Handler.new([:scalar, :repeater, :pointer], :handle_s_r_p),
          Handler.new([:scalar, :repeater, :separator_and?, :scalar, :repeater, :pointer, :separator_at?, 'anchor'], :handle_s_r_a_s_r_p_a),
          Handler.new([:pointer, :scalar, :repeater], :handle_p_s_r),
          Handler.new([:scalar, :repeater, :pointer, :separator_at?, 'anchor'], :handle_s_r_p_a)
        ],

        :narrow => [
          Handler.new([:ordinal, :repeater, :separator_in, :repeater], :handle_o_r_s_r),
          Handler.new([:ordinal, :repeater, :grabber, :repeater], :handle_o_r_g_r)
        ]
      }

      endians = [
        Handler.new([:scalar_month, [:separator_slash, :separator_dash], :scalar_day, [:separator_slash, :separator_dash], :scalar_year, :separator_at?, 'time?'], :handle_sm_sd_sy),
        Handler.new([:scalar_month, [:separator_slash, :separator_dash], :scalar_day, :separator_at?, 'time?'], :handle_sm_sd),
        Handler.new([:scalar_day, [:separator_slash, :separator_dash], :scalar_month, :separator_at?, 'time?'], :handle_sd_sm),
        Handler.new([:scalar_day, [:separator_slash, :separator_dash], :scalar_month, [:separator_slash, :separator_dash], :scalar_year, :separator_at?, 'time?'], :handle_sd_sm_sy)
      ]

      case endian = Array(options[:endian_precedence]).first
      when :little
        @@definitions.merge(:endian => endians.reverse)
      when :middle
        @@definitions.merge(:endian => endians)
      else
        raise ArgumentError, "Unknown endian option '#{endian}'"
      end
    end

    private

    def tokenize(text, options)
      text = pre_normalize(text)
      tokens = text.split(' ').map { |word| Token.new(word) }
      [Repeater, Grabber, Pointer, Scalar, Ordinal, Separator, Sign, TimeZone].each do |tok|
        tok.scan(tokens, options)
      end
      tokens.select { |token| token.tagged? }
    end

    def tokens_to_span(tokens, options)
      definitions = definitions(options)

      (definitions[:endian] + definitions[:date]).each do |handler|
        if handler.match(tokens, definitions)
          good_tokens = tokens.select { |o| !o.get_tag Separator }
          return handler.invoke(:date, good_tokens, self, options)
        end
      end

      definitions[:anchor].each do |handler|
        if handler.match(tokens, definitions)
          good_tokens = tokens.select { |o| !o.get_tag Separator }
          return handler.invoke(:anchor, good_tokens, self, options)
        end
      end

      definitions[:arrow].each do |handler|
        if handler.match(tokens, definitions)
          good_tokens = tokens.reject { |o| o.get_tag(SeparatorAt) || o.get_tag(SeparatorSlash) || o.get_tag(SeparatorDash) || o.get_tag(SeparatorComma) || o.get_tag(SeparatorAnd) }
          return handler.invoke(:arrow, good_tokens, self, options)
        end
      end

      definitions[:narrow].each do |handler|
        if handler.match(tokens, definitions)
          return handler.invoke(:narrow, tokens, self, options)
        end
      end

      puts "-none" if Chronic.debug
      return nil
    end
  end
end
#
module Chronic
  class Time
    HOUR_SECONDS = 3600 # 60 * 60
    MINUTE_SECONDS = 60
    SECOND_SECONDS = 1 # haha, awesome
    SUBSECOND_SECONDS = 0.001

    # Checks if given number could be hour
    def self.could_be_hour?(hour)
      hour >= 0 && hour <= 24
    end

    # Checks if given number could be minute
    def self.could_be_minute?(minute)
      minute >= 0 && minute <= 60
    end

    # Checks if given number could be second
    def self.could_be_second?(second)
      second >= 0 && second <= 60
    end

    # Checks if given number could be subsecond
    def self.could_be_subsecond?(subsecond)
      subsecond >= 0 && subsecond <= 999999
    end

    # normalize offset in seconds to offset as string +mm:ss or -mm:ss
    def self.normalize_offset(offset)
      return offset if offset.is_a?(String)
      offset = Chronic.time_class.now.to_time.utc_offset unless offset # get current system's UTC offset if offset is nil
      sign = '+'
      sign = '-' if offset < 0
      hours = (offset.abs / 3600).to_i.to_s.rjust(2,'0')
      minutes = (offset.abs % 3600).to_s.rjust(2,'0')
      sign + hours + minutes
    end

  end
end
#
module Chronic
  class Date
    YEAR_MONTHS = 12
    MONTH_DAYS        = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    MONTH_DAYS_LEAP   = [nil, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    YEAR_SECONDS      = 31_536_000 # 365 * 24 * 60 * 60
    SEASON_SECONDS    =  7_862_400 #  91 * 24 * 60 * 60
    MONTH_SECONDS     =  2_592_000 #  30 * 24 * 60 * 60
    FORTNIGHT_SECONDS =  1_209_600 #  14 * 24 * 60 * 60
    WEEK_SECONDS      =    604_800 #   7 * 24 * 60 * 60
    WEEKEND_SECONDS   =    172_800 #   2 * 24 * 60 * 60
    DAY_SECONDS       =     86_400 #       24 * 60 * 60
    MONTHS = {
      :january => 1,
      :february => 2,
      :march => 3,
      :april => 4,
      :may => 5,
      :june => 6,
      :july => 7,
      :august => 8,
      :september => 9,
      :october => 10,
      :november => 11,
      :december => 12
    }
    DAYS = {
      :sunday => 0,
      :monday => 1,
      :tuesday => 2,
      :wednesday => 3,
      :thursday => 4,
      :friday => 5,
      :saturday => 6
    }

    # Checks if given number could be day
    def self.could_be_day?(day)
      day >= 1 && day <= 31
    end

    # Checks if given number could be month
    def self.could_be_month?(month)
      month >= 1 && month <= 12
    end

    # Checks if given number could be year
    def self.could_be_year?(year)
      year >= 1 && year <= 9999
    end

    # Build a year from a 2 digit suffix.
    #
    # year - The two digit Integer year to build from.
    # bias - The Integer amount of future years to bias.
    #
    # Examples:
    #
    #   make_year(96, 50) #=> 1996
    #   make_year(79, 20) #=> 2079
    #   make_year(00, 50) #=> 2000
    #
    # Returns The Integer 4 digit year.
    def self.make_year(year, bias)
      return year if year.to_s.size > 2
      start_year = Chronic.time_class.now.year - bias
      century = (start_year / 100) * 100
      full_year = century + year
      full_year += 100 if full_year < start_year
      full_year
    end

    def self.month_overflow?(year, month, day)
      if ::Date.leap?(year)
        day > Date::MONTH_DAYS_LEAP[month]
      else
        day > Date::MONTH_DAYS[month]
      end
    end

  end
end
#
module Chronic
  class Handler

    attr_reader :pattern

    attr_reader :handler_method

    # pattern        - An Array of patterns to match tokens against.
    # handler_method - A Symbol representing the method to be invoked
    #   when a pattern matches.
    def initialize(pattern, handler_method)
      @pattern = pattern
      @handler_method = handler_method
    end

    # tokens - An Array of tokens to process.
    # definitions - A Hash of definitions to check against.
    #
    # Returns true if a match is found.
    def match(tokens, definitions)
      token_index = 0
      @pattern.each do |elements|
        was_optional = false
        elements = [elements] unless elements.is_a?(Array)

        elements.each_index do |i|
          name = elements[i].to_s
          optional = name[-1, 1] == '?'
          name = name.chop if optional

          case elements[i]
          when Symbol
            if tags_match?(name, tokens, token_index)
              token_index += 1
              break
            else
              if optional
                was_optional = true
                next
              elsif i + 1 < elements.count
                next
              else
                return false unless was_optional
              end
            end

          when String
            return true if optional && token_index == tokens.size

            if definitions.key?(name.to_sym)
              sub_handlers = definitions[name.to_sym]
            else
              raise "Invalid subset #{name} specified"
            end

            sub_handlers.each do |sub_handler|
              return true if sub_handler.match(tokens[token_index..tokens.size], definitions)
            end
          else
            raise "Invalid match type: #{elements[i].class}"
          end
        end

      end

      return false if token_index != tokens.size
      return true
    end

    def invoke(type, tokens, parser, options)
      if Chronic.debug
        puts "-#{type}"
        puts "Handler: #{@handler_method}"
      end

      parser.send(@handler_method, tokens, options)
    end

    # other - The other Handler object to compare.
    #
    # Returns true if these Handlers match.
    def ==(other)
      @pattern == other.pattern
    end

    private

    def tags_match?(name, tokens, token_index)
      klass = Chronic.const_get(name.to_s.gsub(/(?:^|_)(.)/) { $1.upcase })

      if tokens[token_index]
        !tokens[token_index].tags.select { |o| o.kind_of?(klass) }.empty?
      end
    end

  end
end
#
module Chronic
  class MiniDate
    attr_accessor :month, :day

    def self.from_time(time)
      new(time.month, time.day)
    end

    def initialize(month, day)
      unless (1..12).include?(month)
        raise ArgumentError, "1..12 are valid months"
      end

      @month = month
      @day = day
    end

    def is_between?(md_start, md_end)
      return false if (@month == md_start.month && @month == md_end.month) &&
                      (@day < md_start.day || @day > md_end.day)
      return true if (@month == md_start.month && @day >= md_start.day) ||
                     (@month == md_end.month && @day <= md_end.day)

      i = (md_start.month % 12) + 1

      until i == md_end.month
        return true if @month == i
        i = (i % 12) + 1
      end

      return false
    end

    def equals?(other)
      @month == other.month and @day == other.day
    end
  end
end
#
module Chronic
  # Tokens are tagged with subclassed instances of this class when
  # they match specific criteria.
  class Tag

    attr_accessor :type

    # type - The Symbol type of this tag.
    def initialize(type, options = {})
      @type = type
      @options = options
    end

    # time - Set the start Time for this Tag.
    def start=(time)
      @now = time
    end

    class << self
      private

      def scan_for(token, klass, items={}, options = {})
        case items
        when Regexp
          return klass.new(token.word, options) if items =~ token.word
        when Hash
          items.each do |item, symbol|
            return klass.new(symbol, options) if item =~ token.word
          end
        end
        nil
      end

    end

  end
end
#
module Chronic
  # A Span represents a range of time. Since this class extends
  # Range, you can use #begin and #end to get the beginning and
  # ending times of the span (they will be of class Time)
  class Span < Range
    # Returns the width of this span in seconds
    def width
      (self.end - self.begin).to_i
    end

    # Add a number of seconds to this span, returning the
    # resulting Span
    def +(seconds)
      Span.new(self.begin + seconds, self.end + seconds)
    end

    # Subtract a number of seconds to this span, returning the
    # resulting Span
    def -(seconds)
      self + -seconds
    end

    # Prints this span in a nice fashion
    def to_s
      ('(' + self.begin.to_s + '..' + self.end.to_s + ')')
    end

    alias :cover? :include? if RUBY_VERSION =~ /^1.8/

  end
end
#
module Chronic
  class Token

    attr_accessor :word
    attr_accessor :tags

    def initialize(word)
      @word = word
      @tags = []
    end

    # Tag this token with the specified tag.
    #
    # new_tag - The new Tag object.
    #
    # Returns nothing.
    def tag(new_tag)
      @tags << new_tag
    end

    # Remove all tags of the given class.
    #
    # tag_class - The tag Class to remove.
    #
    # Returns nothing.
    def untag(tag_class)
      @tags.delete_if { |m| m.kind_of? tag_class }
    end

    # Returns true if this token has any tags.
    def tagged?
      @tags.size > 0
    end

    # tag_class - The tag Class to search for.
    #
    # Returns The first Tag that matches the given class.
    def get_tag(tag_class)
      @tags.find { |m| m.kind_of? tag_class }
    end

    # Print this Token in a pretty way
    def to_s
      @word = (@word + '(' + @tags.join(', ') + ') ')
    end

    def inspect
      to_s
    end
  end
end
#
module Chronic
  class Grabber < Tag

    # Scan an Array of Tokens and apply any necessary Grabber tags to
    # each token.
    #
    # tokens  - An Array of Token objects to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of Token objects.
    def self.scan(tokens, options)
      tokens.each do |token|
        if t = scan_for_all(token) then token.tag(t); next end
      end
    end

    # token - The Token object to scan.
    #
    # Returns a new Grabber object.
    def self.scan_for_all(token)
      scan_for token, self,
      {
        /last/ => :last,
        /this/ => :this,
        /next/ => :next
      }
    end

    def to_s
      ('grabber-' + @type.to_s)
    end
  end
end
#
module Chronic
  class Pointer < Tag

    # Scan an Array of Token objects and apply any necessary Pointer
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each do |token|
        if t = scan_for_all(token) then token.tag(t) end
      end
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Pointer object.
    def self.scan_for_all(token)
      scan_for token, self,
      {
        /\bpast\b/ => :past,
        /\b(?:future|in)\b/ => :future,
      }
    end

    def to_s
      ('pointer-' + @type.to_s)
    end
  end
end
#
module Chronic
  class Scalar < Tag
    DAY_PORTIONS = %w( am pm morning afternoon evening night )

    # Scan an Array of Token objects and apply any necessary Scalar
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each_index do |i|
        token = tokens[i]
        post_token = tokens[i + 1]
        if token.word =~ /^\d+$/
            scalar = token.word.to_i
            token.tag(Scalar.new(scalar))
            token.tag(ScalarSubsecond.new(scalar)) if Chronic::Time::could_be_subsecond?(scalar)
            token.tag(ScalarSecond.new(scalar)) if Chronic::Time::could_be_second?(scalar)
            token.tag(ScalarMinute.new(scalar)) if Chronic::Time::could_be_minute?(scalar)
            token.tag(ScalarHour.new(scalar)) if Chronic::Time::could_be_hour?(scalar)
            unless post_token and DAY_PORTIONS.include?(post_token.word)
              token.tag(ScalarDay.new(scalar)) if Chronic::Date::could_be_day?(scalar)
              token.tag(ScalarMonth.new(scalar)) if Chronic::Date::could_be_month?(scalar)
              if Chronic::Date::could_be_year?(scalar)
                year = Chronic::Date::make_year(scalar, options[:ambiguous_year_future_bias])
                token.tag(ScalarYear.new(year.to_i))
              end
            end
        end
      end
    end

    def to_s
      'scalar'
    end
  end

  class ScalarSubsecond < Scalar #:nodoc:
    def to_s
      (super + '-subsecond-' + @type.to_s)
    end
  end

  class ScalarSecond < Scalar #:nodoc:
    def to_s
      (super + '-second-' + @type.to_s)
    end
  end

  class ScalarMinute < Scalar #:nodoc:
    def to_s
      (super + '-minute-' + @type.to_s)
    end
  end

  class ScalarHour < Scalar #:nodoc:
    def to_s
      (super + '-hour-' + @type.to_s)
    end
  end

  class ScalarDay < Scalar #:nodoc:
    def to_s
      (super + '-day-' + @type.to_s)
    end
  end

  class ScalarMonth < Scalar #:nodoc:
    def to_s
      (super + '-month-' + @type.to_s)
    end
  end

  class ScalarYear < Scalar #:nodoc:
    def to_s
      (super + '-year-' + @type.to_s)
    end
  end
end
#
module Chronic
  class Ordinal < Tag

    # Scan an Array of Token objects and apply any necessary Ordinal
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each_index do |i|
        if tokens[i].word =~ /^(\d+)(st|nd|rd|th|\.)$/
            ordinal = $1.to_i
            tokens[i].tag(Ordinal.new(ordinal))
            tokens[i].tag(OrdinalDay.new(ordinal)) if Chronic::Date::could_be_day?(ordinal)
            tokens[i].tag(OrdinalMonth.new(ordinal)) if Chronic::Date::could_be_month?(ordinal)
            if Chronic::Date::could_be_year?(ordinal)
                year = Chronic::Date::make_year(ordinal, options[:ambiguous_year_future_bias])
                tokens[i].tag(OrdinalYear.new(year.to_i))
            end
        end
      end
    end

    def to_s
      'ordinal'
    end
  end

  class OrdinalDay < Ordinal #:nodoc:
    def to_s
      (super + '-day-' + @type.to_s)
    end
  end

  class OrdinalMonth < Ordinal #:nodoc:
    def to_s
      (super + '-month-' + @type.to_s)
    end
  end

  class OrdinalYear < Ordinal #:nodoc:
    def to_s
      (super + '-year-' + @type.to_s)
    end
  end

end
#
module Chronic
  class Separator < Tag

    # Scan an Array of Token objects and apply any necessary Separator
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each do |token|
        if t = scan_for_commas(token) then token.tag(t); next end
        if t = scan_for_dots(token) then token.tag(t); next end
        if t = scan_for_colon(token) then token.tag(t); next end
        if t = scan_for_space(token) then token.tag(t); next end
        if t = scan_for_slash(token) then token.tag(t); next end
        if t = scan_for_dash(token) then token.tag(t); next end
        if t = scan_for_quote(token) then token.tag(t); next end
        if t = scan_for_at(token) then token.tag(t); next end
        if t = scan_for_in(token) then token.tag(t); next end
        if t = scan_for_on(token) then token.tag(t); next end
        if t = scan_for_and(token) then token.tag(t); next end
        if t = scan_for_t(token) then token.tag(t); next end
        if t = scan_for_w(token) then token.tag(t); next end
      end
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorComma object.
    def self.scan_for_commas(token)
      scan_for token, SeparatorComma, { /^,$/ => :comma }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorDot object.
    def self.scan_for_dots(token)
      scan_for token, SeparatorDot, { /^\.$/ => :dot }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorColon object.
    def self.scan_for_colon(token)
      scan_for token, SeparatorColon, { /^:$/ => :colon }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorSpace object.
    def self.scan_for_space(token)
      scan_for token, SeparatorSpace, { /^ $/ => :space }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorSlash object.
    def self.scan_for_slash(token)
      scan_for token, SeparatorSlash, { /^\/$/ => :slash }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorDash object.
    def self.scan_for_dash(token)
      scan_for token, SeparatorDash, { /^-$/ => :dash }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorQuote object.
    def self.scan_for_quote(token)
      scan_for token, SeparatorQuote,
      {
        /^'$/ => :single_quote,
        /^"$/ => :double_quote
      }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorAt object.
    def self.scan_for_at(token)
      scan_for token, SeparatorAt, { /^(at|@)$/ => :at }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorIn object.
    def self.scan_for_in(token)
      scan_for token, SeparatorIn, { /^in$/ => :in }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeparatorOn object.
    def self.scan_for_on(token)
      scan_for token, SeparatorOn, { /^on$/ => :on }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeperatorAnd Object object.
    def self.scan_for_and(token)
      scan_for token, SeparatorAnd, { /^and$/ => :and }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeperatorT Object object.
    def self.scan_for_t(token)
      scan_for token, SeparatorT, { /^t$/ => :T }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SeperatorW Object object.
    def self.scan_for_w(token)
      scan_for token, SeparatorW, { /^w$/ => :W }
    end

    def to_s
      'separator'
    end
  end

  class SeparatorComma < Separator #:nodoc:
    def to_s
      (super + '-comma')
    end
  end

  class SeparatorDot < Separator #:nodoc:
    def to_s
      (super + '-dot')
    end
  end

  class SeparatorColon < Separator #:nodoc:
    def to_s
      (super + '-colon')
    end
  end
  
  class SeparatorSpace < Separator #:nodoc:
    def to_s
      (super + '-space')
    end
  end

  class SeparatorSlash < Separator #:nodoc:
    def to_s
      (super + '-slash')
    end
  end

  class SeparatorDash < Separator #:nodoc:
    def to_s
      (super + '-dash')
    end
  end

  class SeparatorQuote < Separator #:nodoc:
    def to_s
      (super + '-quote-' + @type.to_s)
    end
  end

  class SeparatorAt < Separator #:nodoc:
    def to_s
      (super + '-at')
    end
  end

  class SeparatorIn < Separator #:nodoc:
    def to_s
      (super + '-in')
    end
  end

  class SeparatorOn < Separator #:nodoc:
    def to_s
      (super + '-on')
    end
  end

  class SeparatorAnd < Separator #:nodoc:
    def to_s
      (super + '-and')
    end
  end

  class SeparatorT < Separator #:nodoc:
    def to_s
      (super + '-T')
    end
  end

  class SeparatorW < Separator #:nodoc:
    def to_s
      (super + '-W')
    end
  end

end
#
module Chronic
  class Sign < Tag

    # Scan an Array of Token objects and apply any necessary Sign
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each do |token|
        if t = scan_for_plus(token) then token.tag(t); next end
        if t = scan_for_minus(token) then token.tag(t); next end
      end
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SignPlus object.
    def self.scan_for_plus(token)
      scan_for token, SignPlus, { /^\+$/ => :plus }
    end

    # token - The Token object we want to scan.
    #
    # Returns a new SignMinus object.
    def self.scan_for_minus(token)
      scan_for token, SignMinus, { /^-$/ => :minus }
    end

    def to_s
      'sign'
    end
  end

  class SignPlus < Sign #:nodoc:
    def to_s
      (super + '-plus')
    end
  end

  class SignMinus < Sign #:nodoc:
    def to_s
      (super + '-minus')
    end
  end

end
#
module Chronic
  class TimeZone < Tag

    # Scan an Array of Token objects and apply any necessary TimeZone
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each do |token|
        if t = scan_for_all(token) then token.tag(t); next end
      end
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Pointer object.
    def self.scan_for_all(token)
      scan_for token, self,
      {
        /[PMCE][DS]T|UTC/i => :tz,
        /(tzminus)?\d{2}:?\d{2}/ => :tz
      }
    end

    def to_s
      'timezone'
    end
  end
end
#
require 'strscan'

module Chronic
  class Numerizer

    DIRECT_NUMS = [
      ['eleven', '11'],
      ['twelve', '12'],
      ['thirteen', '13'],
      ['fourteen', '14'],
      ['fifteen', '15'],
      ['sixteen', '16'],
      ['seventeen', '17'],
      ['eighteen', '18'],
      ['nineteen', '19'],
      ['ninteen', '19'], # Common mis-spelling
      ['zero', '0'],
      ['one', '1'],
      ['two', '2'],
      ['three', '3'],
      ['four(\W|$)', '4\1'],  # The weird regex is so that it matches four but not fourty
      ['five', '5'],
      ['six(\W|$)', '6\1'],
      ['seven(\W|$)', '7\1'],
      ['eight(\W|$)', '8\1'],
      ['nine(\W|$)', '9\1'],
      ['ten', '10'],
      ['\ba[\b^$]', '1'] # doesn't make sense for an 'a' at the end to be a 1
    ]

    ORDINALS = [
      ['first', '1'],
      ['third', '3'],
      ['fourth', '4'],
      ['fifth', '5'],
      ['sixth', '6'],
      ['seventh', '7'],
      ['eighth', '8'],
      ['ninth', '9'],
      ['tenth', '10'],
      ['twelfth', '12'],
      ['twentieth', '20'],
      ['thirtieth', '30'],
      ['fourtieth', '40'],
      ['fiftieth', '50'],
      ['sixtieth', '60'],
      ['seventieth', '70'],
      ['eightieth', '80'],
      ['ninetieth', '90']
    ]

    TEN_PREFIXES = [
      ['twenty', 20],
      ['thirty', 30],
      ['forty', 40],
      ['fourty', 40], # Common mis-spelling
      ['fifty', 50],
      ['sixty', 60],
      ['seventy', 70],
      ['eighty', 80],
      ['ninety', 90]
    ]

    BIG_PREFIXES = [
      ['hundred', 100],
      ['thousand', 1000],
      ['million', 1_000_000],
      ['billion', 1_000_000_000],
      ['trillion', 1_000_000_000_000],
    ]

    def self.numerize(string)
      string = string.dup

      # preprocess
      string = string.gsub(/ +|([^\d])-([^\d])/, '\1 \2') # will mutilate hyphenated-words but shouldn't matter for date extraction
      string = string.gsub(/a half/, 'haAlf') # take the 'a' out so it doesn't turn into a 1, save the half for the end

      # easy/direct replacements

      DIRECT_NUMS.each do |dn|
        string = string.gsub(/#{dn[0]}/i, '<num>' + dn[1])
      end

      ORDINALS.each do |on|
        string = string.gsub(/#{on[0]}/i, '<num>' + on[1] + on[0][-2, 2])
      end

      # ten, twenty, etc.

      TEN_PREFIXES.each do |tp|
        string = string.gsub(/(?:#{tp[0]}) *<num>(\d(?=[^\d]|$))*/i) { '<num>' + (tp[1] + $1.to_i).to_s }
      end

      TEN_PREFIXES.each do |tp|
        string = string.gsub(/#{tp[0]}/i) { '<num>' + tp[1].to_s }
      end

      # hundreds, thousands, millions, etc.

      BIG_PREFIXES.each do |bp|
        string = string.gsub(/(?:<num>)?(\d*) *#{bp[0]}/i) { $1.empty? ? bp[1] : '<num>' + (bp[1] * $1.to_i).to_s}
        andition(string)
      end

      # fractional addition
      # I'm not combining this with the previous block as using float addition complicates the strings
      # (with extraneous .0's and such )
      string = string.gsub(/(\d+)(?: | and |-)*haAlf/i) { ($1.to_f + 0.5).to_s }

      string.gsub(/<num>/, '')
    end

    class << self
      private

      def andition(string)
        sc = StringScanner.new(string)

        while sc.scan_until(/<num>(\d+)( | and )<num>(\d+)(?=[^\w]|$)/i)
          if sc[2] =~ /and/ || sc[1].size > sc[3].size
            string[(sc.pos - sc.matched_size)..(sc.pos-1)] = '<num>' + (sc[1].to_i + sc[3].to_i).to_s
            sc.reset
          end
        end
      end

    end
  end
end
#
module Chronic
  class Season

    attr_reader :start
    attr_reader :end

    def initialize(start_date, end_date)
      @start = start_date
      @end = end_date
    end

    def self.find_next_season(season, pointer)
      lookup = [:spring, :summer, :autumn, :winter]
      next_season_num = (lookup.index(season) + 1 * pointer) % 4
      lookup[next_season_num]
    end

    def self.season_after(season)
      find_next_season(season, +1)
    end

    def self.season_before(season)
      find_next_season(season, -1)
    end
  end
end
#
module Chronic
  class Repeater < Tag

    # Scan an Array of Token objects and apply any necessary Repeater
    # tags to each token.
    #
    # tokens - An Array of tokens to scan.
    # options - The Hash of options specified in Chronic::parse.
    #
    # Returns an Array of tokens.
    def self.scan(tokens, options)
      tokens.each do |token|
        if t = scan_for_season_names(token, options) then token.tag(t); next end
        if t = scan_for_month_names(token, options) then token.tag(t); next end
        if t = scan_for_day_names(token, options) then token.tag(t); next end
        if t = scan_for_day_portions(token, options) then token.tag(t); next end
        if t = scan_for_times(token, options) then token.tag(t); next end
        if t = scan_for_units(token, options) then token.tag(t); next end
      end
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Repeater object.
    def self.scan_for_season_names(token, options = {})
      scan_for token, RepeaterSeasonName,
      {
        /^springs?$/ => :spring,
        /^summers?$/ => :summer,
        /^(autumn)|(fall)s?$/ => :autumn,
        /^winters?$/ => :winter
      }, options
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Repeater object.
    def self.scan_for_month_names(token, options = {})
      scan_for token, RepeaterMonthName,
      {
        /^jan[:\.]?(uary)?$/ => :january,
        /^feb[:\.]?(ruary)?$/ => :february,
        /^mar[:\.]?(ch)?$/ => :march,
        /^apr[:\.]?(il)?$/ => :april,
        /^may$/ => :may,
        /^jun[:\.]?e?$/ => :june,
        /^jul[:\.]?y?$/ => :july,
        /^aug[:\.]?(ust)?$/ => :august,
        /^sep[:\.]?(t[:\.]?|tember)?$/ => :september,
        /^oct[:\.]?(ober)?$/ => :october,
        /^nov[:\.]?(ember)?$/ => :november,
        /^dec[:\.]?(ember)?$/ => :december
      }, options
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Repeater object.
    def self.scan_for_day_names(token, options = {})
      scan_for token, RepeaterDayName,
      {
        /^m[ou]n(day)?$/ => :monday,
        /^t(ue|eu|oo|u|)s?(day)?$/ => :tuesday,
        /^we(d|dnes|nds|nns)(day)?$/ => :wednesday,
        /^th(u|ur|urs|ers)(day)?$/ => :thursday,
        /^fr[iy](day)?$/ => :friday,
        /^sat(t?[ue]rday)?$/ => :saturday,
        /^su[nm](day)?$/ => :sunday
      }, options
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Repeater object.
    def self.scan_for_day_portions(token, options = {})
      scan_for token, RepeaterDayPortion,
      {
        /^ams?$/ => :am,
        /^pms?$/ => :pm,
        /^mornings?$/ => :morning,
        /^afternoons?$/ => :afternoon,
        /^evenings?$/ => :evening,
        /^(night|nite)s?$/ => :night
      }, options
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Repeater object.
    def self.scan_for_times(token, options = {})
      scan_for token, RepeaterTime, /^\d{1,2}(:?\d{1,2})?([\.:]?\d{1,2}([\.:]\d{1,6})?)?$/, options
    end

    # token - The Token object we want to scan.
    #
    # Returns a new Repeater object.
    def self.scan_for_units(token, options = {})
      {
        /^years?$/ => :year,
        /^seasons?$/ => :season,
        /^months?$/ => :month,
        /^fortnights?$/ => :fortnight,
        /^weeks?$/ => :week,
        /^weekends?$/ => :weekend,
        /^(week|business)days?$/ => :weekday,
        /^days?$/ => :day,
	      /^hrs?$/ => :hour,
        /^hours?$/ => :hour,
	      /^mins?$/ => :minute,
        /^minutes?$/ => :minute,
	      /^secs?$/ => :second,
        /^seconds?$/ => :second
      }.each do |item, symbol|
        if item =~ token.word
          klass_name = 'Repeater' + symbol.to_s.capitalize
          klass = Chronic.const_get(klass_name)
          return klass.new(symbol, options)
        end
      end
      return nil
    end

    def <=>(other)
      width <=> other.width
    end

    # returns the width (in seconds or months) of this repeatable.
    def width
      raise("Repeater#width must be overridden in subclasses")
    end

    # returns the next occurance of this repeatable.
    def next(pointer)
      raise("Start point must be set before calling #next") unless @now
    end

    def this(pointer)
      raise("Start point must be set before calling #this") unless @now
    end

    def to_s
      'repeater'
    end
  end
end
#
module Chronic
  class RepeaterYear < Repeater #:nodoc:
    YEAR_SECONDS =  31536000  # 365 * 24 * 60 * 60

    def initialize(type, options = {})
      super
      @current_year_start = nil
    end

    def next(pointer)
      super

      unless @current_year_start
        case pointer
        when :future
          @current_year_start = Chronic.construct(@now.year + 1)
        when :past
          @current_year_start = Chronic.construct(@now.year - 1)
        end
      else
        diff = pointer == :future ? 1 : -1
        @current_year_start = Chronic.construct(@current_year_start.year + diff)
      end

      Span.new(@current_year_start, Chronic.construct(@current_year_start.year + 1))
    end

    def this(pointer = :future)
      super

      case pointer
      when :future
        this_year_start = Chronic.construct(@now.year, @now.month, @now.day + 1)
        this_year_end = Chronic.construct(@now.year + 1, 1, 1)
      when :past
        this_year_start = Chronic.construct(@now.year, 1, 1)
        this_year_end = Chronic.construct(@now.year, @now.month, @now.day)
      when :none
        this_year_start = Chronic.construct(@now.year, 1, 1)
        this_year_end = Chronic.construct(@now.year + 1, 1, 1)
      end

      Span.new(this_year_start, this_year_end)
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      new_begin = build_offset_time(span.begin, amount, direction)
      new_end   = build_offset_time(span.end, amount, direction)
      Span.new(new_begin, new_end)
    end

    def width
      YEAR_SECONDS
    end

    def to_s
      (super + '-year')
    end

    private

    def build_offset_time(time, amount, direction)
      year = time.year + (amount * direction)
      days = month_days(year, time.month)
      day = time.day > days ? days : time.day
      Chronic.construct(year, time.month, day, time.hour, time.min, time.sec)
    end

    def month_days(year, month)
      if ::Date.leap?(year)
        RepeaterMonth::MONTH_DAYS_LEAP[month - 1]
      else
        RepeaterMonth::MONTH_DAYS[month - 1]
      end
    end
  end
end
#
module Chronic
  class RepeaterSeason < Repeater #:nodoc:
    SEASON_SECONDS = 7_862_400 # 91 * 24 * 60 * 60
    SEASONS = {
      :spring => Season.new(MiniDate.new(3,20), MiniDate.new(6,20)),
      :summer => Season.new(MiniDate.new(6,21), MiniDate.new(9,22)),
      :autumn => Season.new(MiniDate.new(9,23), MiniDate.new(12,21)),
      :winter => Season.new(MiniDate.new(12,22), MiniDate.new(3,19))
    }

    def initialize(type, options = {})
      super
      @next_season_start = nil
      @next_season_end = nil
    end

    def next(pointer)
      super

      direction = pointer == :future ? 1 : -1
      next_season = Season.find_next_season(find_current_season(MiniDate.from_time(@now)), direction)

      find_next_season_span(direction, next_season)
    end

    def this(pointer = :future)
      super

      direction = pointer == :future ? 1 : -1

      today = Chronic.construct(@now.year, @now.month, @now.day)
      this_ssn = find_current_season(MiniDate.from_time(@now))
      case pointer
      when :past
        this_ssn_start = today + direction * num_seconds_til_start(this_ssn, direction)
        this_ssn_end = today
      when :future
        this_ssn_start = today + RepeaterDay::DAY_SECONDS
        this_ssn_end = today + direction * num_seconds_til_end(this_ssn, direction)
      when :none
        this_ssn_start = today + direction * num_seconds_til_start(this_ssn, direction)
        this_ssn_end = today + direction * num_seconds_til_end(this_ssn, direction)
      end

      construct_season(this_ssn_start, this_ssn_end)
    end

    def offset(span, amount, pointer)
      Span.new(offset_by(span.begin, amount, pointer), offset_by(span.end, amount, pointer))
    end

    def offset_by(time, amount, pointer)
      direction = pointer == :future ? 1 : -1
      time + amount * direction * SEASON_SECONDS
    end

    def width
      SEASON_SECONDS
    end

    def to_s
      (super + '-season')
    end

    private

    def find_next_season_span(direction, next_season)
      unless @next_season_start || @next_season_end
        @next_season_start = Chronic.construct(@now.year, @now.month, @now.day)
        @next_season_end = Chronic.construct(@now.year, @now.month, @now.day)
      end

      @next_season_start += direction * num_seconds_til_start(next_season, direction)
      @next_season_end += direction * num_seconds_til_end(next_season, direction)

      construct_season(@next_season_start, @next_season_end)
    end

    def find_current_season(md)
      [:spring, :summer, :autumn, :winter].find do |season|
        md.is_between?(SEASONS[season].start, SEASONS[season].end)
      end
    end

    def num_seconds_til(goal, direction)
      start = Chronic.construct(@now.year, @now.month, @now.day)
      seconds = 0

      until MiniDate.from_time(start + direction * seconds).equals?(goal)
        seconds += RepeaterDay::DAY_SECONDS
      end

      seconds
    end

    def num_seconds_til_start(season_symbol, direction)
      num_seconds_til(SEASONS[season_symbol].start, direction)
    end

    def num_seconds_til_end(season_symbol, direction)
      num_seconds_til(SEASONS[season_symbol].end, direction)
    end

    def construct_season(start, finish)
      Span.new(
        Chronic.construct(start.year, start.month, start.day),
        Chronic.construct(finish.year, finish.month, finish.day)
      )
    end
  end
end
#
module Chronic
  class RepeaterSeasonName < RepeaterSeason #:nodoc:
    SEASON_SECONDS = 7_862_400 # 91 * 24 * 60 * 60
    DAY_SECONDS = 86_400 # (24 * 60 * 60)

    def next(pointer)
      direction = pointer == :future ? 1 : -1
      find_next_season_span(direction, @type)
    end

    def this(pointer = :future)
      direction = pointer == :future ? 1 : -1

      today = Chronic.construct(@now.year, @now.month, @now.day)
      goal_ssn_start = today + direction * num_seconds_til_start(@type, direction)
      goal_ssn_end = today + direction * num_seconds_til_end(@type, direction)
      curr_ssn = find_current_season(MiniDate.from_time(@now))
      case pointer
      when :past
        this_ssn_start = goal_ssn_start
        this_ssn_end = (curr_ssn == @type) ? today : goal_ssn_end
      when :future
        this_ssn_start = (curr_ssn == @type) ? today + RepeaterDay::DAY_SECONDS : goal_ssn_start
        this_ssn_end = goal_ssn_end
      when :none
        this_ssn_start = goal_ssn_start
        this_ssn_end = goal_ssn_end
      end

      construct_season(this_ssn_start, this_ssn_end)
    end

    def offset(span, amount, pointer)
      Span.new(offset_by(span.begin, amount, pointer), offset_by(span.end, amount, pointer))
    end

    def offset_by(time, amount, pointer)
      direction = pointer == :future ? 1 : -1
      time + amount * direction * RepeaterYear::YEAR_SECONDS
    end

  end
end
#
module Chronic
  class RepeaterMonth < Repeater #:nodoc:
    MONTH_SECONDS = 2_592_000 # 30 * 24 * 60 * 60
    YEAR_MONTHS = 12
    MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    MONTH_DAYS_LEAP = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    def initialize(type, options = {})
      super
      @current_month_start = nil
    end

    def next(pointer)
      super

      unless @current_month_start
        @current_month_start = offset_by(Chronic.construct(@now.year, @now.month), 1, pointer)
      else
        @current_month_start = offset_by(Chronic.construct(@current_month_start.year, @current_month_start.month), 1, pointer)
      end

      Span.new(@current_month_start, Chronic.construct(@current_month_start.year, @current_month_start.month + 1))
    end

    def this(pointer = :future)
      super

      case pointer
      when :future
        month_start = Chronic.construct(@now.year, @now.month, @now.day + 1)
        month_end = self.offset_by(Chronic.construct(@now.year, @now.month), 1, :future)
      when :past
        month_start = Chronic.construct(@now.year, @now.month)
        month_end = Chronic.construct(@now.year, @now.month, @now.day)
      when :none
        month_start = Chronic.construct(@now.year, @now.month)
        month_end = self.offset_by(Chronic.construct(@now.year, @now.month), 1, :future)
      end

      Span.new(month_start, month_end)
    end

    def offset(span, amount, pointer)
      Span.new(offset_by(span.begin, amount, pointer), offset_by(span.end, amount, pointer))
    end

    def offset_by(time, amount, pointer)
      direction = pointer == :future ? 1 : -1

      amount_years = direction * amount / YEAR_MONTHS
      amount_months = direction * amount % YEAR_MONTHS

      new_year = time.year + amount_years
      new_month = time.month + amount_months
      if new_month > YEAR_MONTHS
        new_year += 1
        new_month -= YEAR_MONTHS
      end

      days = month_days(new_year, new_month)
      new_day = time.day > days ? days : time.day

      Chronic.construct(new_year, new_month, new_day, time.hour, time.min, time.sec)
    end

    def width
      MONTH_SECONDS
    end

    def to_s
      (super + '-month')
    end

    private

    def month_days(year, month)
      ::Date.leap?(year) ? MONTH_DAYS_LEAP[month - 1] : MONTH_DAYS[month - 1]
    end
  end
end
#
module Chronic
  class RepeaterMonthName < Repeater #:nodoc:
    MONTH_SECONDS = 2_592_000 # 30 * 24 * 60 * 60
    MONTHS = {
      :january => 1,
      :february => 2,
      :march => 3,
      :april => 4,
      :may => 5,
      :june => 6,
      :july => 7,
      :august => 8,
      :september => 9,
      :october => 10,
      :november => 11,
      :december => 12
    }

    def initialize(type, options = {})
      super
      @current_month_begin = nil
    end

    def next(pointer)
      super

      unless @current_month_begin
        case pointer
        when :future
          if @now.month < index
            @current_month_begin = Chronic.construct(@now.year, index)
          elsif @now.month > index
            @current_month_begin = Chronic.construct(@now.year + 1, index)
          end
        when :none
          if @now.month <= index
            @current_month_begin = Chronic.construct(@now.year, index)
          elsif @now.month > index
            @current_month_begin = Chronic.construct(@now.year + 1, index)
          end
        when :past
          if @now.month >= index
            @current_month_begin = Chronic.construct(@now.year, index)
          elsif @now.month < index
            @current_month_begin = Chronic.construct(@now.year - 1, index)
          end
        end
        @current_month_begin || raise("Current month should be set by now")
      else
        case pointer
        when :future
          @current_month_begin = Chronic.construct(@current_month_begin.year + 1, @current_month_begin.month)
        when :past
          @current_month_begin = Chronic.construct(@current_month_begin.year - 1, @current_month_begin.month)
        end
      end

      cur_month_year = @current_month_begin.year
      cur_month_month = @current_month_begin.month

      if cur_month_month == 12
        next_month_year = cur_month_year + 1
        next_month_month = 1
      else
        next_month_year = cur_month_year
        next_month_month = cur_month_month + 1
      end

      Span.new(@current_month_begin, Chronic.construct(next_month_year, next_month_month))
    end

    def this(pointer = :future)
      super

      case pointer
      when :past
        self.next(pointer)
      when :future, :none
        self.next(:none)
      end
    end

    def width
      MONTH_SECONDS
    end

    def index
      @index ||= MONTHS[@type]
    end

    def to_s
      (super + '-monthname-' + @type.to_s)
    end
  end
end
#
module Chronic
  class RepeaterFortnight < Repeater #:nodoc:
    FORTNIGHT_SECONDS = 1_209_600 # (14 * 24 * 60 * 60)

    def initialize(type, options = {})
      super
      @current_fortnight_start = nil
    end

    def next(pointer)
      super

      unless @current_fortnight_start
        case pointer
        when :future
          sunday_repeater = RepeaterDayName.new(:sunday)
          sunday_repeater.start = @now
          next_sunday_span = sunday_repeater.next(:future)
          @current_fortnight_start = next_sunday_span.begin
        when :past
          sunday_repeater = RepeaterDayName.new(:sunday)
          sunday_repeater.start = (@now + RepeaterDay::DAY_SECONDS)
          2.times { sunday_repeater.next(:past) }
          last_sunday_span = sunday_repeater.next(:past)
          @current_fortnight_start = last_sunday_span.begin
        end
      else
        direction = pointer == :future ? 1 : -1
        @current_fortnight_start += direction * FORTNIGHT_SECONDS
      end

      Span.new(@current_fortnight_start, @current_fortnight_start + FORTNIGHT_SECONDS)
    end

    def this(pointer = :future)
      super

      pointer = :future if pointer == :none

      case pointer
      when :future
        this_fortnight_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour) + RepeaterHour::HOUR_SECONDS
        sunday_repeater = RepeaterDayName.new(:sunday)
        sunday_repeater.start = @now
        sunday_repeater.this(:future)
        this_sunday_span = sunday_repeater.this(:future)
        this_fortnight_end = this_sunday_span.begin
        Span.new(this_fortnight_start, this_fortnight_end)
      when :past
        this_fortnight_end = Chronic.construct(@now.year, @now.month, @now.day, @now.hour)
        sunday_repeater = RepeaterDayName.new(:sunday)
        sunday_repeater.start = @now
        last_sunday_span = sunday_repeater.next(:past)
        this_fortnight_start = last_sunday_span.begin
        Span.new(this_fortnight_start, this_fortnight_end)
      end
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      span + direction * amount * FORTNIGHT_SECONDS
    end

    def width
      FORTNIGHT_SECONDS
    end

    def to_s
      (super + '-fortnight')
    end
  end
end
#
module Chronic
  class RepeaterWeek < Repeater #:nodoc:
    WEEK_SECONDS = 604800 # (7 * 24 * 60 * 60)

    def initialize(type, options = {})
      super
      @current_week_start = nil
    end

    def next(pointer)
      super

      unless @current_week_start
        case pointer
        when :future
          sunday_repeater = RepeaterDayName.new(:sunday)
          sunday_repeater.start = @now
          next_sunday_span = sunday_repeater.next(:future)
          @current_week_start = next_sunday_span.begin
        when :past
          sunday_repeater = RepeaterDayName.new(:sunday)
          sunday_repeater.start = (@now + RepeaterDay::DAY_SECONDS)
          sunday_repeater.next(:past)
          last_sunday_span = sunday_repeater.next(:past)
          @current_week_start = last_sunday_span.begin
        end
      else
        direction = pointer == :future ? 1 : -1
        @current_week_start += direction * WEEK_SECONDS
      end

      Span.new(@current_week_start, @current_week_start + WEEK_SECONDS)
    end

    def this(pointer = :future)
      super

      case pointer
      when :future
        this_week_start = Chronic.time_class.local(@now.year, @now.month, @now.day, @now.hour) + RepeaterHour::HOUR_SECONDS
        sunday_repeater = RepeaterDayName.new(:sunday)
        sunday_repeater.start = @now
        this_sunday_span = sunday_repeater.this(:future)
        this_week_end = this_sunday_span.begin
        Span.new(this_week_start, this_week_end)
      when :past
        this_week_end = Chronic.time_class.local(@now.year, @now.month, @now.day, @now.hour)
        sunday_repeater = RepeaterDayName.new(:sunday)
        sunday_repeater.start = @now
        last_sunday_span = sunday_repeater.next(:past)
        this_week_start = last_sunday_span.begin
        Span.new(this_week_start, this_week_end)
      when :none
        sunday_repeater = RepeaterDayName.new(:sunday)
        sunday_repeater.start = @now
        last_sunday_span = sunday_repeater.next(:past)
        this_week_start = last_sunday_span.begin
        Span.new(this_week_start, this_week_start + WEEK_SECONDS)
      end
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      span + direction * amount * WEEK_SECONDS
    end

    def width
      WEEK_SECONDS
    end

    def to_s
      (super + '-week')
    end
  end
end
#
module Chronic
  class RepeaterWeekend < Repeater #:nodoc:
    WEEKEND_SECONDS = 172_800 # (2 * 24 * 60 * 60)

    def initialize(type, options = {})
      super
      @current_week_start = nil
    end

    def next(pointer)
      super

      unless @current_week_start
        case pointer
        when :future
          saturday_repeater = RepeaterDayName.new(:saturday)
          saturday_repeater.start = @now
          next_saturday_span = saturday_repeater.next(:future)
          @current_week_start = next_saturday_span.begin
        when :past
          saturday_repeater = RepeaterDayName.new(:saturday)
          saturday_repeater.start = (@now + RepeaterDay::DAY_SECONDS)
          last_saturday_span = saturday_repeater.next(:past)
          @current_week_start = last_saturday_span.begin
        end
      else
        direction = pointer == :future ? 1 : -1
        @current_week_start += direction * RepeaterWeek::WEEK_SECONDS
      end

      Span.new(@current_week_start, @current_week_start + WEEKEND_SECONDS)
    end

    def this(pointer = :future)
      super

      case pointer
      when :future, :none
        saturday_repeater = RepeaterDayName.new(:saturday)
        saturday_repeater.start = @now
        this_saturday_span = saturday_repeater.this(:future)
        Span.new(this_saturday_span.begin, this_saturday_span.begin + WEEKEND_SECONDS)
      when :past
        saturday_repeater = RepeaterDayName.new(:saturday)
        saturday_repeater.start = @now
        last_saturday_span = saturday_repeater.this(:past)
        Span.new(last_saturday_span.begin, last_saturday_span.begin + WEEKEND_SECONDS)
      end
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      weekend = RepeaterWeekend.new(:weekend)
      weekend.start = span.begin
      start = weekend.next(pointer).begin + (amount - 1) * direction * RepeaterWeek::WEEK_SECONDS
      Span.new(start, start + (span.end - span.begin))
    end

    def width
      WEEKEND_SECONDS
    end

    def to_s
      (super + '-weekend')
    end
  end
end
#
module Chronic
  class RepeaterWeekday < Repeater #:nodoc:
    DAY_SECONDS = 86400 # (24 * 60 * 60)
    DAYS = {
      :sunday => 0,
      :monday => 1,
      :tuesday => 2,
      :wednesday => 3,
      :thursday => 4,
      :friday => 5,
      :saturday => 6
    }

    def initialize(type, options = {})
      super
      @current_weekday_start = nil
    end

    def next(pointer)
      super

      direction = pointer == :future ? 1 : -1

      unless @current_weekday_start
        @current_weekday_start = Chronic.construct(@now.year, @now.month, @now.day)
        @current_weekday_start += direction * DAY_SECONDS

        until is_weekday?(@current_weekday_start.wday)
          @current_weekday_start += direction * DAY_SECONDS
        end
      else
        loop do
          @current_weekday_start += direction * DAY_SECONDS
          break if is_weekday?(@current_weekday_start.wday)
        end
      end

      Span.new(@current_weekday_start, @current_weekday_start + DAY_SECONDS)
    end

    def this(pointer = :future)
      super

      case pointer
      when :past
        self.next(:past)
      when :future, :none
        self.next(:future)
      end
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1

      num_weekdays_passed = 0; offset = 0
      until num_weekdays_passed == amount
        offset += direction * DAY_SECONDS
        num_weekdays_passed += 1 if is_weekday?((span.begin+offset).wday)
      end

      span + offset
    end

    def width
      DAY_SECONDS
    end

    def to_s
      (super + '-weekday')
    end

    private

    def is_weekend?(day)
      day == symbol_to_number(:saturday) || day == symbol_to_number(:sunday)
    end

    def is_weekday?(day)
      !is_weekend?(day)
    end

    def symbol_to_number(sym)
      DAYS[sym] || raise("Invalid symbol specified")
    end
  end
end
#
module Chronic
  class RepeaterDay < Repeater #:nodoc:
    DAY_SECONDS = 86_400 # (24 * 60 * 60)

    def initialize(type, options = {})
      super
      @current_day_start = nil
    end

    def next(pointer)
      super

      unless @current_day_start
        @current_day_start = Chronic.time_class.local(@now.year, @now.month, @now.day)
      end

      direction = pointer == :future ? 1 : -1
      @current_day_start += direction * DAY_SECONDS

      Span.new(@current_day_start, @current_day_start + DAY_SECONDS)
    end

    def this(pointer = :future)
      super

      case pointer
      when :future
        day_begin = Chronic.construct(@now.year, @now.month, @now.day, @now.hour)
        day_end = Chronic.construct(@now.year, @now.month, @now.day) + DAY_SECONDS
      when :past
        day_begin = Chronic.construct(@now.year, @now.month, @now.day)
        day_end = Chronic.construct(@now.year, @now.month, @now.day, @now.hour)
      when :none
        day_begin = Chronic.construct(@now.year, @now.month, @now.day)
        day_end = Chronic.construct(@now.year, @now.month, @now.day) + DAY_SECONDS
      end

      Span.new(day_begin, day_end)
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      span + direction * amount * DAY_SECONDS
    end

    def width
      DAY_SECONDS
    end

    def to_s
      (super + '-day')
    end
  end
end
#
module Chronic
  class RepeaterDayName < Repeater #:nodoc:
    DAY_SECONDS = 86400 # (24 * 60 * 60)

    def initialize(type, options = {})
      super
      @current_date = nil
    end

    def next(pointer)
      super

      direction = pointer == :future ? 1 : -1

      unless @current_date
        @current_date = ::Date.new(@now.year, @now.month, @now.day)
        @current_date += direction

        day_num = symbol_to_number(@type)

        while @current_date.wday != day_num
          @current_date += direction
        end
      else
        @current_date += direction * 7
      end
      next_date = @current_date.succ
      Span.new(Chronic.construct(@current_date.year, @current_date.month, @current_date.day), Chronic.construct(next_date.year, next_date.month, next_date.day))
    end

    def this(pointer = :future)
      super

      pointer = :future if pointer == :none
      self.next(pointer)
    end

    def width
      DAY_SECONDS
    end

    def to_s
      (super + '-dayname-' + @type.to_s)
    end

    private

    def symbol_to_number(sym)
      lookup = {:sunday => 0, :monday => 1, :tuesday => 2, :wednesday => 3, :thursday => 4, :friday => 5, :saturday => 6}
      lookup[sym] || raise("Invalid symbol specified")
    end
  end
end
#
module Chronic
  class RepeaterDayPortion < Repeater #:nodoc:
    PORTIONS = {
      :am => 0..(12 * 60 * 60 - 1),
      :pm => (12 * 60 * 60)..(24 * 60 * 60 - 1),
      :morning => (6 * 60 * 60)..(12 * 60 * 60),    # 6am-12am,
      :afternoon => (13 * 60 * 60)..(17 * 60 * 60), # 1pm-5pm,
      :evening => (17 * 60 * 60)..(20 * 60 * 60),   # 5pm-8pm,
      :night => (20 * 60 * 60)..(24 * 60 * 60),     # 8pm-12pm
    }

    def initialize(type, options = {})
      super
      @current_span = nil

      if type.kind_of? Integer
        @range = (@type * 60 * 60)..((@type + 12) * 60 * 60)
      else
        @range = PORTIONS[type]
        @range || raise("Invalid type '#{type}' for RepeaterDayPortion")
      end

      @range || raise("Range should have been set by now")
    end

    def next(pointer)
      super

      unless @current_span
        now_seconds = @now - Chronic.construct(@now.year, @now.month, @now.day)
        if now_seconds < @range.begin
          case pointer
          when :future
            range_start = Chronic.construct(@now.year, @now.month, @now.day) + @range.begin
          when :past
            range_start = Chronic.construct(@now.year, @now.month, @now.day - 1) + @range.begin
          end
        elsif now_seconds > @range.end
          case pointer
          when :future
            range_start = Chronic.construct(@now.year, @now.month, @now.day + 1) + @range.begin
          when :past
            range_start = Chronic.construct(@now.year, @now.month, @now.day) + @range.begin
          end
        else
          case pointer
          when :future
            range_start = Chronic.construct(@now.year, @now.month, @now.day + 1) + @range.begin
          when :past
            range_start = Chronic.construct(@now.year, @now.month, @now.day - 1) + @range.begin
          end
        end
        offset = (@range.end - @range.begin)
        range_end = construct_date_from_reference_and_offset(range_start, offset)
        @current_span = Span.new(range_start, range_end)
      else
        days_to_shift_window =
        case pointer
        when :future
          1
        when :past
          -1
        end

        new_begin = Chronic.construct(@current_span.begin.year, @current_span.begin.month, @current_span.begin.day + days_to_shift_window, @current_span.begin.hour, @current_span.begin.min, @current_span.begin.sec)
        new_end = Chronic.construct(@current_span.end.year, @current_span.end.month, @current_span.end.day + days_to_shift_window, @current_span.end.hour, @current_span.end.min, @current_span.end.sec)
        @current_span = Span.new(new_begin, new_end)
      end
    end

    def this(context = :future)
      super

      range_start = Chronic.construct(@now.year, @now.month, @now.day) + @range.begin
      range_end = construct_date_from_reference_and_offset(range_start)
      @current_span = Span.new(range_start, range_end)
    end

    def offset(span, amount, pointer)
      @now = span.begin
      portion_span = self.next(pointer)
      direction = pointer == :future ? 1 : -1
      portion_span + (direction * (amount - 1) * RepeaterDay::DAY_SECONDS)
    end

    def width
      @range || raise("Range has not been set")
      return @current_span.width if @current_span
      if @type.kind_of? Integer
        return (12 * 60 * 60)
      else
        @range.end - @range.begin
      end
    end

    def to_s
      (super + '-dayportion-' + @type.to_s)
    end

    private
    def construct_date_from_reference_and_offset(reference, offset = nil)
      elapsed_seconds_for_range = offset || (@range.end - @range.begin)
      second_hand = ((elapsed_seconds_for_range - (12 * 60))) % 60
      minute_hand = (elapsed_seconds_for_range - second_hand) / (60) % 60
      hour_hand = (elapsed_seconds_for_range - minute_hand - second_hand) / (60 * 60) + reference.hour % 24
      Chronic.construct(reference.year, reference.month, reference.day, hour_hand, minute_hand, second_hand)
    end
  end
end
#
module Chronic
  class RepeaterHour < Repeater #:nodoc:
    HOUR_SECONDS = 3600 # 60 * 60

    def initialize(type, options = {})
      super
      @current_hour_start = nil
    end

    def next(pointer)
      super

      unless @current_hour_start
        case pointer
        when :future
          @current_hour_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour + 1)
        when :past
          @current_hour_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour - 1)
        end
      else
        direction = pointer == :future ? 1 : -1
        @current_hour_start += direction * HOUR_SECONDS
      end

      Span.new(@current_hour_start, @current_hour_start + HOUR_SECONDS)
    end

    def this(pointer = :future)
      super

      case pointer
      when :future
        hour_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min + 1)
        hour_end = Chronic.construct(@now.year, @now.month, @now.day, @now.hour + 1)
      when :past
        hour_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour)
        hour_end = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min)
      when :none
        hour_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour)
        hour_end = hour_start + HOUR_SECONDS
      end

      Span.new(hour_start, hour_end)
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      span + direction * amount * HOUR_SECONDS
    end

    def width
      HOUR_SECONDS
    end

    def to_s
      (super + '-hour')
    end
  end
end
#
module Chronic
  class RepeaterMinute < Repeater #:nodoc:
    MINUTE_SECONDS = 60

    def initialize(type, options = {})
      super
      @current_minute_start = nil
    end

    def next(pointer = :future)
      super

      unless @current_minute_start
        case pointer
        when :future
          @current_minute_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min + 1)
        when :past
          @current_minute_start = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min - 1)
        end
      else
        direction = pointer == :future ? 1 : -1
        @current_minute_start += direction * MINUTE_SECONDS
      end

      Span.new(@current_minute_start, @current_minute_start + MINUTE_SECONDS)
    end

    def this(pointer = :future)
      super

      case pointer
      when :future
        minute_begin = @now
        minute_end = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min)
      when :past
        minute_begin = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min)
        minute_end = @now
      when :none
        minute_begin = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min)
        minute_end = Chronic.construct(@now.year, @now.month, @now.day, @now.hour, @now.min) + MINUTE_SECONDS
      end

      Span.new(minute_begin, minute_end)
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      span + direction * amount * MINUTE_SECONDS
    end

    def width
      MINUTE_SECONDS
    end

    def to_s
      (super + '-minute')
    end
  end
end
#
module Chronic
  class RepeaterSecond < Repeater #:nodoc:
    SECOND_SECONDS = 1 # haha, awesome

    def initialize(type, options = {})
      super
      @second_start = nil
    end

    def next(pointer = :future)
      super

      direction = pointer == :future ? 1 : -1

      unless @second_start
        @second_start = @now + (direction * SECOND_SECONDS)
      else
        @second_start += SECOND_SECONDS * direction
      end

      Span.new(@second_start, @second_start + SECOND_SECONDS)
    end

    def this(pointer = :future)
      super

      Span.new(@now, @now + 1)
    end

    def offset(span, amount, pointer)
      direction = pointer == :future ? 1 : -1
      span + direction * amount * SECOND_SECONDS
    end

    def width
      SECOND_SECONDS
    end

    def to_s
      (super + '-second')
    end
  end
end
#
module Chronic
  class RepeaterTime < Repeater #:nodoc:
    class Tick #:nodoc:
      attr_accessor :time

      def initialize(time, ambiguous = false)
        @time = time
        @ambiguous = ambiguous
      end

      def ambiguous?
        @ambiguous
      end

      def *(other)
        Tick.new(@time * other, @ambiguous)
      end

      def to_f
        @time.to_f
      end

      def to_s
        @time.to_s + (@ambiguous ? '?' : '')
      end

    end

    def initialize(time, options = {})
      @current_time = nil
      @options = options
      time_parts = time.split(':')
      raise ArgumentError, "Time cannot have more than 4 groups of ':'" if time_parts.count > 4

      if time_parts.first.length > 2 and time_parts.count == 1
        if time_parts.first.length > 4
          second_index = time_parts.first.length - 2
          time_parts.insert(1, time_parts.first[second_index..time_parts.first.length])
          time_parts[0] = time_parts.first[0..second_index - 1]
        end
        minute_index = time_parts.first.length - 2
        time_parts.insert(1, time_parts.first[minute_index..time_parts.first.length])
        time_parts[0] = time_parts.first[0..minute_index - 1]
      end

      ambiguous = false
      hours = time_parts.first.to_i

      if @options[:hours24].nil? or (not @options[:hours24].nil? and @options[:hours24] != true)
          ambiguous = true if (time_parts.first.length == 1 and hours > 0) or (hours >= 10 and hours <= 12) or (@options[:hours24] == false and hours > 0)
          hours = 0 if hours == 12 and ambiguous
      end

      hours *= 60 * 60
      minutes = 0
      seconds = 0
      subseconds = 0

      minutes = time_parts[1].to_i * 60 if time_parts.count > 1
      seconds = time_parts[2].to_i if time_parts.count > 2
      subseconds = time_parts[3].to_f / (10 ** time_parts[3].length) if time_parts.count > 3

      @type = Tick.new(hours + minutes + seconds + subseconds, ambiguous)
    end

    # Return the next past or future Span for the time that this Repeater represents
    #   pointer - Symbol representing which temporal direction to fetch the next day
    #             must be either :past or :future
    def next(pointer)
      super

      half_day = 60 * 60 * 12
      full_day = 60 * 60 * 24

      first = false

      unless @current_time
        first = true
        midnight = Chronic.time_class.local(@now.year, @now.month, @now.day)

        yesterday_midnight = midnight - full_day
        tomorrow_midnight = midnight + full_day

        offset_fix = midnight.gmt_offset - tomorrow_midnight.gmt_offset
        tomorrow_midnight += offset_fix

        catch :done do
          if pointer == :future
            if @type.ambiguous?
              [midnight + @type.time + offset_fix, midnight + half_day + @type.time + offset_fix, tomorrow_midnight + @type.time].each do |t|
                (@current_time = t; throw :done) if t >= @now
              end
            else
              [midnight + @type.time + offset_fix, tomorrow_midnight + @type.time].each do |t|
                (@current_time = t; throw :done) if t >= @now
              end
            end
          else # pointer == :past
            if @type.ambiguous?
              [midnight + half_day + @type.time + offset_fix, midnight + @type.time + offset_fix, yesterday_midnight + @type.time + half_day].each do |t|
                (@current_time = t; throw :done) if t <= @now
              end
            else
              [midnight + @type.time + offset_fix, yesterday_midnight + @type.time].each do |t|
                (@current_time = t; throw :done) if t <= @now
              end
            end
          end
        end

        @current_time || raise("Current time cannot be nil at this point")
      end

      unless first
        increment = @type.ambiguous? ? half_day : full_day
        @current_time += pointer == :future ? increment : -increment
      end

      Span.new(@current_time, @current_time + width)
    end

    def this(context = :future)
      super

      context = :future if context == :none

      self.next(context)
    end

    def width
      1
    end

    def to_s
      (super + '-time-' + @type.to_s)
    end
  end
end
#

# Parse natural language dates and times into Time or Chronic::Span objects.
#
# Examples:
#
#   require 'chronic'
#
#   Time.now   #=> Sun Aug 27 23:18:25 PDT 2006
#
#   Chronic.parse('tomorrow')
#     #=> Mon Aug 28 12:00:00 PDT 2006
#
#   Chronic.parse('monday', :context => :past)
#     #=> Mon Aug 21 12:00:00 PDT 2006
module Chronic
  VERSION = "0.10.2"

  class << self

    # Returns true when debug mode is enabled.
    attr_accessor :debug

    # Examples:
    #
    #   require 'chronic'
    #   require 'active_support/time'
    #
    #   Time.zone = 'UTC'
    #   Chronic.time_class = Time.zone
    #   Chronic.parse('June 15 2006 at 5:54 AM')
    #     # => Thu, 15 Jun 2006 05:45:00 UTC +00:00
    #
    # Returns The Time class Chronic uses internally.
    attr_accessor :time_class
  end

  self.debug = false
  self.time_class = ::Time


  # Parses a string containing a natural language date or time.
  #
  # If the parser can find a date or time, either a Time or Chronic::Span
  # will be returned (depending on the value of `:guess`). If no
  # date or time can be found, `nil` will be returned.
  #
  # text - The String text to parse.
  # opts - An optional Hash of configuration options passed to Parser::new.
  def self.parse(text, options = {})
    Parser.new(options).parse(text)
  end

  # Construct a new time object determining possible month overflows
  # and leap years.
  #
  # year   - Integer year.
  # month  - Integer month.
  # day    - Integer day.
  # hour   - Integer hour.
  # minute - Integer minute.
  # second - Integer second.
  #
  # Returns a new Time object constructed from these params.
  def self.construct(year, month = 1, day = 1, hour = 0, minute = 0, second = 0, offset = nil)
    if second >= 60
      minute += second / 60
      second = second % 60
    end

    if minute >= 60
      hour += minute / 60
      minute = minute % 60
    end

    if hour >= 24
      day += hour / 24
      hour = hour % 24
    end

    # determine if there is a day overflow. this is complicated by our crappy calendar
    # system (non-constant number of days per month)
    day <= 56 || raise("day must be no more than 56 (makes month resolution easier)")
    if day > 28 # no month ever has fewer than 28 days, so only do this if necessary
      days_this_month = ::Date.leap?(year) ? Date::MONTH_DAYS_LEAP[month] : Date::MONTH_DAYS[month]
      if day > days_this_month
        month += day / days_this_month
        day = day % days_this_month
      end
    end

    if month > 12
      if month % 12 == 0
        year += (month - 12) / 12
        month = 12
      else
        year += month / 12
        month = month % 12
      end
    end
    if Chronic.time_class.name == "Date"
      Chronic.time_class.new(year, month, day)
    elsif not Chronic.time_class.respond_to?(:new) or (RUBY_VERSION.to_f < 1.9 and Chronic.time_class.name == "Time")
      Chronic.time_class.local(year, month, day, hour, minute, second)
    else
      offset = Time::normalize_offset(offset) if Chronic.time_class.name == "DateTime"
      Chronic.time_class.new(year, month, day, hour, minute, second, offset)
    end
  end

end
