# This file contains magical incantations to interface with the MediaWiki
# API.  This is very much a work in progress so don't count on it not changing
# (for the better).
#
# Check out the source on github http://github.com/schleyfox/wikipedia-api

['hpricot', 'cgi', 'open-uri'].each {|f| require f}


# The MediaWiki class allows one to interface with the MediaWiki API.
# Everything about it is incomplete and I promise that it will eat your kids
# and/or small furry woodland creatures.  These things happen.
#
# == Usage
#
# To use, you construct a MediaWiki object for the site
# 
#   require 'mediawiki'
#   example_wiki = MediaWiki.new("http://example.com/w/api.php")
#
# From here you can query based on title or pageid for individual pages or
# collections
#
#  # By pageid
#  page = example_wiki.find(10)
#  page.title #=> "foo"
#
#  # By title
#  page = example_wiki.find_by_title("foo")
#  page.pageid #=> 10
#
#  # a collection by pageids
#  result = example_wiki.find_by_pageids(10,11)
#  result.pages.collect(&:title) #=> ["foo", "bar"]
#
#  # a collection by titles
#  result = example_wiki.find_by_titles("foo", "bar")
#  result.pages.collect(&:pageid) #=> [10, 11]
#
class MediaWiki
  PROPS = [:info, :revisions, :links, :langlinks, :images, :imageinfo,
    :templates, :categories, :extlinks, :categoryinfo]
  RVPROPS = [:ids, :flags, :timestamp, :user, :size, :comment, :content]


  def initialize(url)
    @url = url
  end

  # find by pageid
  def find(*opts)
    find_by_pageids(opts).pages.first
  end

  # find the articles identified by the Array page_ids
  def find_by_pageids(*opts)
    page_ids, opts_qs = handle_options(opts)
    page_ids_qs = make_qs("pageids", page_ids)
    MediaWikiBase.new(make_url(opts_qs.push(page_ids_qs)))
  end

  # Same as find_by_titles but returns a single page
  def find_by_title(*opts)
    find_by_titles(opts).pages.first
  end

  # find the articles identified by the Array titles
  def find_by_titles(*opts)
    titles, opts_qs = handle_options(opts)
    titles_qs = make_qs("titles", titles)
    MediaWikiBase.new(make_url(opts_qs.push(titles_qs)))
  end

  class MediaWikiBase
  
    attr_accessor :xml, :pages
  
    def initialize(url)
      @xml = Hpricot.XML(open(url))
      @pages = (@xml/:api/:query/:pages/:page).collect{|p| Page.new(p) }
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
        @timestamp = Time.parse(rev.attributes['timestamp'])
        @comment = rev.attributes['comment']
        @content = rev.inner_html
      end
    end
  
  end


  protected
  def make_url(*opts)
    @url + "?" + (["action=query", "format=xml"] + opts).join('&')
  end

  def handle_options(opts)
    arr = opts.delete_if{|o| o.is_a? Hash}
    hash = (opts - arr).first
    [arr, handle_opts_hash(hash)]
  end

  def handle_opts_hash(opts)
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

  def make_qs(name, collection)
    "#{name}=#{CGI.escape(collection.join('|'))}"
  end
end


