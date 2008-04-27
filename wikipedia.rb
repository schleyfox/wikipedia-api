['hpricot', 'cgi', 'open-uri'].each {|f| require f}

class Wikipedia
  BASE_URL = 'http://en.wikipedia.org/w/api.php?format=xml&'
  PROPS = [:info, :revisions, :links, :langlinks, :images, :imageinfo,
    :templates, :categories, :extlinks, :categoryinfo]

  attr_accessor :xml, :pages

  def initialize(url)
    @xml = Hpricot.XML(open(url))
    @pages = (@xml/:api/:query/:pages/:page).collect{|p| Page.new(p) }
  end

  def self.find(page_ids, props = nil)
    props ||= PROPS
    props = props & PROPS
    page_id_qs = "pageids=#{CGI.escape(page_ids.join('|'))}"
    props_qs = "prop=#{CGI.escape(props.join('|'))}"
    Wikipedia.new(make_url(page_id_qs, props_qs))
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
end
