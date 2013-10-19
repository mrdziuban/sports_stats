module MLB
  TEAMS = {
    "red sox" => "Boston",
    "rays" => "tampa bay",
    "yankees" => "NY Yankees",
    "orioles" => "Baltimore",
    "blue jays" => "Toronto",
    "tigers" => "Detroit",
    "indians" => "Cleveland",
    "royals" => "Kansas City",
    "twins" => "Minnesota",
    "white sox" => "Chicago Sox",
    "athletics" => "Oakland",
    "rangers" => "Texas",
    "angels" => "LA Angels",
    "mariners" => "Seattle",
    "astros" => "Houston",
    "braves" => "Atlanta",
    "nationals" => "Washington",
    "mets" => "NY Mets",
    "phillies" => "Philadelphia",
    "marlins" => "Miami",
    "florida" => "Miami",
    "cardinals" => "St. Louis",
    "pirates" => "Pittsburgh",
    "reds" => "Cincinnati",
    "brewers" => "Milwaukee",
    "cubs" => "Chicago Cubs",
    "dodgers" => "LA Dodgers",
    "diamondbacks" => "Arizona",
    "giants" => "San Francisco",
    "padres" => "San Diego",
    "rockies" => "Colorado"
  }
  
  class Team
    def self.search(options = {})
      @@year = options[:year] || 2013
      @@year = @@year.to_i
      url = "http://espn.go.com/mlb/standings/_/year/#{@@year}"
      page = Nokogiri::HTML(open(url))
      table = page.css(".tablehead")

      if options[:league]
        @@league = options[:league].titleize
        if @@league == "American" || @@league == "American League"
          all_rows = table.css("tr")
          rows = all_rows[2..6] + all_rows[8..12] + all_rows[14..18]
        elsif @@league == "National" || @@league == "National League"
          all_rows = table.css("tbody > tr")
          rows = all_rows[21..25] + all_rows[27..31] + all_rows[33..37]
        else
          return "That's not a league! Try 'American' or 'National'" unless ["American League", "National League"].include?(@@league)
        end
        self.build_conference_hash(rows)
      elsif options[:name]
        if TEAMS.values.include?(options[:name].titleize)
          team = options[:name].titleize
        else
          return "Couldn't find that team!" unless TEAMS[options[:name].downcase]
          team = TEAMS[options[:name].downcase]
        end

        self.build_stats_hash([table.search("[text()*='#{team}']")[0].parent.parent])
      else

      end
    end

    def self.build_stats_hash(rows)
      stats = {}
      keys = [:wins, :losses, :percentage, :games_back, :home_record,
              :away_record, :runs_scored, :runs_allowed, :diff, :streak, :last_10]

      rows.each_with_index do |row, i|
        team = row.css("td")[0].text.strip
        team = team[2..-1] if ["x", "y", "z", "*"].include?(team[0])
        stats[team] = {}
        team_stats = []

        row.css("td").each_with_index do |td, j|
          next if j == 0
          if [1,2,7,8,9].include?(j)
            team_stats << td.text.strip.to_i
          elsif [3,4].include?(j)
            team_stats << td.text.strip.to_f
          elsif j == 10
            streak = td.text.strip
            streak[4] = ""
            team_stats << streak
          else
            team_stats << td.text.strip
          end
        end

        keys.each_with_index do |key, k|
          stats[team][key] = team_stats[k]
        end
      end

      stats
    end

    def self.build_conference_hash(rows)
      stats = {}
      keys = [:wins, :losses, :percentage, :games_back, :home_record,
              :away_record, :runs_scored, :runs_allowed, :diff, :streak, :last_10]

      rows.each_with_index do |row, i|
        division = get_division(i)
        stats[division] ||= {}
        team = row.css("td")[0].text.strip
        team = team[2..-1] if ["x", "y", "z", "*"].include?(team[0])
        stats[division][team] = {}
        team_stats = []

        row.css("td").each_with_index do |td, j|
          next if j == 0
          if [1,2,7,8,9].include?(j)
            team_stats << td.text.strip.to_i
          elsif [3,4].include?(j)
            team_stats << td.text.strip.to_f
          elsif j == 10
            streak = td.text.strip
            streak[4] = ""
            team_stats << streak
          else
            team_stats << td.text.strip
          end
        end

        keys.each_with_index do |key, k|
          stats[division][team][key] = team_stats[k]
        end
      end

      stats
    end

    def self.get_division(i)
      case i
      when 0..4 then return "East"
      when 5..9 then return "Central"
      when 10..14 then return "West"
      end
    end
  end


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