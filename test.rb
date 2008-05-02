require 'test/unit'
require 'rubygems'
require 'shoulda'
require 'mediawiki'

class MediaWiki
  class MediaWikiBase
    def get_xml(url)
      Hpricot.XML(open('sample.xml'))
    end
  end
end

class MediaWikiTest < Test::Unit::TestCase
  def setup
    @mw = MediaWiki.new("http://mock.com/api.php")
  end

  context "MediaWiki interface" do
    should("find article by id"){ assert @mw.find(10) }
    should("find article by title"){ assert @mw.find_by_title("Foo") }
    should("find articles by ids"){ assert @mw.find_by_pageids(10,11) }
    should("find articles by titles"){ assert @mw.find_by_titles("Foo","Bar") }
  end

  context "MediaWiki base" do
    should("have xml"){ assert @mw.find_by_titles("Foo").xml }
    should("have pages"){ assert @mw.find_by_titles("Foo").pages }
  end

  context "MediaWiki pages" do
  end
end

