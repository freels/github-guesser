require 'monkey'
require 'date'
require 'watch'
require 'watcher'
require 'owner'
require 'lang'

class Repo
  attr_accessor :id, :owner_name, :name, :date, :parent_id

  def initialize(data)
    instantiate_with data

    self.class.all[self.id] = self
    self.class.all_by_parent[parent_id] = self if parent_id
    self.class.all_by_owner[owner_name] = self
  end

  def watches
    Watch.all_by_repo[id]
  end

  def watchers
    @watchers ||= watches.map{|w| w.watcher}
  end

  def parent
    self.class[parent_id]
  end

  def owner
    Owner[name]
  end

  def langs
    Lang.all_by_repo[id]
  end

  private

  def instantiate_with(data)
    m = %r|(\d+):(.*?)/(.+?),(\d\d\d\d-\d\d-\d\d),?(\d*)|.match(data)
    raise "can't understand! #{data}" unless m

    id, owner_name, name, date, parent_id = m[1..5]
    self.id = id.to_i
    self.owner_name = owner_name
    self.name = name
    self.date = Date.parse(date)
    self.parent_id = parent_id.to_i unless parent_id.empty?
  end

  class << self
    def all
      @all ||= {}
    end

    def [](id)
      all[id]
    end

    def all_by_parent
      @all_by_parent ||= Hash.new{|h,k| h[k] = []}
    end

    def all_by_owner
      @all_by_owner ||= Hash.new{|h,k| h[k] = []}
    end
  end
end
