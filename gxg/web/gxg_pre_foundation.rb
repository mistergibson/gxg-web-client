module GxG
    module Gui
        # ### Core Component Classes & Registration System
        class Abbreviation < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :abbr
                  @options[:title] = @title.clone.to_s
            end
        end
        #
        class Address < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :address
            end
        end
        #
        class Area < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :area
            end
        end
        #
        class Bold < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :b
            end
        end
        #
        class Bdi < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :bdi
            end
        end
        #
        class Bdo < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :bdo
            end
        end
        #
        class BlockQuote < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :blockquote
            end
        end
        #
        class Break < GxG::Gui::Vdom::BaseElement
            # Review has no closing tag - account for this in Factory
            def _before_create
                  super()
                  @domtype = :br
            end
        end
        #
        class Caption < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :caption
            end
        end
        #
        class Cite < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :cite
            end
        end
        #
        class Code < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :code
            end
        end
        #
        class Column < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :col
            end
        end
        #
        class ColumnGroup < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :colgroup
            end
        end
        #
        class Data < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :data
            end
        end
        #
        class DataList < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :datalist
            end
        end
        #
        class Description < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :dd
            end
        end
        #
        class Deleted < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :del
            end
        end
        #
        class Details < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :details
            end
        end
        #
        class Dfn < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :dfn
            end
        end
        #
        class Dialog < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :dialog
            end
        end
        #
        class Division < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :div
            end
        end
        #
        class DescriptionList < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :dl
            end
        end
        #
        class DescriptionTerm < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :dt
            end
        end
        #
        class Emphasis < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :em
            end
        end
        #
        class Embed < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :embed
            end
        end
        #
        class Figure < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :figure
            end
        end
        #
        class FigureCaption < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :figcaption
            end
        end
        #
        class ThemeDivider < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :hr
            end
        end
        #
        class Italic < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :i
            end
        end
        #
        class InlineFrame < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :iframe
            end
        end
        #
        class Insertion < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :ins
            end
        end
        #
        class KeyboardKey < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :kbd
            end
        end
        #
        class Map < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :map
            end
        end
        #
        class Mark < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :mark
            end
        end
        #
        class Meter < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :meter
            end
        end
        #
        class NoScript < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :noscript
            end
        end
        #
        class Object < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :object
            end
        end
        #
        class OptionGroup < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :optgroup
            end
        end
        #
        class Parameter < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :param
            end
        end
        #
        class Picture < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :picture
            end
        end
        #
        class Preformatted < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :pre
            end
        end
        #
        class Progress < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :progress
            end
        end
        #
        class Quotation < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :q
            end
        end
        #
        class StrikeThrough < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :s
            end
        end
        #
        class Sample < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :samp
            end
        end
        #
        class Source < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :source
            end
        end
        #
        class Strong < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :strong
            end
        end
        #
        class Small < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :small
            end
        end
        #
        class Style < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :style
            end
        end
        #
        class SubScript < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :sub
            end
        end
        #
        class Summary < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :summary
            end
        end
        #
        class SuperScript < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :sup
            end
        end
        #
        class Svg < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :svg
            end
        end
        #
        class Template < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :template
            end
        end
        #
        class Time < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :time
            end
        end
        #
        class Track < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :track
            end
        end
        #
        class Misspelled < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :u
            end
        end
        #
        class Variable < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :var
            end
        end
        #
        class WordBreak < GxG::Gui::Vdom::BaseElement
            def _before_create
                  super()
                  @domtype = :wbr
            end
        end
        #
        class Header < GxG::Gui::Vdom::BaseElement
          def _before_create
                super()
                @domtype = :header
          end
        end
        #
        class Navigation < GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :nav
            end
        end
        #
        class Main < GxG::Gui::Vdom::BaseElement
          def _before_create
                super()
                @domtype = :main
          end
        end
        #
        class Section < GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :section
            end
        end
        #
        class Article < GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :article
            end
        end
        #
        class Aside < GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :aside
            end
        end
        #
        class Footer < GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :footer
            end
        end
        #
        class Form < GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
            end
            #
            def form_data()
               result = {}
               search_queue = self.children.values
               while search_queue.size > 0 do
                   entry = search_queue.shift
                   if entry
                       if entry.domtype == :input
                           result[(entry.title.to_s.to_sym)] = entry.value()
                       else
                           entry.children.values.each do |the_child|
                               search_queue << the_child
                           end
                       end
                   end
               end
               result
            end
        end
        # ### Buttons
        class ButtonInput < ::GxG::Gui::Vdom::BaseClickableElement
            def _before_create
                super()
                @options[:type] = :button
            end
        end
        #
        class SubmitButton < ::GxG::Gui::Vdom::BaseClickableElement
            def _before_create
                super()
                @options[:type] = :submit
            end
        end
        #
        class Block < ::GxG::Gui::Vdom::BaseClickableElement
            def _before_create
                super()
                @domtype = :div
                @options.delete(:type)
                true
            end
        end
        #
        class CheckBox < ::GxG::Gui::Vdom::BaseClickableElement
            def _before_create
                super()
                @options[:type] = :checkbox
            end
        end
        #
        class Image < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :image
                if @options[:source]
                    @options[:src] = @options.delete(:source)
                end
                @options[:alt] ||= @options[:src]
            end
        end
        #
        class Video < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :video
                if @options[:source]
                    @options[:src] = @options.delete(:source)
                end
            end
        end
        #
        class Audio < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :audio
                if @options[:source]
                    @options[:src] = @options.delete(:source)
                end
            end
        end
        #
        class Canvas < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :canvas
                if @options[:source]
                    @options[:src] = @options.delete(:source)
                end
            end
        end
        #
        class HiddenInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :hidden
            end
        end
        #
        class FileInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :file
            end
        end
        #
        class TextInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :text
            end
        end
        #
        class PasswordInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :password
            end
        end
        #
        class ResetInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :reset
            end
        end
        #
        class RadioButton < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :radio
            end
        end
        #
        class ColorPicker < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :color
            end
        end
        #
        class DatePicker < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :date
            end
        end
        #
        class DateTimeLocal < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :"datetime-local"
            end
        end
        #
        class EmailInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :email
            end
        end
        #
        class MonthPicker < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :month
            end
        end
        #
        class NumberInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :number
            end
        end
        #
        class RangeInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :range
            end
        end
        #
        class SearchInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :search
            end
        end
        #
        class PhoneInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :tel
            end
        end
        #
        class TimePicker < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :time
            end
        end
        #
        class UrlInput < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :url
            end
        end
        #
        class WeekPicker < ::GxG::Gui::Vdom::BaseInputElement
            def _before_create
                super()
                @options[:type] = :week
            end
        end
        #
        class Label < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :label
            end
        end
        #
        class TextArea < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :textarea
            end
        end
        #
        class Output < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :output
            end
        end
        #
        class Paragraph < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :p
            end
        end
        #
        class Header1 < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :h1
            end
        end
        #
        class Header2 < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :h2
            end
        end
        #
        class Header3 < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :h3
            end
        end
        #
        class Header4 < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :h4
            end
        end
        #
        class Header5 < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :h5
            end
        end
        #
        class Header6 < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :h6
            end
        end
        #
        class List < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
            end
        end
        #
        class OrderedList < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ol
            end
        end
        #
        class ListItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
        end
        #
        class Anchor < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :a
            end
        end
        #
        class ExternalLink < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                # When link is clicked will navigate to a location outside the
                # application and in a new tab.
                # Specify option :target to set the location.
                @options[:target] ||= "_blank"
                @domtype = :a
            end
        end
        #
        class Button < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :button
                unless @options[:type] == "button"
                    @options[:type] = "button"
                end
                unless @states[:button] == true
                    @states[:button] = true
                end
            end
            #
            def _after_create
                super()
                # Review : consider a non-gxg listener for un-focusing the active element. thus:
                #`{@element}.addEventListener("click",function(e){#{clicked};document.activeElement.blur()})`
                on(:click) do |the_event|
                    `document.activeElement.blur()`
                end
            end
        end
        #
        class Table < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :table
            end
        end
        #
        class TableHeader < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :th
            end
        end
        #
        class TableRow < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :tr
            end
        end
        #
        class TableCell < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :td
            end
        end
        #
        class BlockTable < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:table] == true
                    @states[:table] = true
                end
            end
        end
        #
        class BlockTableHeader < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:th] == true
                    @states[:th] = true
                end
            end
        end
        #
        class BlockTableRow < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:tr] == true
                    @states[:tr] = true
                end
            end
        end
        #
        class BlockTableCell < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:td] == true
                    @states[:td] = true
                end
            end
        end
        #
        class Span < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :span
            end
        end
        #
        class Select < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :select
            end
        end
        #
        class Option < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :option
            end
        end
        #
        class FieldSet < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :fieldset
                unless @states[:fieldset] == true
                    @states[:fieldset] = true
                end
            end
        end
        #
        class Legend < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :legend
            end
        end
        #
        # ### Component Registration
        COMPONENT_CLASSES = {
            :abbreviation => ::GxG::Gui::Abbreviation,
            :address => ::GxG::Gui::Address,
            :area => ::GxG::Gui::Area,
            :bold => ::GxG::Gui::Bold,
            :bdi => ::GxG::Gui::Bdi,
            :bdo => ::GxG::Gui::Bdo,
            :blockquote => ::GxG::Gui::BlockQuote,
            :break => ::GxG::Gui::Break,
            :caption => ::GxG::Gui::Caption,
            :cite => ::GxG::Gui::Cite,
            :code => ::GxG::Gui::Code,
            :column => ::GxG::Gui::Column,
            :column_group => ::GxG::Gui::ColumnGroup,
            :data => ::GxG::Gui::Data,
            :datalist => ::GxG::Gui::DataList,
            :description => ::GxG::Gui::Description,
            :deleted => ::GxG::Gui::Deleted,
            :details => ::GxG::Gui::Details,
            :dfn => ::GxG::Gui::Dfn,
            :dialog => ::GxG::Gui::Dialog,
            :division => ::GxG::Gui::Division,
            :description_list => ::GxG::Gui::DescriptionList,
            :description_term => ::GxG::Gui::DescriptionTerm,
            :emphasis => ::GxG::Gui::Emphasis,
            :embed => ::GxG::Gui::Embed,
            :figure => ::GxG::Gui::Figure,
            :figure_caption => ::GxG::Gui::FigureCaption,
            :theme_divider => ::GxG::Gui::ThemeDivider,
            :italic => ::GxG::Gui::Italic,
            :inline_frame => ::GxG::Gui::InlineFrame,
            :Insertion => ::GxG::Gui::Insertion,
            :keyboard_key => ::GxG::Gui::KeyboardKey,
            :map => ::GxG::Gui::Map,
            :mark => ::GxG::Gui::Mark,
            :meter => ::GxG::Gui::Meter,
            :noscript => ::GxG::Gui::NoScript,
            :object => ::GxG::Gui::Object,
            :option_group => ::GxG::Gui::OptionGroup,
            :parameter => ::GxG::Gui::Parameter,
            :picture => ::GxG::Gui::Picture,
            :preformatted => ::GxG::Gui::Preformatted,
            :progress => ::GxG::Gui::Progress,
            :quotation => ::GxG::Gui::Quotation,
            :strike_through => ::GxG::Gui::StrikeThrough,
            :sample => ::GxG::Gui::Sample,
            :section => ::GxG::Gui::Section,
            :small => ::GxG::Gui::Small,
            :source => ::GxG::Gui::Source,
            :strong => ::GxG::Gui::Strong,
            :style => ::GxG::Gui::Style,
            :sub_script => ::GxG::Gui::SubScript,
            :summary => ::GxG::Gui::Summary,
            :super_script => ::GxG::Gui::SuperScript,
            :svg => ::GxG::Gui::Svg,
            :template => ::GxG::Gui::Template,
            :text_area => ::GxG::Gui::TextArea,
            :time => ::GxG::Gui::Time,
            :track => ::GxG::Gui::Track,
            :misspelled => ::GxG::Gui::Misspelled,
            :variable => ::GxG::Gui::Variable,
            :word_break => ::GxG::Gui::WordBreak,
            :header => ::GxG::Gui::Header,
            :navigation => ::GxG::Gui::Navigation,
            :main => ::GxG::Gui::Main,
            :article => ::GxG::Gui::Article,
            :aside => ::GxG::Gui::Aside,
            :footer => ::GxG::Gui::Footer,
            :form => ::GxG::Gui::Form,
            :button_input => ::GxG::Gui::ButtonInput,
            :submit_button => ::GxG::Gui::SubmitButton,
            :block => ::GxG::Gui::Block,
            :checkbox => ::GxG::Gui::CheckBox,
            :image => ::GxG::Gui::Image,
            :video => ::GxG::Gui::Video,
            :audio => ::GxG::Gui::Audio,
            :canvas => ::GxG::Gui::Canvas,
            :hidden => ::GxG::Gui::HiddenInput,
            :file_input => ::GxG::Gui::FileInput,
            :text_input => ::GxG::Gui::TextInput,
            :password_input => ::GxG::Gui::PasswordInput,
            :reset_input => ::GxG::Gui::ResetInput,
            :radio_button => ::GxG::Gui::RadioButton,
            :color_picker => ::GxG::Gui::ColorPicker,
            :date_picker => ::GxG::Gui::DatePicker,
            :datetime_local => ::GxG::Gui::DateTimeLocal,
            :email_input => ::GxG::Gui::EmailInput,
            :month_picker => ::GxG::Gui::MonthPicker,
            :number_input =>::GxG::Gui::NumberInput,
            :range_input => ::GxG::Gui::RangeInput,
            :search_input => ::GxG::Gui::SearchInput,
            :phone_input => ::GxG::Gui::PhoneInput,
            :time_picker => ::GxG::Gui::TimePicker,
            :url_input => ::GxG::Gui::UrlInput,
            :week_picker => ::GxG::Gui::WeekPicker,
            :label => ::GxG::Gui::Label,
            :output => ::GxG::Gui::Output,
            :paragraph => ::GxG::Gui::Paragraph,
            :header1 => ::GxG::Gui::Header1,
            :header2 => ::GxG::Gui::Header2,
            :header3 => ::GxG::Gui::Header3,
            :header4 => ::GxG::Gui::Header4,
            :header5 => ::GxG::Gui::Header5,
            :header6 => ::GxG::Gui::Header6,
            :list => ::GxG::Gui::List,
            :ordered_list => ::GxG::Gui::OrderedList,
            :list_item => ::GxG::Gui::ListItem,
            :anchor => ::GxG::Gui::Anchor,
            :external_link => ::GxG::Gui::ExternalLink,
            :button => ::GxG::Gui::Button,
            :table => ::GxG::Gui::Table,
            :table_header => ::GxG::Gui::TableHeader,
            :table_row => ::GxG::Gui::TableRow,
            :table_cell => ::GxG::Gui::TableCell,
            :block_table => ::GxG::Gui::BlockTable,
            :block_table_header => ::GxG::Gui::BlockTableHeader,
            :block_table_row => ::GxG::Gui::BlockTableRow,
            :block_table_cell => ::GxG::Gui::BlockTableCell,
            :span => ::GxG::Gui::Span,
            :select => ::GxG::Gui::Select,
            :option => ::GxG::Gui::Option,
            :field_set => ::GxG::Gui::FieldSet,
            :legend => ::GxG::Gui::Legend
        }
        #
        def self.component_class(the_type_specifier=nil)
            result = nil
            if the_type_specifier
                result = GxG::Gui::COMPONENT_CLASSES[(the_type_specifier.to_s.to_sym)]
            end
            result
        end
        #
        def self.class_component(the_class_specifier=nil)
            result = nil
            if the_class_specifier
                found_index = GxG::Gui::COMPONENT_CLASSES.values.index(the_class_specifier)
                if found_index
                    result = GxG::Gui::COMPONENT_CLASSES.keys[(found_index)]
                end
            end
            result
        end
        #
        def self.component_registered?(the_specifier=nil)
            if GxG::Gui::component_class(the_specifier)
                true
            else
                false
            end
        end
        #
        def self.register_component_class(the_specifier=nil, the_constant=nil)
            if the_specifier.is_any?(::String, ::Symbol) && the_constant.is_a?(::Class)
                if GxG::Gui::component_registered?(the_specifier.to_s.to_sym)
                    if GxG::Gui::component_class(the_specifier.to_s.to_sym) != the_constant
                        GxG::Gui::COMPONENT_CLASSES[(the_specifier.to_s.to_sym)] = the_constant
                        true
                    else
                        # Review : should re-defining component constants be allowed ??
                        log_warn("Component Class #{the_specifier.to_s.to_sym.inspect} => #{the_constant.inspect} already defined.")
                        false
                    end
                else
                    GxG::Gui::COMPONENT_CLASSES[(the_specifier.to_s.to_sym)] = the_constant
                    true
                end
            else
                false
            end
        end
        #
    end
    # End Gui
end
# End GxG
# ### Foundation Integration
module GxG
    module Gui
        # ### Foundation Component Classes
        # See : https://get.foundation/sites/docs/index.html
        #
    end
end