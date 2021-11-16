module GxG
    module Gui
        # ### Page Component
        class Page < GxG::Gui::Vdom::Page
        end
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
            :"org.gxg.gui.page" => ::GxG::Gui::Page,
            :"org.gxg.gui.abbreviation" => ::GxG::Gui::Abbreviation,
            :"org.gxg.gui.address" => ::GxG::Gui::Address,
            :"org.gxg.gui.area" => ::GxG::Gui::Area,
            :"org.gxg.gui.bold" => ::GxG::Gui::Bold,
            :"org.gxg.gui.bdi" => ::GxG::Gui::Bdi,
            :"org.gxg.gui.bdo" => ::GxG::Gui::Bdo,
            :"org.gxg.gui.blockquote" => ::GxG::Gui::BlockQuote,
            :"org.gxg.gui.break" => ::GxG::Gui::Break,
            :"org.gxg.gui.caption" => ::GxG::Gui::Caption,
            :"org.gxg.gui.cite" => ::GxG::Gui::Cite,
            :"org.gxg.gui.code" => ::GxG::Gui::Code,
            :"org.gxg.gui.column" => ::GxG::Gui::Column,
            :"org.gxg.gui.column.group" => ::GxG::Gui::ColumnGroup,
            :"org.gxg.gui.data" => ::GxG::Gui::Data,
            :"org.gxg.gui.data.list" => ::GxG::Gui::DataList,
            :"org.gxg.gui.description" => ::GxG::Gui::Description,
            :"org.gxg.gui.deleted" => ::GxG::Gui::Deleted,
            :"org.gxg.gui.details" => ::GxG::Gui::Details,
            :"org.gxg.gui.dfn" => ::GxG::Gui::Dfn,
            :"org.gxg.gui.dialog" => ::GxG::Gui::Dialog,
            :"org.gxg.gui.division" => ::GxG::Gui::Division,
            :"org.gxg.gui.description.list" => ::GxG::Gui::DescriptionList,
            :"org.gxg.gui.description.item" => ::GxG::Gui::DescriptionTerm,
            :"org.gxg.gui.emphasis" => ::GxG::Gui::Emphasis,
            :"org.gxg.gui.figure" => ::GxG::Gui::Figure,
            :"org.gxg.gui.figure.caption" => ::GxG::Gui::FigureCaption,
            :"org.gxg.gui.theme.divider" => ::GxG::Gui::ThemeDivider,
            :"org.gxg.gui.italic" => ::GxG::Gui::Italic,
            :"org.gxg.gui.frame.inline" => ::GxG::Gui::InlineFrame,
            :"org.gxg.gui.insertion" => ::GxG::Gui::Insertion,
            :"org.gxg.gui.keyboard.key" => ::GxG::Gui::KeyboardKey,
            :"org.gxg.gui.map" => ::GxG::Gui::Map,
            :"org.gxg.gui.mark" => ::GxG::Gui::Mark,
            :"org.gxg.gui.meter" => ::GxG::Gui::Meter,
            :"org.gxg.gui.noscript" => ::GxG::Gui::NoScript,
            :"org.gxg.gui.object" => ::GxG::Gui::Object,
            :"org.gxg.gui.option.group" => ::GxG::Gui::OptionGroup,
            :"org.gxg.gui.parameter" => ::GxG::Gui::Parameter,
            :"org.gxg.gui.picture" => ::GxG::Gui::Picture,
            :"org.gxg.gui.preformatted" => ::GxG::Gui::Preformatted,
            :"org.gxg.gui.progress" => ::GxG::Gui::Progress,
            :"org.gxg.gui.quotation" => ::GxG::Gui::Quotation,
            :"org.gxg.gui.strike.through" => ::GxG::Gui::StrikeThrough,
            :"org.gxg.gui.sample" => ::GxG::Gui::Sample,
            :"org.gxg.gui.section" => ::GxG::Gui::Section,
            :"org.gxg.gui.small" => ::GxG::Gui::Small,
            :"org.gxg.gui.source" => ::GxG::Gui::Source,
            :"org.gxg.gui.strong" => ::GxG::Gui::Strong,
            :"org.gxg.gui.style" => ::GxG::Gui::Style,
            :"org.gxg.gui.sub.script" => ::GxG::Gui::SubScript,
            :"org.gxg.gui.summary" => ::GxG::Gui::Summary,
            :"org.gxg.gui.super.script" => ::GxG::Gui::SuperScript,
            :"org.gxg.gui.svg" => ::GxG::Gui::Svg,
            :"org.gxg.gui.template" => ::GxG::Gui::Template,
            :"org.gxg.gui.text.area" => ::GxG::Gui::TextArea,
            :"org.gxg.gui.time" => ::GxG::Gui::Time,
            :"org.gxg.gui.track" => ::GxG::Gui::Track,
            :"org.gxg.gui.misspelled" => ::GxG::Gui::Misspelled,
            :"org.gxg.gui.variable" => ::GxG::Gui::Variable,
            :"org.gxg.gui.word.break" => ::GxG::Gui::WordBreak,
            :"org.gxg.gui.header" => ::GxG::Gui::Header,
            :"org.gxg.gui.navigator" => ::GxG::Gui::Navigation,
            :"org.gxg.gui.main" => ::GxG::Gui::Main,
            :"org.gxg.gui.article" => ::GxG::Gui::Article,
            :"org.gxg.gui.aside" => ::GxG::Gui::Aside,
            :"org.gxg.gui.footer" => ::GxG::Gui::Footer,
            :"org.gxg.gui.form" => ::GxG::Gui::Form,
            :"org.gxg.gui.input.button" => ::GxG::Gui::ButtonInput,
            :"org.gxg.gui.input.button.submit" => ::GxG::Gui::SubmitButton,
            :"org.gxg.gui.block" => ::GxG::Gui::Block,
            :"org.gxg.gui.button.checkbox" => ::GxG::Gui::CheckBox,
            :"org.gxg.gui.image" => ::GxG::Gui::Image,
            :"org.gxg.gui.video" => ::GxG::Gui::Video,
            :"org.gxg.gui.audio" => ::GxG::Gui::Audio,
            :"org.gxg.gui.canvas" => ::GxG::Gui::Canvas,
            :"org.gxg.gui.input.hidden" => ::GxG::Gui::HiddenInput,
            :"org.gxg.gui.input.file" => ::GxG::Gui::FileInput,
            :"org.gxg.gui.input.text" => ::GxG::Gui::TextInput,
            :"org.gxg.gui.input.password" => ::GxG::Gui::PasswordInput,
            :"org.gxg.gui.input.reset" => ::GxG::Gui::ResetInput,
            :"org.gxg.gui.button.radio" => ::GxG::Gui::RadioButton,
            :"org.gxg.gui.picker.color" => ::GxG::Gui::ColorPicker,
            :"org.gxg.gui.picker.date" => ::GxG::Gui::DatePicker,
            :"org.gxg.gui.input.datetime.local" => ::GxG::Gui::DateTimeLocal,
            :"org.gxg.gui.input.email" => ::GxG::Gui::EmailInput,
            :"org.gxg.gui.picker.month" => ::GxG::Gui::MonthPicker,
            :"org.gxg.gui.picker.number" =>::GxG::Gui::NumberInput,
            :"org.gxg.gui.input.range" => ::GxG::Gui::RangeInput,
            :"org.gxg.gui.input.search" => ::GxG::Gui::SearchInput,
            :"org.gxg.gui.input.phone" => ::GxG::Gui::PhoneInput,
            :"org.gxg.gui.picker.time" => ::GxG::Gui::TimePicker,
            :"org.gxg.gui.input.url" => ::GxG::Gui::UrlInput,
            :"org.gxg.gui.picker.week" => ::GxG::Gui::WeekPicker,
            :"org.gxg.gui.label" => ::GxG::Gui::Label,
            :"org.gxg.gui.output" => ::GxG::Gui::Output,
            :"org.gxg.gui.paragraph" => ::GxG::Gui::Paragraph,
            :"org.gxg.gui.header.one" => ::GxG::Gui::Header1,
            :"org.gxg.gui.header.two" => ::GxG::Gui::Header2,
            :"org.gxg.gui.header.three" => ::GxG::Gui::Header3,
            :"org.gxg.gui.header.four" => ::GxG::Gui::Header4,
            :"org.gxg.gui.header.five" => ::GxG::Gui::Header5,
            :"org.gxg.gui.header.six" => ::GxG::Gui::Header6,
            :"org.gxg.gui.list" => ::GxG::Gui::List,
            :"org.gxg.gui.list.ordered" => ::GxG::Gui::OrderedList,
            :"org.gxg.gui.list.item" => ::GxG::Gui::ListItem,
            :"org.gxg.gui.link.anchor" => ::GxG::Gui::Anchor,
            :"org.gxg.gui.link.external" => ::GxG::Gui::ExternalLink,
            :"org.gxg.gui.button" => ::GxG::Gui::Button,
            :"org.gxg.gui.table" => ::GxG::Gui::Table,
            :"org.gxg.gui.table.header" => ::GxG::Gui::TableHeader,
            :"org.gxg.gui.table.row" => ::GxG::Gui::TableRow,
            :"org.gxg.gui.table.cell" => ::GxG::Gui::TableCell,
            :"org.gxg.gui.block.table" => ::GxG::Gui::BlockTable,
            :"org.gxg.gui.block.table.header" => ::GxG::Gui::BlockTableHeader,
            :"org.gxg.gui.block.table.row" => ::GxG::Gui::BlockTableRow,
            :"org.gxg.gui.block.table.cell" => ::GxG::Gui::BlockTableCell,
            :"org.gxg.gui.span" => ::GxG::Gui::Span,
            :"org.gxg.gui.select" => ::GxG::Gui::Select,
            :"org.gxg.gui.option" => ::GxG::Gui::Option,
            :"org.gxg.gui.field.set" => ::GxG::Gui::FieldSet,
            :"org.gxg.gui.legend" => ::GxG::Gui::Legend
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
        # See : https://get.foundation/sites/docs/kitchen-sink.html
        class GridContainer < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"grid-container"] == true
                    @states[:"grid-container"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.grid.container", ::GxG::Gui::GridContainer)
        #
        class GridX < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"grid-x"] == true
                    @states[:"grid-x"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
            #
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.grid.x", ::GxG::Gui::GridX)
        #
        class GridY < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"grid-y"] == true
                    @states[:"grid-y"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.grid.y", ::GxG::Gui::GridY)
        #
        class Accordion < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"accordion"] == true
                    @states[:"accordion"] = true
                end
                unless @options.keys.include?(:"data-accordion")
                    @options[:"data-accordion"] = nil
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.accordion", ::GxG::Gui::Accordion)
        #
        class AccordionItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
                unless @states[:"accordion-item"] == true
                    @states[:"accordion-item"] = true
                end
                unless @options.keys.include?(:"data-accordion-item")
                    @options[:"data-accordion-item"] = nil
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.accordion.item", ::GxG::Gui::AccordionItem)
        #
        class AccordionMenu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"vertical"] == true
                    @states[:"vertical"] = true
                end
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
                unless @options.keys.include?(:"data-accordion-menu")
                    @options[:"data-accordion-menu"] = nil
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.accordion.menu", ::GxG::Gui::AccordionMenu)
        #
        class AccordionSubMenu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"vertical"] == true
                    @states[:"vertical"] = true
                end
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
                unless @states[:"nested"] == true
                    @states[:"nested"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.accordion.submenu", ::GxG::Gui::AccordionSubMenu)
        #
        class AccordionMenuItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.accordion.menu.item", ::GxG::Gui::AccordionMenuItem)
        #
        class AnchorButton < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :a
                unless @states[:"button"] == true
                    @states[:"button"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.anchor.button", ::GxG::Gui::AnchorButton)
        #
        class Badge < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :span
                unless @states[:"badge"] == true
                    @states[:"badge"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.badge", ::GxG::Gui::Badge)
        #
        class Breadcrumb < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"breadcrumb"] == true
                    @states[:"breadcrumb"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.breadcrumb", ::GxG::Gui::Breadcrumb)
        #
        class BreadcrumbItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.breadcrumb.item", ::GxG::Gui::BreadcrumbItem)
        #
        class ButtonGroup < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"button-group"] == true
                    @states[:"button-group"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.button.group", ::GxG::Gui::ButtonGroup)
        #
        class Callout < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"callout"] == true
                    @states[:"callout"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.callout", ::GxG::Gui::Callout)
        #
        class ColoredLabel < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :span
                unless @states[:"label"] == true
                    @states[:"label"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.label.colored", ::GxG::Gui::ColoredLabel)
        #
        class DrilldownMenu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"vertical"] == true
                    @states[:"vertical"] = true
                end
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
                unless @options.keys.include?(:"data-drilldown")
                    @options[:"data-drilldown"] = nil
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.drilldown.menu", ::GxG::Gui::DrilldownMenu)
        #
        class DrilldownSubMenu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"vertical"] == true
                    @states[:"vertical"] = true
                end
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.drilldown.submenu", ::GxG::Gui::DrilldownSubMenu)
        #
        class DrilldownMenuItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.drilldown.menu.item", ::GxG::Gui::DrilldownMenuItem)
        #
        class DropdownSubMenu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
            end
            #
            def _after_create
                super()
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.dropdown.submenu", ::GxG::Gui::DropdownSubMenu)
        #
        class DropdownMenuItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.dropdown.menu.item", ::GxG::Gui::DropdownMenuItem)
        #
        class Equalizer < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"grid-x"] == true
                    @states[:"grid-x"] = true
                end
                unless @states[:"grid-margin-x"] == true
                    @states[:"grid-margin-x"] = true
                end
                unless @options.keys.include?(:"data-equalizer")
                    @options[:"data-equalizer"] = nil
                end
                unless @options.keys.include?(:"data-equalize-on")
                    @options[:"data-equalize-on"] = "medium"
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.equalizer", ::GxG::Gui::Equalizer)
        #
        class FlexGridRow < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"row"] == true
                    @states[:"row"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.flexgrid.row", ::GxG::Gui::FlexGridRow)
        #
        class FlexGridColumn < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"columns"] == true
                    @states[:"columns"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.flexgrid.column", ::GxG::Gui::FlexGridColumn)
        #
        class Embed < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"responsive-embed"] == true
                    @states[:"responsive-embed"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.embed", ::GxG::Gui::Embed)
        #
        class MediaObject < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"media-object"] == true
                    @states[:"media-object"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.media.object", ::GxG::Gui::MediaObject)
        #
        class MediaObjectSection < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"media-object-section"] == true
                    @states[:"media-object-section"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.media.object.section", ::GxG::Gui::MediaObjectSection)
        # DropdownMenu, See: https://get.foundation/sites/docs/kitchen-sink.html#dropdown-menu
        class DropdownMenu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"dropdown"] == true
                    @states[:"dropdown"] = true
                end
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
                unless @options.keys.include?(:"data-dropdown-menu")
                    @options[:"data-dropdown-menu"] = nil
                end
            end
            #
            def add_menu_item(label=nil, data=nil)
                the_item = ::GxG::Database::DetachedHash.new
                the_item[:component] = "org.gxg.gui.dropdown.menu.item"
                the_item[:settings] = {:label => label, :data => data}
                the_item[:options] = {}
                the_item[:script] = ""
                the_item[:content] = []
                page.build_components(self, [(the_item)])
                true
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.dropdown.menu", ::GxG::Gui::DropdownMenu)
        #
        class MenuBar < ::GxG::Gui::DropdownMenu
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.menu.bar", ::GxG::Gui::MenuBar)
        #
        class Menu < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"menu"] == true
                    @states[:"menu"] = true
                end
            end
            #
            def add_menu_item(label=nil, data=nil)
                the_item = ::GxG::Database::DetachedHash.new
                the_item[:component] = "org.gxg.gui.menu.item"
                the_item[:settings] = {:label => label, :data => data}
                the_item[:options] = {}
                the_item[:script] = ""
                the_item[:content] = []
                page.build_components(self, [(the_item)])
                true
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.menu", ::GxG::Gui::Menu)
        #
        class MenuItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
            #
            def initialize(the_parent, options)
                @label = nil
                super(the_parent, options)
                self
            end
            #
            def cascade
                #
                label = ::GxG::Database::DetachedHash.new
                label.title = "label #{@uuid.to_s}"
                label[:component] = "anchor"
                label[:settings] = {}
                # label[:options] = {:href => "#0", :content => (@settings[:label] || "Untitled").to_s}
                label[:options] = {:content => (@settings[:label] || "Untitled").to_s}
                label[:script] = "
                on(:mouseup) do |event|
                    menu_item = self.find_parent_type(::GxG::Gui::MenuItem)
                    if menu_item
                        unless menu_item.get_state(:disabled) == true
                            menu_item.select()
                        end
                    end
                end
                "
                label[:content] = []
                #
                page.build_components(self, [(label)])
                the_object = page.find_object_by("label #{@uuid.to_s}")
                if the_object
                    @label = the_object
                end
            end
            #
            def set_label(the_text=nil)
                if @label
                    @label.set_text(the_text.to_s)
                    @settings[:label] = the_text.to_s
                end
            end
            #
            def set_data(data=nil)
                @settings[:data] = data
            end
            #
            def select(data=nil)
                # override in object script
            end
            #
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.menu.item", ::GxG::Gui::MenuItem)
        #
        class OffCanvasWrapper < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"off-canvas-wrapper"] == true
                    @states[:"off-canvas-wrapper"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.offcanvas.wrapper", ::GxG::Gui::OffCanvasWrapper)
        #
        class OffCanvasWrapperInner < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"off-canvas-wrapper-inner"] == true
                    @states[:"off-canvas-wrapper-inner"] = true
                end
                unless @options.keys.include?(:"data-off-canvas-wrapper")
                    @options[:"data-off-canvas-wrapper"] = nil
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.offcanvas.wrapper.inner", ::GxG::Gui::OffCanvasWrapperInner)
        #
        class OffCanvasLeft < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"off-canvas"] == true
                    @states[:"off-canvas"] = true
                end
                unless @states[:"position-left"] == true
                    @states[:"position-left"] = true
                end
                unless @options.keys.include?(:"data-off-canvas")
                    @options[:"data-off-canvas"] = nil
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.offcanvas.left", ::GxG::Gui::OffCanvasLeft)
        #
        class OffCanvasRight < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"off-canvas"] == true
                    @states[:"off-canvas"] = true
                end
                unless @states[:"position-right"] == true
                    @states[:"position-right"] = true
                end
                unless @options.keys.include?(:"data-off-canvas")
                    @options[:"data-off-canvas"] = nil
                end
                unless @options.keys.include?(:"data-position")
                    @options[:"data-position"] = "right"
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.offcanvas.right", ::GxG::Gui::OffCanvasRight)
        #
        class OffCanvasContent < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"off-canvas-content"] == true
                    @states[:"off-canvas-content"] = true
                end
                unless @options.keys.include?(:"data-off-canvas-content")
                    @options[:"data-off-canvas-content"] = nil
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.offcanvas.content", ::GxG::Gui::OffCanvasContent)
        #
        class Orbit < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"orbit"] == true
                    @states[:"orbit"] = true
                end
                unless @options.keys.include?(:"role")
                    @options[:"role"] = "region"
                end
                unless @options.keys.include?(:"data-orbit")
                    @options[:"data-orbit"] = nil
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit", ::GxG::Gui::Orbit)
        #
        class OrbitContainer < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @states[:"orbit-container"] == true
                    @states[:"orbit-container"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit.container", ::GxG::Gui::OrbitContainer)
        #
        class OrbitPrevious < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :button
                unless @states[:"orbit-previous"] == true
                    @states[:"orbit-previous"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit.previous", ::GxG::Gui::OrbitPrevious)
        #
        class OrbitNext < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :button
                unless @states[:"orbit-next"] == true
                    @states[:"orbit-next"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit.next", ::GxG::Gui::OrbitNext)
        #
        class OrbitSlide < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
                unless @states[:"orbit-slide"] == true
                    @states[:"orbit-slide"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit.slide", ::GxG::Gui::OrbitSlide)
        #
        class OrbitNavigator < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :nav
                unless @states[:"orbit-bullets"] == true
                    @states[:"orbit-bullets"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit.navigator", ::GxG::Gui::OrbitNavigator)
        #
        class OrbitBullet < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :button
                unless @options.keys.include?(:"data-slide")
                    @options[:"data-slide"] = "0"
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.orbit.bullet", ::GxG::Gui::OrbitBullet)
        #
        class Pagination < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :ul
                unless @options.keys.include?(:"role")
                    @options[:"role"] = "navigation"
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.pagination", ::GxG::Gui::Pagination)
        #
        class PaginationItem < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :li
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.pagination.item", ::GxG::Gui::PaginationItem)
        #
        class ProgressBar < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"progress"] == true
                    @states[:"progress"] = true
                end
                unless @options.keys.include?(:"role")
                    @options[:"role"] = "progressbar"
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.progress.bar", ::GxG::Gui::ProgressBar)
        #
        class ProgressMeter < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"progress-meter"] == true
                    @states[:"progress-meter"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.progress.meter", ::GxG::Gui::ProgressMeter)
        #
        class HorizontalSlider < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"slider"] == true
                    @states[:"slider"] = true
                end
                # Data Initial and End
                if @options[:"data-initial-start"]
                    @data_start = @options.delete(:"data-initial-start")
                else
                    @data_start = "50"
                end
                if @options[:"data-initial-end"]
                    @data_second = @options.delete(:"data-initial-end")
                else
                    @data_second = nil
                end
                if @options[:"data-end"]
                    @data_end = @options.delete(:"data-end")
                else
                    @data_end = "200"
                end
            end
            #
            def _after_create
                super()
                if @data_second
                    container_one = self.add_child({:component => "org.gxg.gui.block", :title => "slider_container", :settings => {}, :options => {:states => ["small-10 columns"]}, :script =>"", :content => []})
                    slider = container_one.add_child({:component => "org.gxg.gui.block", :title => "slider",  :settings => {}, :options => {:'data-slider' => nil, :'data-initial-start' => @data_start, :'data-initial-end' => @data_second, :'data-end' => @data_end, :states => ["slider"]}, :script =>"", :content => []})
                    handle = slider.add_child({:component => "org.gxg.gui.span", :title => "slider_handle", :settings => {}, :options => {:"data-slider-handle" => nil, :role => "slider", :tabindex => "1", :states => ["slider-handle"]}, :script =>"", :content => []})
                    slider.add_child({:component => "org.gxg.gui.span", :title => "slider_groove", :settings => {}, :options => {:"data-slider-fill" => nil, :states => ["slider-fill"]}, :script =>"", :content => []})
                    handle_two = slider.add_child({:component => "org.gxg.gui.span", :title => "slider_handle_two", :settings => {}, :options => {:"data-slider-handle" => nil, :role => "slider", :tabindex => "1", :states => ["slider-handle"]}, :script =>"", :content => []})
                    container_two = self.add_child({:component => "org.gxg.gui.block", :title => ("value_container" + @uuid.to_s), :settings => {}, :options => {:states => ["small-2 columns"]}, :script =>"", :content => []})
                    value_containter = container_two.add_child({:component => "org.gxg.gui.picker.number", :title => "slider_value", :settings => {}, :options => {}, :script =>"", :content => []})
                    container_three = self.add_child({:component => "org.gxg.gui.block", :title => ("value_container_two" + @uuid.to_s), :settings => {}, :options => {:states => ["small-2 columns"]}, :script =>"", :content => []})
                    value_containter_two = container_three.add_child({:component => "org.gxg.gui.picker.number", :title => "slider_value_two", :settings => {}, :options => {}, :script =>"", :content => []})
                    handle.set_attribute(:"aria-controls", value_containter.uuid.to_s)
                    handle_two.set_attribute(:"aria-controls", value_containter_two.uuid.to_s)
                    #
                else
                    container_one = self.add_child({:component => "org.gxg.gui.block", :title => "slider_container", :settings => {}, :options => {:states => ["small-10 columns"]}, :script =>"", :content => []})
                    slider = container_one.add_child({:component => "org.gxg.gui.block", :title => "slider",  :settings => {}, :options => {:'data-slider' => nil, :'data-initial-start' => @data_start, :'data-end' => @data_end, :states => ["slider"]}, :script =>"", :content => []})
                    handle = slider.add_child({:component => "org.gxg.gui.span", :title => "slider_handle", :settings => {}, :options => {:"data-slider-handle" => nil, :role => "slider", :tabindex => "1", :states => ["slider-handle"]}, :script =>"", :content => []})
                    slider.add_child({:component => "org.gxg.gui.span", :title => "slider_groove", :settings => {}, :options => {:"data-slider-fill" => nil, :states => ["slider-fill"]}, :script =>"", :content => []})
                    container_two = self.add_child({:component => "org.gxg.gui.block", :title => ("value_container" + @uuid.to_s), :settings => {}, :options => {:states => ["small-2 columns"]}, :script =>"", :content => []})
                    value_containter = container_two.add_child({:component => "org.gxg.gui.picker.number", :title => "slider_value", :settings => {}, :options => {}, :script =>"", :content => []})
                    handle.set_attribute(:"aria-controls", value_containter.uuid.to_s)
                end
                `$(document).foundation()`
            end
            #
            def set_script(the_script_body="", alternate_target=nil)
                if alternate_target
                    alternate_target.set_script(the_script_body)
                else
                    if @data_second
                        handle = find_descendant("slider_handle")
                        unless handle
                            raise "Unable to find slider handle object."
                        end
                        super(the_script_body, handle)
                        handle_two = find_descendant("slider_handle_two")
                        unless handle_two
                            raise "Unable to find slider handle object."
                        end
                        super(the_script_body, handle_two)
                    else
                        handle = find_descendant("slider_handle")
                        unless handle
                            raise "Unable to find slider handle object."
                        end
                        super(the_script_body, handle)
                    end
                end
            end
            #
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.slider.horizontal", ::GxG::Gui::HorizontalSlider)
        #
        class VerticalSlider < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"slider"] == true
                    @states[:"slider"] = true
                end
                unless @states[:"vertical"] == true
                    @states[:"vertical"] = true
                end
                # Data Initial and End
                if @options[:"data-initial-start"]
                    @data_start = @options.delete(:"data-initial-start")
                else
                    @data_start = "50"
                end
                if @options[:"data-initial-end"]
                    @data_second = @options.delete(:"data-initial-end")
                else
                    @data_second = nil
                end
                if @options[:"data-end"]
                    @data_end = @options.delete(:"data-end")
                else
                    @data_end = "200"
                end
            end
            #
            def _after_create
                super()
                if @data_second
                    container_one = self.add_child({:component => "org.gxg.gui.block", :title => "slider_container", :settings => {}, :options => {:states => ["small-10 columns"]}, :script =>"", :content => []})
                    slider = container_one.add_child({:component => "org.gxg.gui.block", :title => "slider",  :settings => {}, :options => {:'data-slider' => nil, :'data-initial-start' => @data_start, :'data-initial-end' => @data_second, :'data-end' => @data_end, :states => ["vertical","slider"]}, :script =>"", :content => []})
                    handle = slider.add_child({:component => "org.gxg.gui.span", :title => "slider_handle", :settings => {}, :options => {:"data-slider-handle" => nil, :role => "slider", :tabindex => "1", :states => ["slider-handle"]}, :script =>"", :content => []})
                    slider.add_child({:component => "org.gxg.gui.span", :title => "slider_groove", :settings => {}, :options => {:"data-slider-fill" => nil, :states => ["slider-fill"]}, :script =>"", :content => []})
                    handle_two = slider.add_child({:component => "org.gxg.gui.span", :title => "slider_handle_two", :settings => {}, :options => {:"data-slider-handle" => nil, :role => "slider", :tabindex => "1", :states => ["slider-handle"]}, :script =>"", :content => []})
                    container_two = self.add_child({:component => "org.gxg.gui.block", :title => ("value_container" + @uuid.to_s), :settings => {}, :options => {:states => ["small-2 columns"]}, :script =>"", :content => []})
                    value_containter = container_two.add_child({:component => "org.gxg.gui.picker.number", :title => "slider_value", :settings => {}, :options => {}, :script =>"", :content => []})
                    container_three = self.add_child({:component => "org.gxg.gui.block", :title => ("value_container_two" + @uuid.to_s), :settings => {}, :options => {:states => ["small-2 columns"]}, :script =>"", :content => []})
                    value_containter_two = container_three.add_child({:component => "org.gxg.gui.picker.number", :title => "slider_value_two", :settings => {}, :options => {}, :script =>"", :content => []})
                    handle.set_attribute(:"aria-controls", value_containter.uuid.to_s)
                    handle_two.set_attribute(:"aria-controls", value_containter_two.uuid.to_s)
                    #
                else
                    container_one = self.add_child({:component => "org.gxg.gui.block", :title => "slider_container", :settings => {}, :options => {:states => ["small-10 columns"]}, :script =>"", :content => []})
                    slider = container_one.add_child({:component => "org.gxg.gui.block", :title => "slider",  :settings => {}, :options => {:'data-slider' => nil, :'data-initial-start' => @data_start, :'data-end' => @data_end, :states => ["vertical","slider"]}, :script =>"", :content => []})
                    handle = slider.add_child({:component => "org.gxg.gui.span", :title => "slider_handle", :settings => {}, :options => {:"data-slider-handle" => nil, :role => "slider", :tabindex => "1", :states => ["slider-handle"]}, :script =>"", :content => []})
                    slider.add_child({:component => "org.gxg.gui.span", :title => "slider_groove", :settings => {}, :options => {:"data-slider-fill" => nil, :states => ["slider-fill"]}, :script =>"", :content => []})
                    container_two = self.add_child({:component => "org.gxg.gui.block", :title => ("value_container" + @uuid.to_s), :settings => {}, :options => {:states => ["small-2 columns"]}, :script =>"", :content => []})
                    value_containter = container_two.add_child({:component => "org.gxg.gui.picker.number", :title => "slider_value", :settings => {}, :options => {}, :script =>"", :content => []})
                    handle.set_attribute(:"aria-controls", value_containter.uuid.to_s)
                end
                `$(document).foundation()`
            end
            #
            def set_script(the_script_body="", alternate_target=nil)
                if alternate_target
                    alternate_target.set_script(the_script_body)
                else
                    if @data_second
                        handle = find_descendant("slider_handle")
                        unless handle
                            raise "Unable to find slider handle object."
                        end
                        super(the_script_body, handle)
                        handle_two = find_descendant("slider_handle_two")
                        unless handle_two
                            raise "Unable to find slider handle object."
                        end
                        super(the_script_body, handle_two)
                    else
                        handle = find_descendant("slider_handle")
                        unless handle
                            raise "Unable to find slider handle object."
                        end
                        super(the_script_body, handle)
                    end
                end
            end
            #
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.slider.vertical", ::GxG::Gui::VerticalSlider)
        #
        class StickyContainer < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @options.keys.include?(:"data-sticky-container")
                    @options[:"data-sticky-container"] = nil
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.sticky.container", ::GxG::Gui::StickyContainer)
        #
        class Sticky < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"sticky"] == true
                    @states[:"sticky"] = true
                end
                unless @options.keys.include?(:"data-sticky")
                    @options[:"data-sticky"] = nil
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.sticky", ::GxG::Gui::Sticky)
        #
        class Switch < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"switch"] == true
                    @states[:"switch"] = true
                end
            end
            def _after_create
                input_one = self.add_child({:component => "org.gxg.gui.button.checkbox", :title => ("switch_input" + @uuid.to_s), :settings => {}, :options => {:states => ["switch-input"]}, :script =>"", :content => []})
                label_one = self.add_child({:component => "org.gxg.gui.label", :title => ("switch_paddle" + @uuid.to_s), :settings => {}, :options => {:for => (input_one.uuid.to_s), :states => ["switch-paddle"]}, :script =>"", :content => []})
                span_one = label_one.add_child({:component => "org.gxg.gui.span", :title => ("switch_span" + @uuid.to_s), :settings => {}, :options => {:states => ["show-for-sr"]}, :script =>"", :content => []})
                `$(document).foundation()`
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.switch", ::GxG::Gui::Switch)
        #
        class TabContent < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"tabs-panel"] == true
                    @states[:"tabs-panel"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.tab.content", ::GxG::Gui::TabContent)
        #
        class TabSet < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
            end
            def _after_create
                @tabs = self.add_child({:component => "org.gxg.gui.list", :title => ("tabs" + @uuid.to_s), :settings => {}, :options => {:"data-tabs" => nil, :states => ["tabs"]}, :script =>"", :content => []})
                @tab_content = self.add_child({:component => "org.gxg.gui.block", :title => ("tab_content" + @uuid.to_s), :settings => {}, :options => {:"data-tabs-content" => (@tabs.uuid.to_s), :states => ["tabs-content"]}, :script =>"", :content => []})
                `$(document).foundation()`
            end
            def add_child(options={})
                new_child = nil
                if options[:component].to_s.downcase.to_sym == :tab_content
                    new_child = @tab_content.add_child(options)
                    item = @tabs.add_child({:component => "org.gxg.gui.list.item", :title => ("tab" + new_child.uuid.to_s), :settings => {}, :options => {:states => ["tabs-title"]}, :script =>"", :content => []})
                    link = item.add_child({:component => "org.gxg.gui.link.anchor", :title => ("link" + new_child.uuid.to_s), :settings => {}, :options => {:"href" => ("#" + new_child.uuid.to_s), :states => []}, :script =>"", :content => []})
                    link.value = new_child.title.to_s
                else
                    raise "Unacceptable Component Type"
                end
                new_child
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.tab.set", ::GxG::Gui::TabSet)
        #
        class Thumbnail < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :img
                unless @states[:"thumbnail"] == true
                    @states[:"thumbnail"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.thumbnail", ::GxG::Gui::Thumbnail)
        #
        class Titlebar < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"title-bar"] == true
                    @states[:"title-bar"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.titlebar", ::GxG::Gui::Titlebar)
        #
        class TitlebarLeft < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"title-bar-left"] == true
                    @states[:"title-bar-left"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.titlebar.left", ::GxG::Gui::TitlebarLeft)
        #
        class TitlebarRight < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"title-bar-right"] == true
                    @states[:"title-bar-right"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.titlebar.right", ::GxG::Gui::TitlebarRight)
        #
        class Topbar < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"top-bar"] == true
                    @states[:"top-bar"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.topbar", ::GxG::Gui::Topbar)
        #
        class TopbarLeft < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"top-bar-left"] == true
                    @states[:"top-bar-left"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.topbar.left", ::GxG::Gui::TopbarLeft)
        #
        class TopbarRight < ::GxG::Gui::Vdom::BaseElement
            def _before_create
                super()
                @domtype = :div
                unless @states[:"top-bar-right"] == true
                    @states[:"top-bar-right"] = true
                end
            end
        end
        ::GxG::Gui::register_component_class(:"org.gxg.gui.topbar.right", ::GxG::Gui::TopbarRight)
        #
    end
end