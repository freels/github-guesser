require 'monkey'

class PQueue
  def initialize(length, order = :descending)
    @length = length
    @list = []
    @order = order
    @current = 0
  end

  def add(priority, item)
    @current += 1

    # highest numbers first if :descending
    priority = priority * -1 if @order == :descending

    if @list.length >= @length and @list.last.first < priority
      return self
    end

    @list << [priority, @current, item]
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

