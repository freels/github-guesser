require 'monkey'
require 'watch'
require 'repo'

class Watcher
  attr_accessor :id

  def initialize(id)
    self.id = id
    self.class.all[id] = self
  end

  def watches
    @watches ||= Watch.all_by_watcher[id].sort_by{|w| w.repo_id}
  end

  def repos
    @repos ||= watches.map{|w| w.repo}.sort_by{|w| w.repo_id}
  end

  class << self
    def all
      @all ||= {}
    end

    def [](id)
      all[id] ||= new(id)
    end
  end
end
