require 'monkey'
require 'watcher'
require 'pqueue'

class Enigma
  attr_accessor :id

  def initialize(id)
    self.id = id.to_i
    self.class.all << self
  end

  def watcher
    @watcher ||= Watcher[id]
  end

  def guessed_watches
    if parent_repo_ids.length >= 10
      puts "id:#{id} using parents: #{parent_repo_ids[0,10].join(', ')}"
      return parent_repo_ids[0,10]
    end

    from_correlations = guess_from_correlations

    # select best guesses (poor man's heap)
    top_ten = PQueue.new(10)

    from_correlations.each do |id, weight|
      top_ten.add(weight, [id, weight])
    end

    top_ten = top_ten.to_a

    print "id:#{id} existing:#{watcher.watches.length} guesses(#{from_correlations.length}): "
    puts top_ten[0,10].map{|g| sprintf "%i:%.3f", *g }.join(', ')

    top_ten.map! {|g| g.first }

    (parent_repo_ids + top_ten)[0,10]
  end

  def parent_repos
    @parent_repos ||= begin
      repos = watcher.watches.map {|w| w.repo.parent}.compact.uniq
      repos.reject! {|r| watched_repo_ids.include? r.id }
      repos.sort {|a,b| b.watches.length <=> a.watches.length}
    end
  end

  def parent_repo_ids
    @parent_repo_ids = parent_repos.map {|r| r.id }
  end

  def ancestor_repos
    @ancestor_repos ||= begin
      repos = []

      watcher.watches.each do |watch|
        parent = watch.repo.parent
        until parent.nil?
          repos << parent
          parent = parent.parent
        end
      end

      repos.uniq - watched_repos
    end
  end

  def ancestor_repo_ids
    @ancestor_repo_ids ||= ancestor_repos.map {|r| r.id }
  end

  def watched_repos
    @watched_repos ||= watcher.watches.map {|w| w.repo }
  end

  def watched_repo_ids
    @watched_repo_ids ||= watched_repos.map{|r| r.id }
  end

  def guess_from_correlations
    (watched_repo_ids + ancestor_repo_ids).uniq.inject(Hash.new(0)) do |guesses, repo_id|
      total = (Watch.all_by_repo[repo_id].length rescue 0)
      weighted_total = (total ** 1.5).to_f

      (Watch.correlations[repo_id] || {}).each do |id, weight|
        unless watched_repo_ids.include?(id)
          guesses[id] += ((weight || 0) / weighted_total)
        end
      end

      guesses
    end
  end

  def to_s
    "#{id}:#{guessed_watches.join(',')}"
  end

  class << self
    def all
      @all ||= []
    end
  end
end
