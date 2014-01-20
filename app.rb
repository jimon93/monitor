#!/usr/local/bin/ruby
Version = "0.0.1"
require 'optparse'
require 'fssm'

class Main
  def initialize
    @options =  MyOptionParser.new.parse
    @watch_path = WatchPath.new(@options)
    @pattern = Pattern.new(@options)
  end

  def start
    options = @options
    FSSM.monitor(@watch_path, @pattern) do
      update do |base, file|
        Command.new(options[:update], base, file).execute
      end
      create do |base, file|
        Command.new(options[:create], base, file).execute
      end
    end
  end
end

class MyOptionParser
  def initialize
    @options = {:path => ".", :pattern => "**/*"}
    @parser = OptionParser.new

    desc =  "the path to watch (default: '.')"
    @parser.on("-w", "--watch-path PATH", desc){ |v| @options[:path] = v }

    desc = "one or more glob pattern (default: '**/*')"
    @parser.on("-p", "--pattern PATTERN", desc){ |v| @options[:pattern] = v }

    desc = "when a file is create, use a command"
    @parser.on('-c', "--create COMMAND", desc){ |v| @options[:create] = v }

    desc = "when a file is update, use a command"
    @parser.on('-u', "--update COMMAND", desc){ |v| @options[:update] = v }

    #desc = "when a file is remove, use a command"
    #@parser.on('-r', "--remove COMMAND", desc){ |v| @options[:remove] = v }
  end

  def parse
    @options[:argv] = @parser.order(ARGV)
    @options[:update] ||= @options[:argv].join(" ")
    @options[:create] ||= @options[:argv].join(" ")
    validate
    return @options
  end

  def validate
    if @options[:update].empty? and @options[:create].empty?
      puts @parser.help
      exit 1
    end
  end

end

class WatchPath < String
  def initialize(options)
    super options[:path]
  end
end

class Pattern < Array
  def initialize(options)
    super options[:pattern].split(" ")
  end
end

class Command
  def initialize(command, base, file)
    @command, @base, @file = command, base, file
  end

  def execute
    unless extend_command.empty?
      puts "#{self.class.name}: `#{extend_command}`"
      puts `#{extend_command}`
    end
  end

  private
  def extend_command
    @_extend_command ||= @command.gsub(/[$%](file|base|dir|fullpathdir|fullpath)/){ get_path($1) }
  end

  def get_path(path)
    case path
    when "base" then
      @base
    when "file" then
      @file
    when "dir" then
      File.dirname @file
    when "fullpath" then
      "#{@base}/#{@file}"
    when "fullpathdir" then
      File.dirname "#{@base}/#{@file}"
    end
  end
end

Main.new.start
