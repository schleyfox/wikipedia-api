['hpricot', 'cgi', 'open-uri'].each {|f| require f}

class Wikipedia
  BASE_URL = 'http://en.wikipedia.org/w/api.php?format=xml&'
  OPTS = [:revids, :prop]
  PROPS = [:info, :revisions, :links, :langlinks, :images, :imageinfo,
    :templates, :categories, :extlinks, :categoryinfo]

  attr_accessor :xml, :pages

  def initialize(url)
    @xml = Hpricot.XML(open(url))
    @pages = (@xml/:api/:query/:pages/:page).collect{|p| Page.new(p) }
  end

  def self.find_by_pageids(page_ids, opts = nil)
    opts_qs = handle_options(opts)
    page_ids_qs = "pageids=#{CGI.escape(page_ids.join('|'))}"
    Wikipedia.new(make_url(opts_qs.push(page_ids_qs)))
  end

  def self.find_by_titles(titles, opts = nil)
    opts_qs = handle_options(opts)
    titles_qs = "titles=#{CGI.escape(titles.join('|'))}"
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
    end

  end

  protected
  def self.make_url(*opts)
    BASE_URL + (["action=query"] + opts).join('&')
  end

  def self.handle_options(opts)
    opts ||= {}
    opts[:prop] ||= PROPS
    opts[:prop] = opts[:prop] & PROPS
    res = ["prop=#{CGI.escape(opts[:prop].join('|'))}"]
    res << "revids=#{CGI.escape(opts[:revids].join('|'))}" if opts[:revids]
    res
  end
end
