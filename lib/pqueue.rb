require 'monkey'

class PQueue
  def initialize(length)
    @length = length
    @list = []
    @order = 0
  end

  def add(priority, item)
    @order += 1

    priority = priority * -1 # highest numbers first

    if @list.length >= @length and @list.last.first < priority
      return self
    end

    @list << [priority, @order, item]
    @list.sort!
    @list.pop if @list.length > @length
    self
  end

  def <<(pritem)
    add(*pritem)
  end

  def to_a
    @list.map{|a| a.last}
  end
end

