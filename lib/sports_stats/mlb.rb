require 'nokogiri'
require 'open-uri'
require 'active_support/inflector'

module MLB
  class Player
    def self.search(options = {})
      options[:year] ||= 2013
      options[:season] ||= "season"
      url = "http://sports.yahoo.com/mlb/stats/byposition?pos=C,1B,2B,SS,3B,LF,CF,RF,DH&conference=MLB&year=#{options[:season]}_#{options[:year]}&qualified=0"
      page = Nokogiri::HTML(open(url))
      table = page.css("table")[4]

      if options[:name]
        rows = table.search("[text()*='#{options[:name].titleize}']")
        self.build_stats_hash(rows.map{|row| row.parent.parent})
      else
        self.build_stats_hash(table.css(".ysprow1, .ysprow2"))
      end
    end

    def self.build_stats_hash(rows)
      stats = {}
      keys = [:team_abbrev, :games_played, :at_bats, :runs, :hits, :doubles,
              :triples, :home_runs, :RBIs, :walks, :strikeouts,
              :stolen_bases, :batting_avg, :obp, :slg]

      rows.each do |row|
        player = row.css("td")[1].text.strip
        stats[player] = {}
        player_stats = []

        row.css("td").each_with_index do |td, i|
          skips = (4..32).step(2).to_a
          skips += [0, 1, 25, 33]
          next if skips.include?(i)
          if i == 2
            player_stats << td.text.strip
          elsif i.between?(3,25)
            player_stats << td.text.strip.to_i
          else
            player_stats << td.text.strip.to_f
          end
        end

        keys.each_with_index do |key, i|
          stats[player][key] = player_stats[i]
        end
      end

      Hash[stats.sort_by {|p,v| p.split(" ")[1]}]
    end
  end

  class Pitcher
    def self.search(options = {})
      options[:year] ||= 2013
      options[:season] ||= "season"
      url = "http://sports.yahoo.com/mlb/stats/byposition?pos=SP,RP&conference=MLB&year=#{options[:season]}_#{options[:year]}&qualified=0"
      page = Nokogiri::HTML(open(url))
      table = page.css("table")[4]

      if options[:name]
        rows = table.search("[text()*='#{options[:name].titleize}']")
        self.build_stats_hash(rows.map {|row| row.parent.parent})
      else
        self.build_stats_hash(table.css(".ysprow1, .ysprow2"))
      end
    end

    def self.build_stats_hash(rows)
      stats = {}
      keys = [:team_abbrev, :games_played, :starts, :wins, :losses, :saves,
              :blown_saves, :complete_games, :shutouts, :innings, :hits,
              :runs, :earned_runs, :home_runs, :walks, :strikeouts, :era, :whip,
              :batting_avg_against]

      rows.each do |row|
        player = row.css("td")[1].text.strip
        stats[player] = {}
        player_stats = []

        row.css("td").each_with_index do |td, i|
          skips = (4..38).step(2).to_a
          skips += [0, 1, 15]
          next if skips.include?(i)
          if i == 2
            player_stats << td.text.strip
          elsif ![21, 35, 37, 39].include?(i)
            player_stats << td.text.strip.to_i
          else
            player_stats << td.text.strip.to_f
          end
        end

        keys.each_with_index do |key, i|
          stats[player][key] = player_stats[i]
        end
      end

      Hash[stats.sort_by {|p,v| p.split(" ")[1]}]
    end
  end
end