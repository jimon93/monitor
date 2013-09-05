# Extend ============= {{{
# Maybe #{{{
class NilClass
  def method_missing( method_name, *args )
    nil
  end
end #}}}
# Enumerable Extend #{{{
module Enumerable
  #alias :filter :find_all
  def count_by(&block)
    Hash[ group_by(&block).map{ |key,vals| [key, vals.size] } ]
  end
end #}}}
# Identity #{{{
class Object
  def identity
    self
  end
end #}}}
# ==================== }}}

require 'optparse'
require 'fssm'

class MyOptionParser
  def initialize
    @option = {:pattern => "**/*"}
    @parser = OptionParser.new

    @parser.on("-p", "--pattern PATTERN"){ |v| @option[:pattern] = v }
  end

  def parse
    argv = @parser.parse(ARGV)
    [@option, argv]
  end
end

class Commandor
  def initialize(option, argv)
    @command = argv.join(" ")
  end

  def execute(base, file)
    command = create_command(base, file)
    puts `#{command}`
  end

  private
  def create_command(base, file)
    dict = { "base" => base, "file" => file }
    @command.gsub(/%(file|base)/){ dict[$1] }
  end
end


option, argv = MyOptionParser.new.parse
pattern = option[:pattern]
commandor = Commandor.new(option, argv)

FSSM.monitor('.', pattern) do
  update do |base, file|
    puts "UPDATE: #{base}/#{file}"
    commandor.execute(base, file)
  end
  create do |base, file|
    puts "CREATE: #{base}/#{file}"
    commandor.execute(base, file)
  end
end
