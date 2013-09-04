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

pattern = ARGV[0]
command = ARGV[1..-1].join(" ")

FSSM.monitor('.', pattern) do
  update do |base, file|
    path = "#{base}/#{file}"
    puts "UPDATE: #{path}"
    puts `#{command} #{path}`
  end
  create do |base, file|
    path = "#{base}/#{file}"
    puts "CREATE: #{path}"
    puts `#{command} #{path}`
  end
end
