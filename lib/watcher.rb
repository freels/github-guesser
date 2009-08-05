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

  def repo_ancestors
    @repo_ancestors ||= begin
      ancestors = []

      repos.each do |repo|
        parent = repo.parent
        until parent.nil?
          ancestors << parent
          parent = parent.parent
        end
      end

      ancestors.uniq - repos
    end
  end

  def repo_parents
    @repo_parents ||= repos.map {|r| r.parent }.uniq
  end

  def repo_ids
    @repo_ids ||= repos.map {|r| r.id }
  end

  def repo_parent_ids
    @repo_parent_ids ||= repo_parents.map {|r| r.id }
  end

  def repo_ancestor_ids
    @repo_ancestor_ids ||= repo_ancestors.map {|r| r.id }
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
