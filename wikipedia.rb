# This file contains magical incantations to interface with the new Wikipedia
# API.  This is very much a work in progress so don't count on it not changing
# (for the better).
#
# Check out the source on github http://github.com/schleyfox/wikipedia-api

['hpricot', 'cgi', 'open-uri'].each {|f| require f}

# The Wikipedia class allows the use of Wikipedia's Query API from Ruby
# The wrapping is incomplete and the interface will be cleaned up as work is
# done.
#
# == Usage
#
# The simplest case is just finding pages by title.  The Wikipedia API allows
# requests to be on multiple titles or ids, so this wrapping returns an array of
# pages
#
#   require 'wikipedia'
#   page = Wikipedia.find_by_titles('Foo').pages.first
#   page.title #=> "Foo"
#
# Pages can also be found based on pageid
# 
#   page = Wikipedia.find_by_pageids(10).pages.first
#   page.title #=> "AccessibleComputing"
#
# Further API options can be specified in the optional second parameter to
# find_by_*.  This can be used to limit the fetching of unnecessary data
#
#   page = Wikipedia.find_by_titles('Foo', :prop => [:langlinks]).pages.first
#   page.langlinks #=> ["da", "fi", "it", "no", "sl", "vi"]
#
class Wikipedia
  BASE_URL = 'http://en.wikipedia.org/w/api.php?format=xml&'
  PROPS = [:info, :revisions, :links, :langlinks, :images, :imageinfo,
    :templates, :categories, :extlinks, :categoryinfo]
  RVPROPS = [:ids, :flags, :timestamp, :user, :size, :comment, :content]

  attr_accessor :xml, :pages

  def initialize(url)
    @xml = Hpricot.XML(open(url))
    @pages = (@xml/:api/:query/:pages/:page).collect{|p| Page.new(p) }
  end

  # find the articles identified by the Array page_ids
  def self.find_by_pageids(*opts)
    page_ids, opts_qs = handle_options(opts)
    page_ids_qs = make_qs("pageids", page_ids)
    Wikipedia.new(make_url(opts_qs.push(page_ids_qs)))
  end

  # find the articles identified by the Array titles
  def self.find_by_titles(*opts)
    titles, opts_qs = handle_options(opts)
    titles_qs = make_qs("titles", titles)
    Wikipedia.new(make_url(opts_qs.push(titles_qs)))
  end

  # Page encapsulates the properties of wikipedia page.
  class Page
    attr_accessor *PROPS
    attr_accessor :title, :pageid

    def initialize(page)
      @title = page.attributes['title']
      @pageid = page.attributes['pageid']
      @links = (page/:links/:pl).collect{|pl| pl.attributes['title']}
      @langlinks = (page/:langlinks/:ll).collect{|ll| ll.attributes['lang']}
      @images = (page/:images/:im).collect{|im| im.attributes['title']}
      @templates = (page/:templates/:tl).collect{|tl| tl.attributes['title']}
      @extlinks = (page/:extlinks/:el).collect{|el| el.inner_html}
      @revisions = (page/:revisions/:rev).collect{|rev| Revision.new(rev)}
    end
  end

  class Revision
    attr_accessor *RVPROPS
    attr_accessor :revid

    def initialize(rev)
      @revid = rev.attributes['revid']
      @user = rev.attributes['user']
      @timestamp = DateTime.parse(rev.attributes['timestamp'])
      @comment = rev.attributes['comment']
      @content = rev.inner_html
    end
  end

  protected
  def self.make_url(*opts)
    BASE_URL + (["action=query"] + opts).join('&')
  end

  def self.handle_options(opts)
    arr = opts.delete_if{|o| o.is_a? Hash}
    hash = (opts - arr).first
    [arr, handle_opts_hash(hash)]
  end

  def self.handle_opts_hash(opts)
    opts ||= {}
    res = []

    opts[:prop] ||= PROPS
    opts[:prop] = opts[:prop] & PROPS
    res << make_qs("prop", opts[:prop])
    
    if opts[:revids]
      res << make_qs("revids", opts[:revids])
    end

    if opts[:rvprop] 
      opts[:rvprop] = opts[:rvprop] & RVPROPS
      res << make_qs("rvprop", opts[:rvprop])
    end

    res
  end

  def self.make_qs(name, collection)
    "#{name}=#{CGI.escape(collection.join('|'))}"
  end
end
