require 'optparse'
require 'fssm'

class Main
  def initialize
    options = MyOptionParser.new.parse
    @pattern = Pattern.new(options)
    @command = Command.new(options)
  end

  def start
    cmd = @command
    FSSM.monitor('.', @pattern) do
      update do |base, file|
        cmd.execute(base, file)
      end
      create do |base, file|
        cmd.execute(base, file)
      end
    end
  end
end

class MyOptionParser
  def initialize
    @options = {:pattern => "**/*"}
    @parser = OptionParser.new

    @parser.on("-p", "--pattern PATTERN"){ |v| @options[:pattern] = v }
  end

  def parse
    @options[:argv] = @parser.parse(ARGV)
    @options
  end
end

class Pattern < String
  def initialize(options)
    super options[:pattern]
  end
end

class Command
  def initialize(options)
    @base_command = options[:argv].join(" ") || ""
  end

  def execute(base, file)
    dict = { "base" => base, "file" => file }
    command = @base_command.gsub(/%(file|base)/){ dict[$1] }

    puts "command: `#{command}`"
    puts `#{command}`
  end

  def to_s
    @base_command
  end
end

Main.new.start
