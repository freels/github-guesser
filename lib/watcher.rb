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
    @repos ||= watches.map{|w| w.repo}.sort_by{|r| r.id}
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

  def preferred_langs
    @preferred_lang ||= begin
      repos.inject(Hash.new(0)) {|langs,r| langs[r.lang] += 1 if r.lang; langs }
    end
  end

  def nearest_neighbors(count)
    nearest = PQueue.new(count)

    (Watcher.neighbors[id] || {}).each do |neigbor, shared_count|
      nearest.add shared_count, [neigbor, shared_count]
    end

    nearest.to_a
  end


  class << self
    def all
      @all ||= {}
    end

    def [](id)
      all[id] ||= new(id)
    end

    def neighbors
      @neighbors ||= begin
        neighbors = {}

        if File.exist?('neighbors.dump')
          neighbors = Marshal.load(File.read('neighbors.dump'))

        else
          Watch.all_by_repo.each do |repo_id, watches|
            watches.each do |w1|
              watches.each do |w2|
                id_1 = w1.watcher_id
                id_2 = w2.watcher_id
                if id_1 != id_2
                  neighbors[id_1] ||= {}
                  neighbors[id_1][id_2] ||= 0
                  neighbors[id_1][id_2] += 1
                end
              end
            end
          end

          File.open('neighbors.dump', 'w') do |fd|
            fd.puts Marshal.dump(neighbors)
          end
        end

        neighbors
      end
    end
  end
end
