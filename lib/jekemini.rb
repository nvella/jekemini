require 'logger'
require 'optparse'
require 'yaml'
require 'kramdown'

# TODO kramdown gemini converter

module Jekemini
  class Post
    BODY_REGEX = /^(?:.*)?---\r?\n(?:.*\r?\n)*---\r?\n((?:.*\r?\n?)*)$/

    def initialize(format, front_matter, body)
      @format = format
      @front_matter = front_matter
      @body = body
    end

    def render
      # Render the post in Gemini
    end

    def self.from_post_md(data)
      # Parse the front matter
      # Take the Markdown and convert it to gemini thru redcarpet 
      front_matter = YAML.load(data)
      puts front_matter
      post_body = BODY_REGEX.match(data).captures.first
      throw 'couldn\'t find a post body!' if post_body.nil?

      markdown = Kramdown::Document.new(post_body).to_latex
      puts markdown
    end

    def self.from_post_html(data)
      # Parse the front matter
      # Take HTML nad convert it to gemini thru redcarpet


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
        
        do_post path
      end
    end

    def do_post(path)

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

