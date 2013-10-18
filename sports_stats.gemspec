Gem::Specification.new do |s|
  s.name = 'sports_stats'
  s.version = '0.0.1'
  s.date = '2013-10-17'
  s.summary = 'Get stats for teams and players'
  s.description = 'Search for your favorite teams or players in any league or get all stats.'
  s.authors = ['Matt Dziuban']
  s.email = 'mrdziuban@gmail.com'
  s.files = ['lib/sports_stats.rb',
    'lib/sports_stats/nhl.rb']
  s.homepage = 'http://github.com/mrdziuban/sports_stats'
  s.license = 'MIT'
  s.add_dependency 'nokogiri'
  s.add_dependency 'i18n'
end
