module NBA
  TEAMS = {
    "knicks" => "New York",
    "nets" => "Brooklyn",
    "new jersey" => "Brooklyn",
    "celtics" => "Boston",
    "76ers" => "Philadelphia",
    "raptors" => "Toronto",
    "pacers" => "Indiana",
    "bulls" => "Chicago",
    "bucks" => "Milwaukee",
    "pistons" => "Detroit",
    "cavaliers" => "Cleveland",
    "heat" => "Miami",
    "hawks" => "Atlanta",
    "wizards" => "Washington",
    "bobcats" => "Charlotte",
    "magic" => "Orlando",
    "clippers" => "LA Clippers",
    "warriors" => "Golden State",
    "lakers" => "LA Lakers",
    "kings" => "Sacramento",
    "suns" => "Phoenix",
    "spurs" => "San Antonio",
    "grizzlies" => "Memphis",
    "rockets" => "Houston",
    "mavericks" => "Dallas",
    "pelicans" => "New Orleans",
    "hornets" => "New Orleans",
    "thunder" => "Oklahoma City",
    "nuggets" => "Denver",
    "jazz" => "Utah",
    "trail blazers" => "Portland",
    "timberwolves" => "Minnesota"
  }

  class Team
    def self.search(options = {})
      options[:year] ||= 2012
      url = "http://sports.yahoo.com/nba/standings/?season=#{options[:year]}"
      page = Nokogiri::HTML(open(url))
      div = page.css("div.yom-tabview")

      if options[:conference]
        @@conference = options[:conference].titleize
        @@conference += "ern" unless @@conference[-3..-1] == "ern"
        table1 = div.search("[text()*='#{@@conference}']")[0].next_element
        table1_rows = table1.css("tbody > tr")
        table2 = table1.next_element.next_element
        table2_rows = table2.css("tbody > tr")
        table3_rows = table2.next_element.next_element.css("tbody > tr")
        self.build_conference_hash(table1_rows + table2_rows + table3_rows)
      elsif options[:division]
        rows = div.css("table[summary=#{options[:division].titleize}] > tbody > tr")
        self.build_stats_hash(rows)
      elsif options[:name]
        if TEAMS.values.include?(options[:name].titleize)
          team = options[:name].titleize
        else
          return "Couldn't find that team!" unless TEAMS[options[:name].downcase]
          team = TEAMS[options[:name].downcase]
        end

        self.build_stats_hash([div.search("[text()*='#{team}']")[0].parent.parent])
      else
        tables = div.css("table > tbody")
        rows = tables.map {|t| t.css("tr")}.flatten
        self.build_stats_hash(rows)
      end
    end

    def self.build_stats_hash(rows)
      stats = {}
      keys = [:wins, :losses, :percentage, :games_back, :home_record,
      :away_record, :division_record, :conference_record, :last_10,
      :points_for, :points_allowed, :diff, :streak]

      rows.each do |row|
        team = row.css("th > a").text.strip
        team = team[2..-1] if ["x", "y", "z"].include?(team[0])
        stats[team] = {}
        team_stats = []

        row.css("td").each_with_index do |td, j|
          next if j == 4
          if [0,1,3].include?(j)
            team_stats << td.text.strip.to_i
          elsif [2,10,11,12].include?(j)
            team_stats << td.text.strip.to_f
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
      :away_record, :division_record, :conference_record, :last_10,
      :points_for, :points_allowed, :diff, :streak]
      return "That's not a conference! Try 'East' or 'West'" unless ["Eastern", "Western"].include?(@@conference)

      rows.each_with_index do |row, i|
        division = get_division(i)
        stats[division] ||= {}
        team = row.css("th > a").text.strip
        team = team[2..-1] if ["x", "y", "z"].include?(team[0])
        stats[division][team] = {}
        team_stats = []

        row.css("td").each_with_index do |td, j|
          next if j == 4
          if [0,1,3].include?(j)
            team_stats << td.text.strip.to_i
          elsif [2,10,11,12].include?(j)
            team_stats << td.text.strip.to_f
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
      if @@conference == "Eastern"
        case i
        when 0..4 then return "Atlantic"
        when 5..9 then return "Central"
        when 10..14 then return "Southeast"
        end
      else
        case i
        when 0..4 then return "Pacific"
        when 5..9 then return "Southwest"
        when 10..14 then return "Northwest"
        end
      end
    end
  end

  class Player
    def self.search(options = {})
      options[:year] ||= 2012
      options[:season] ||= "season"
      url = "http://sports.yahoo.com/nba/stats/byposition?pos=PG%2CSG%2CG%2CGF%2CSF%2CPF%2CF%2CFC%2CC&sort=25&qualified=0&conference=NBA&year=#{options[:season]}_#{options[:year]}"
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
      keys = [:team_abbrev, :games_played, :minutes, :fg_made, :fg_attempted, :fg_pct,
              :three_pt_made, :three_pt_attempted, :three_pt_pct,
              :ft_made, :ft_attempted, :ft_pct, :offensive_rebounds,
              :defensive_rebounds, :total_rebounds, :assists, :turnovers,
              :steals, :blocks, :fouls, :points_per_game]

      rows.each do |row|
        player = row.css("td")[0].text.strip[1..-1]
        stats[player] = {}
        player_stats = []

        row.css("td").each_with_index do |td, i|
          next if [0,7,11,15,19].include?(i)
          if i == 1
            player_stats << td.text.strip
          elsif i == 2
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