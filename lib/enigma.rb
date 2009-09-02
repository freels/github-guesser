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
    guesses = nil
    guess_time = time do
      guesses = merge_guesses!(
        #guess_from_popular_stuff,
        #guess_from_preferred_lang,
        #guess_from_author_projects,
        #guess_from_parents,
        guess_from_neighbors
        #guess_from_correlations
      )
    end

    watches_filter = watcher.watches.inject({}) {|f, w| f[w.repo_id] = true; f }

    # select best guesses (poor man's heap)
    top_ten = PQueue.new(10)

    sort_time = time do
      guesses.each do |id, prob|
        next if watches_filter[id]
        popularity = Watch.all_by_repo[id].length
        top_ten.add(prob, popularity, [id, prob])
      end
    end

    top_ten = top_ten.to_a

    puts "id:#{id} existing:#{watcher.watches.length} guesses(#{guesses.length}): "
    puts top_ten.map{|g| sprintf "    %6i: %.30f", *g }.join("\n")
    puts "  seconds elapsed: #{guess_time} (guesses), #{sort_time} (sort)" 

    top_ten.map {|g| g.first }
  end

  SIGNIFICANCE = 10
  PENALTY = 0.10
  MAX = 0.6
  BLEED = 0#1e-6

  def self.normalize_correlations!
    return if @normalized_correlations
    @normalized_correlations = true

    Watcher.neighbors

    Watch.correlations.each do |repo_id, corr|
      unless corr.empty?
        total = Watch.all_by_repo[repo_id].length
        max_prob = MAX
        max_prob -= (PENALTY / SIGNIFICANCE) * (SIGNIFICANCE - total) if total < SIGNIFICANCE

        corr.keys.each {|k| corr[k] = corr[k] * max_prob / total }
      end
    end
  end

  def guess_from_correlations
    self.class.normalize_correlations!

    #sources = (watcher.repo_ids + watcher.repo_ancestor_ids).uniq
    sources = watcher.repo_ids
    sources.inject({}) do |guesses, repo_id|
      addon = Watch.correlations[repo_id] || {}

      guesses.merge!(addon) do|k,a,b|
        if a >= MAX or b >= MAX
          (a > b ? a : b) + BLEED
        else
          (MAX - (MAX - a) * (MAX - b))
        end
      end
      guesses
    end
  end

  MAX_NEIGHBOR_PROB = 0.9
  NUM_NEIGHBORS = 10
  MIN_SIMILARITY = 0.3

  def guess_from_neighbors
    guesses = {}
    neighbors = watcher.nearest_neighbors(NUM_NEIGHBORS)
    
    neighbors.each do |neighbor_id, shared_watch_count|
      similarity = shared_watch_count.to_f / watcher.watches.length
      next if similarity < MIN_SIMILARITY

      Watcher[neighbor_id].watches.each do |watch|
        repo_id = watch.repo_id
        if guesses[repo_id]
          guesses[repo_id] = prob_or(guesses[repo_id], similarity)
        else
          guesses[repo_id] = similarity
        end
      end
    end

    guesses.keys.each {|k| guesses[k] = MAX_NEIGHBOR_PROB * k }
    guesses
  end

  PARENT_PROB = 0.7

  def guess_from_parents
    repos = watcher.watches.map {|w| w.repo.parent.id if w.repo.parent }.compact
    guesses = {}

    repos.each do |repo_id|
      if guesses[repo_id]
        guesses[repo_id] = prob_or(guesses[repo_id], PARENT_PROB)
      else
        guesses[repo_id] = PARENT_PROB
      end
    end

    guesses
  end

  AUTHOR_MAX = 0.6

  def guess_from_author_projects
    authors = watcher.watches.map {|w| w.repo.owner }
    author_guesses = {}
    authors.each do |author|
      total_watchers = author.repos.inject(0) {|t,r| t + r.watches.length }
      author.repos.each do |repo|
        author_guesses[repo.id] = AUTHOR_MAX * repo.watches.length / total_watchers
      end
    end
    author_guesses
  end

  LANG_PROB = 0.2

  def guess_from_preferred_lang
    langs = watcher.preferred_langs
    return {} if langs.empty?

    total = langs.values.inject{|a,b| a+b }
    max = langs.values.sort.last
    preferred = langs.index(max)
    adjusted_prob = LANG_PROB * max / total

    Lang.all_by_name[preferred].inject({}) do |guesses, lang|
      guesses[lang.repo_id] = adjusted_prob
      guesses
    end
  end

  POP_PROB = 0.001

  def guess_from_popular_stuff
    Repo.most_popular.inject({}) {|g,r| g[r.id] = POP_PROB; g }
  end

  def to_s
    "#{id}:#{guessed_watches.join(',')}"
  end

  private

  def prob_or(a,b)
    1.0 - (1.0 - a) * (1.0 - b)
  end

  def time
    start = Time.now
    yield
    Time.now.to_i - start.to_i
  end

  def merge_guesses!(*guess_hashes)
    guess_hashes.inject do |guesses, addon|
      guesses.merge!(addon) {|k,a,b| prob_or(a,b) }
      guesses
    end
  end

  class << self
    def all
      @all ||= []
    end
  end
end
