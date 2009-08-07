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
    guess_time = Time.now.to_i
    guesses = merge_guesses!(guess_from_correlations, guess_from_parents)
    guess_time = Time.now.to_i - guess_time

    watches_filter = watcher.watches.inject({}) {|f, w| f[w.repo_id] = true; f }

    # select best guesses (poor man's heap)
    top_ten = PQueue.new(10)

    sort_time = Time.now.to_i
    guesses.each do |id, prob|
      next if watches_filter[id]
      popularity = Watch.all_by_repo[id].length
      top_ten.add(prob, popularity, [id, prob])
    end
    sort_time = Time.now.to_i - sort_time

    top_ten = top_ten.to_a

    puts "id:#{id} existing:#{watcher.watches.length} guesses(#{guesses.length}): "
    puts top_ten.map{|g| sprintf "    %6i: %.30f", *g }.join("\n")
    puts "  seconds elapsed: #{guess_time} (guesses), #{sort_time} (sort)" 

    top_ten.map {|g| g.first }
  end

  SIGNIFICANCE = 10
  PENALTY = 0.15
  MAX = 0.75
  BLEED = 1e-6

  def self.normalize_correlations!
    return if @normalized_correlations
    @normalized_correlations = true

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

      guesses.merge!(addon) do|k,a,b| p = (MAX - (MAX - a) * (MAX - b))
        if a >= MAX or b >= MAX
          (a + b) / 2.0 + BLEED
        else
          (MAX - (MAX - a) * (MAX - b))
        end
      end
      guesses
    end
  end

  PARENT_PROBABILITY = 0.95

  def guess_from_parents
    repos = watcher.watches.map {|w| w.repo.parent.id if w.repo.parent }.compact
    guesses = {}

    repos.each do |repo_id|
      if guesses[repo_id]
        guesses[repo_id] = prob_or(guesses[repo_id], PARENT_PROBABILITY)
      else
        guesses[repo_id] = PARENT_PROBABILITY
      end
    end

    guesses
  end

  def to_s
    "#{id}:#{guessed_watches.join(',')}"
  end

  private

  def prob_or(a,b)
    1.0 - (1.0 - a) * (1.0 - b)
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
