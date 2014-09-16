#require 'pdfkit'
require 'nokogiri'
require 'prawn'
require 'prawn/measurement_extensions'

require 'helpers/import'
import 'yuzu/core/siteroot'

module Yuzu::Command

  class Pdf < Base
    def index
      # Override needed because paths should all be local file paths, not URL-based.
      @config.link_root_override = Dir.pwd.to_s
      @siteroot = Yuzu::Core::SiteRoot.new(@config)
      @pdf = PdfMaker.new(@siteroot)
      @pdf.write_to_disk
    end

    def self.help(method)
      case method
      when :index
        ""
      end
    end
  end

  class PdfMaker
    def initialize(siteroot)
      @siteroot = siteroot

      render!
    end

    def render_pdfkit!
      #file_to_render = @siteroot.get_child_by_filename("index.md")
      #contents = file_to_render.html_contents

      #kit = PDFKit.new(html, :page_size => 'Letter')
      #kit.stylesheets << '/path/to/css/file'

      # Save the PDF to a file
      #file = kit.to_file("#{@siteroot.config.site_name}.pdf")
    end

    def pdf_name
      @siteroot.config.site_name.gsub(" ", "_")
    end

    def render!
      files_to_render = get_all_website_files

      top_margin = bottom_margin = 0.75.send(:in)
      left_margin = right_margin = 1.0.send(:in)

      Prawn::Document.generate(
        "#{pdf_name}.pdf", 
        :top_margin => top_margin,
        :bottom_margin => bottom_margin,
        :left_margin => left_margin,
        :right_margin => right_margin
      ) do |pdf|

        #:normal => "#{Prawn::DATADIR}/fonts/Chalkboard.ttf"
        pdf.font_families.update(
          "Times" => {
            :normal => "/System/Library/Fonts/Times.dfont"
          },
          "Georgia" => {
            :normal => "/Library/Fonts/Georgia.ttf"
          },
          "sans" => {
            :normal => "/System/Library/Fonts/HelveticaNeue.dfont"
          }
        )

        pdf.font(default_font)
        pdf.font_size(default_size)
        pdf.default_leading(5)

        files_to_render.each do |website_file|
          $stderr.puts website_file
          render_page_for!(website_file, pdf)
          pdf.start_new_page
        end

      end
    end

    def get_all_website_files
      files_only = proc {|f| f.file? and f.processable? and not f.hidden? and not f.generated? and not f.index?}
      v = Yuzu::Core::Visitor.new(files_only)

      files = []
      v.traverse_breadth(@siteroot) do |website_file|
        files.push(website_file)
      end
      files
    end

    def render_title_for!(website_file, pdf)
      pdf.font_size(16)
      pdf.text(website_file.name)
      pdf.move_down(20)
      pdf.font_size(default_size)
    end

    def render_page_for!(website_file, pdf)
      #render_title_for!(website_file, pdf)

      contents = website_file.html_contents
      html = Nokogiri::HTML(contents)

      nodes = []
      nodes_to_get = ["p", "ol", "ul", "h1", "h2", "h3", "h4", "img"]

      article = html.css("article")
      return if article.length == 0

      article[0].traverse do |node|
        if nodes_to_get.include?(node.name)
          nodes.push(node)
        end
      end

      #flattened = html.css("article p, article li, article h1, article h2, article h3, article h4")
      flattened = nodes

      flattened.each do |el|
        if el.name == "img"
          render_image!(el, pdf)
        else
          render_text_node!(el, pdf)
        end
      end

    end

    def render_image!(el, pdf)
      hider = []

      el.ancestors.each do |p|
        if p.respond_to?(:attributes)
          if p.attributes.has_key?('style')
            hider.push(p.attributes['style'].to_s.downcase)
          end
        end
      end

      is_hidden = false
      if hider.length > 0
        hider.each do |style|
          m = style.match(/display:\s*?none/)
          if not m.nil?
            is_hidden = true
          end
        end
      end

      source = el.attributes['src'].to_s
      is_hidden ||= source.include?("-small.")
      source = source.sub("-large.", "-medium.")

      if not is_hidden
        $stderr.puts "Inserting image #{source}"
        width = 6.5.in
        pdf.image(source, :width => width)
        pdf.move_down(20)
      end
    rescue => e
      # It's OK if the image is not found.
      $stderr.puts e.message
    end

    def default_font
      #"Georgia"
      "Times"
    end

    def default_size
      11
    end

    def render_list_item!(node, prefix, pdf)
      #child = node.first_element_child

      #is_code = false
      #if not child.nil?
      #  is_code = node.first_element_child.name == "code"
      #end
      #pdf.font("Courier") if is_code

      #pdf.text("#{prefix} " + node.content.to_s.strip)

      #pdf.font(default_font) if is_code

      pdf.float do
        pdf.bounding_box [15, pdf.cursor], :width => 10 do
          pdf.text prefix
        end
      end

      pdf.formatted_text_box(
        formatted_text(node), :at => [25, pdf.cursor], :width => 500, :font => default_font
      )
      #pdf.bounding_box [25, pdf.cursor], :width => 500 do
      #  formatted_text(node, pdf)
      #end

      pdf.move_down(20)
    end

    def render_text_node!(el, pdf)
      sans_tags = ["h2", "h3", "h4"]
      no_move_tags = ["li"]

      if el.name == "p"
        # Strip newlines out of paragraphs.
        lines = el.content.to_s.split("\n")
        el_contents = lines.collect {|line| line.strip}.join(" ")
      else
        el_contents = el.content.to_s.strip
      end

      large_text = false
      sans_text = false
      if el.parent.attributes.has_key?('class')
        if el.parent.attributes['class'].to_s.include?("intro")
          large_text = true
        end
        if el.parent.attributes['class'].to_s.include?("content-footer")
          sans_text = true
        end
      end

      pdf.font_size(20) if large_text
      pdf.font_size(16) if el.name == "h1"
      pdf.font_size(10) if sans_text
      pdf.font("Helvetica") if sans_tags.include?(el.name) or sans_text

      if el.name == "ul"
        el.children.each do |node|
          if node.name == "li"
            pdf.text("* " + node.content.to_s)
          end
        end
      elsif el.name == "ol"
        count = 1
        el.children.each do |node|
          if node.name == "li"
            render_list_item!(node, "#{count}. ", pdf)
            count += 1
          end
        end
      else
        pdf.text(el_contents)
      end

      pdf.font_size(default_size) if large_text or el.name == "h1" or sans_text
      pdf.font(default_font) if sans_tags.include?(el.name) or sans_text
      pdf.move_down(20) if not no_move_tags.include?(el.name)
    end

    def formatted_text(node)
      tr = []
      node.children.each do |child|
        tr.push formatted_chunk(child)
      end
      tr
    end

    def formatted_chunk(node)
      if node.text?
        {:text => node.to_s, :font => default_font}
      elsif node.name == "code"
        {:text => node.children[0].to_s, :font => code_font}
      elsif node.name == "strong"
        {:text => node.children[0].to_s, :styles => [:bold], :font => default_font}
      elsif node.name == "em"
        {:text => node.children[0].to_s, :styles => [:italic], :font => default_font}
      else
        {:text => node.to_s, :font => default_font}
      end
    end

    def code_font
      "Courier"
    end

    def write_to_disk
    end
  end



end

