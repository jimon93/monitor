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
        UpdateCommand.new(options, base, file).execute
      end
      create do |base, file|
        CreateCommand.new(options, base, file).execute
      end
      #remove do |base, file|
      #  RemoveCommand.new(options, base, file).execute
      #end
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
    @options
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
  def initialize(options, base, file)
    @options, @base, @file = options, base, file
  end

  def execute
    unless extend_command.empty?
      puts "#{self.class.name}: `#{extend_command}`"
      puts `#{extend_command}`
    end
  end

  protected
  def base_command
    raise NotImplementedError
  end

  private
  def extend_command
    @_extend_command ||= base_command.gsub(/[$%](file|base|dir)/){ dict[$1] }
  end

  def dict
    @_dict ||= {
      "base" => base,
      "file" => file,
      "dir"  => File.dirname(file)
    }
  end
end

class UpdateCommand < Command
  protected
  def base_command
    @options[:update] || @options[:argv].join(" ") || ""
  end
end

class CreateCommand < Command
  protected
  def base_command
    @options[:create] || @options[:argv].join(" ") || ""
  end
end

class RemoveCommand < Command
  protected
  def base_command
    @options[:remove] ||  ""
  end
end

Main.new.start
