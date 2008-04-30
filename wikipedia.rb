require 'mediawiki'

# The Wikipedia constant allows the use of Wikipedia's Query API from Ruby
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
Wikipedia = MediaWiki.new("http://en.wikipedia.org/w/api.php") 
