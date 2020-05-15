require 'logger'
require 'optparse'
require 'yaml'
require 'kramdown'

# TODO kramdown gemini converter

module Jekemini
  class GeminiConverter < Kramdown::Converter::Base
    def initialize(root, options)
      super(root, options)
      @refs = {}
    end

    def convert(el, opts = {})
      method_sym = :"convert_#{el.type}"
      if respond_to? method_sym
        text = send(method_sym, el, opts)
        text = text.dup if text.frozen?
        return text.force_encoding('UTF-8')
      end
      '' #"(unknown el #{el.type} #{el.value.inspect})"
    end

    def convert_root(el, opts)
      res = c(el)
      if !@refs.empty?
        res << "\r\n"
        @refs.each {|key, ref| res << "=> #{ref[:link]}\t[#{key}] #{ref[:link]}\r\n"}
      end
      res
    end

    def convert_p(el, opts)
      return "#{c(el)}\r\n" if opts[:in_blockquote] # Don't douple append newline if in quote

      "#{c(el)}\r\n\r\n"
    end

    def convert_text(el, opts)
      return el.value.dup if el.value.frozen?
      el.value
    end

    def convert_em(el, opts)
      "_#{c(el)}_"
    end

    def convert_img(el, opts)
      ref_num = ref(el.attr['src'], "Image: #{el.attr['alt']}")
      "(Image: #{el.attr['alt']}[#{ref_num}])"
    end

    def convert_a(el, opts)
      child_text = c el
      "#{child_text}[#{ref(el.attr['href'], child_text)}]"
    end

    def convert_smart_quote(el, opts)
      if Kramdown::Parser::Kramdown::SQ_SUBSTS.value?(el.value)
        Kramdown::Parser::Kramdown::SQ_SUBSTS.key(el.value).last
      else
        "'"
      end
    end

    def convert_entity(el, opts)
      el.value.code_point.chr
    end

    def convert_blockquote(el, opts)
      "> #{c(el, in_blockquote: true)}"
    end

    def convert_blank(el, opts); ''; end

    private
    def c(el, opts = {})
      el.children.map {|child| convert(child, opts)}.join
    end

    def ref(link, title)
      id = @refs.length + 1
      @refs[id] = {link: link, title: title}
      id
    end
  end

  class Post
    attr_reader :path, :format, :front_matter, :body

    FM_REGEX = /^(---\r?\n[\s\S]*---\r?\n(?:\r?\n)?)/

    def initialize(format, front_matter, body)
      @format = format
      @front_matter = front_matter
      @body = body
    end

    def render
      # Render the post in Gemini format
      GeminiConverter.convert(kd_document.root, kd_document.options)[0]
    end

    def kd_document
      Kramdown::Document.new(@body, input: case @format
      when :md
        'kramdown'
      when :html
        'html'
      end)
    end

    def save(path)
      @path = path
      File.write(path, render)
    end

    def self.from_post_md(data)
      # Parse the front matter
      front_matter = YAML.load(data)
      post_body = data.gsub(FM_REGEX, '')
      throw 'couldn\'t find a post body!' if post_body.nil?

      Post.new(:md, front_matter, post_body)
    end

    def self.from_post_html(data)
      # Parse the front matter
      front_matter = YAML.load(data)
      post_body = data.gsub(FM_REGEX, '')
      throw 'couldn\'t find a post body!' if post_body.nil?

      Post.new(:html, front_matter, post_body)
    end
  end

  class App
    def initialize(posts_path:, out_path:, templates_path:)
      @posts_path = posts_path
      @out_path = out_path
      @templates_path = templates_path

      @log = Logger.new STDOUT
    end

    def run
      @log.info 'Building Gemini blog from posts'
      @log.info "#{@posts_path} -> #{@out_path}"
      @log.info "templates @ #{@templates_path}"

      Dir.entries(@posts_path).each do |entry|
        next if File.extname(entry) != '.html' && File.extname(entry) != '.md'

        path = File.join(@posts_path, entry)
        @log.info "processing #{path}"
        
        post = post_from_path(path)
        post_out = File.join(@out_path, "#{File.basename(entry, ".*")}.gmi")
        @log.info "saving to #{post_out}"
        post.save(post_out)
      end
    end

    def post_from_path(path)
      case File.extname(path)
      when '.md'
        Post.from_post_md(File.read(path).force_encoding("utf-8"))
      when '.html'
        Post.from_post_html(File.read(path).force_encoding("utf-8"))
      end
    end

    def self.start
      options = {}

      OptionParser.new do |opt|
        opt.on('-p POSTS_PATH') { |o| options[:posts_path] = o }
        opt.on('-o GEMINI_OUTPUT') { |o| options[:out_path] = o }
        opt.on('-t TEMPLATES_PATH') { |o| options[:templates_path] = o }
      end.parse!

      throw 'i need a posts path!' if options[:posts_path].nil?
      throw 'i need an output path!' if options[:out_path].nil?
      options[:templates_path] = './_templates' if options[:templates_path].nil?

      App.new(**options).run
    end
  end
end

