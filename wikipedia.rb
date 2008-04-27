['hpricot', 'cgi', 'open-uri'].each {|f| require f}

class Wikipedia
  BASE_URL = 'http://en.wikipedia.org/w/api.php?format=xml&'
  #OPTS = [:revids, :prop]
  PROPS = [:info, :revisions, :links, :langlinks, :images, :imageinfo,
    :templates, :categories, :extlinks, :categoryinfo]
  RVPROPS = [:ids, :flags, :timestamp, :user, :size, :comment, :content]

  attr_accessor :xml, :pages

  def initialize(url)
    @xml = Hpricot.XML(open(url))
    @pages = (@xml/:api/:query/:pages/:page).collect{|p| Page.new(p) }
  end

  def self.find_by_pageids(page_ids, opts = nil)
    opts_qs = handle_options(opts)
    page_ids_qs = make_qs("pageids", page_ids)
    Wikipedia.new(make_url(opts_qs.push(page_ids_qs)))
  end

  def self.find_by_titles(titles, opts = nil)
    opts_qs = handle_options(opts)
    titles_qs = make_qs("titles", titles)
    Wikipedia.new(make_url(opts_qs.push(titles_qs)))
  end

  class Page
    attr_accessor *PROPS

    def initialize(page)
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
