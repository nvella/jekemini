# Jekemini

A static site generator for Gemini, designed to co-exist with your existing static site generator.

The name is my poor attempt at a cross between Jekyll and Gemini.

## Why Ruby?

Besides myself being comfortable with it, Ruby has a plethora of (extensible) libraries for parsing and converting HTML and Markdown.

## How to use

Currently Jekemini's configuration is provided on the command line. Configuration DSL may be on the table.

- Install the latest version of Ruby and Bundler.
- Clone the repo
- `bundle`
- `bin/jekemini -p path_to_your_posts_dir -o output_dir [-t templates_dir]`

## Templates directory

Contains various template and helper files to build your Gemini site. Templates are in ERB format. Copy the templates dir from the repo to make your own.

Template files
- `layout.erb` - Layout for every page on your site 
