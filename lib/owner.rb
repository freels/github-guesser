require 'monkey'
require 'repo'

class Owner
  attr_accessor :name

  def initialize(name)
    self.name = name
    self.class.all[name] = self
  end

  def repos
    @repos ||= Repo.all_by_owner[name]
  end

  class << self
    def all
      @all ||= {}
    end

    def [](name)
      all[name] ||= new(name)
    end
  end
end
