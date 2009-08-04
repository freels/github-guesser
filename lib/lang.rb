require 'monkey'
require 'repo'

class Lang
  attr_accessor :lang, :repo_id, :lines

  def initialize(lang, repo_id, lines)
    self.lang = lang
    self.repo_id = repo_id
    self.lines = lines

    self.class.all << self
    self.class.all_by_lang[lang] << self
    self.class.all_by_repo[repo_id] << self
    self.class.all_by_repo[repo_id].sort! {|a,b| b.lines <=> a.lines }
  end

  def repo
    @repo ||= Repo[repo_id]
  end

  class << self
    def parse(data)
      repo_id, langs = data.split(':')
      langs.split(',').map{|l| l.split(';')}.each do |lang,lines|
        new(lang, repo_id.to_i, lines.to_i)
      end
    end

    def all
      @all ||= []
    end

    def [](lang)
      all_by_lang[lang]
    end

    def all_by_lang[lang]
      @all_by_lang ||= Hash.new {|h,k| h[k] = [] }
    end

    def all_by_repo
      @all_by_repo ||= Hash.new {|h,k| h[k] = [] }
    end
  end
end
