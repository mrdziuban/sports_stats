# require_relative 'tickets'

module NHL
  TEAMS = {
    "canadiens" => "Montreal",
    "bruins" => "Boston",
    "maple leafs" => "Toronto",
    "senators" => "Ottawa",
    "sabres" => "Buffalo",
    "penguins" => "Pittsburgh",
    "rangers" => "NY Rangers",
    "islanders" => "NY Islanders",
    "flyers" => "Philadelphia",
    "devils" => "New Jersey",
    "capitals" => "Washington",
    "jets" => "Winnipeg",
    "thrashers" => "Atlanta",
    "hurricanes" => "Carolina",
    "lightning" => "Tampa Bay",
    "panthers" => "Florida",
    "blackhawks" => "Chicago",
    "blues" => "St. Louis",
    "red wings" => "Detroit",
    "blue jackets" => "Columbus",
    "predators" => "Nashville",
    "ducks" => "Anaheim",
    "kings" => "Los Angeles",
    "sharks" => "San Jose",
    "coyotes" => "Phoenix",
    "stars" => "Dallas",
    "canucks" => "Vancouver",
    "wild" => "Minnesota",
    "oilers" => "Edmonton",
    "flames" => "Calgary",
    "avalanche" => "Colorado"
  }

  # TEAM_ABBREVS = {
  #   "boston" => :BOS,
  #   "buffalo" => :BUF,
  #   "calgary" => :CGY,
  #   "chicago" => :CHI,
  #   "detroit" => :DET,
  #   "edmonton" => :EDM,
  #   "carolina" => :CAR,
  #   "los angeles" => :LOS,
  #   "montreal" => :MON,
  #   "dallas" => :DAL,
  #   "new jersey" => :NJD,
  #   "ny islanders" => :NYI,
  #   "ny rangers" => :NYR,
  #   "philadelphia" => :PHI,
  #   "pittsburgh" => :PIT,
  #   "colorado" => :COL,
  #   "st. louis" => :STL,
  #   "toronto" => :TOR,
  #   "vancouver" => :VAN,
  #   "washington" => :WAS,
  #   "phoenix" => :PHO,
  #   "san jose" => :SJS,
  #   "ottawa" => :OTT,
  #   "tampa bay" => :TAM,
  #   "anaheim" => :ANA,
  #   "florida" => :FLA,
  #   "winnipeg" => :WPG,
  #   "columbus" => :CBJ,
  #   "minnesota" => :MIN,
  #   "nashville" => :NSH
  # }


  # class Standings1213
  #   def self.scrape
  #     standings_url = "http://www.nhl.com/ice/standings.htm?type=DIV#&navid=nav-stn-div"
  #     standings_page = Nokogiri::HTML(open(standings_url))
  #     standings_tables = standings_page.css(".data.standings.Division")
  #     standings_hash = {}
  #     keys = [:GP, :W, :L, :OT, :P, :ROW, :GF, :GA, :DIFF, :HOME, :AWAY, :SO, :L10, :STREAK]

  #     standings_tables.each do |t|
  #       division = (t.css("th")[1].text).to_sym
  #       standings_hash[division] = {}
  #       t.css("tbody tr").each do |tr|
  #         team = (tr.css("a")[1].text).strip
  #         team = I18n.transliterate(team)
  #         team = TEAM_ABBREVS[team.downcase]
  #         standings_hash[division][team] = {}
  #         val = nil
  #         (2..15).each do |i|
  #           key = t.css("th")[i].css("a").text.strip
  #           if key == "S/O"
  #             key = "SO"
  #           end
  #           if i.between?(2,9)
  #             val = tr.css("td")[i].text.strip.to_i
  #           else
  #             val = tr.css("td")[i].text.strip
  #           end
  #           standings_hash[division][team][key.to_sym] = val
  #         end
  #       end
  #     end

  #     return standings_hash
  #   end
  # end


  class Team
    def self.search(options = {})
      @@year = options[:year] || 2013
      @@year = @@year.to_i
      url = "http://sports.yahoo.com/nhl/standings/?season=#{@@year}"
      page = Nokogiri::HTML(open(url))
      div = page.css("div.yom-tabview")

      if options[:conference]
        @@conference = options[:conference].titleize
        @@conference += "ern" unless @@conference[-3..-1] == "ern"
        table1 = div.search("[text()*='#{@@conference}']")[0].next_element
        table1_rows = table1.css("tbody > tr")
        table2 = table1.next_element.next_element
        table2_rows = table2.css("tbody > tr")
        if @@year < 2013
          table3_rows = table2.next_element.next_element.css("tbody > tr")
          self.build_conference_hash(table1_rows + table2_rows + table3_rows)
        else
          self.build_conference_hash(table1_rows + table2_rows)
        end
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
      keys = [:games_played, :wins, :losses, :ot_losses, :points, :goals_for,
              :goals_against, :diff, :home_record, :away_record, :last_10, :streak]

      rows.each_with_index do |row, i|
        team = row.css("th > a").text.strip
        team = team[2..-1] if ["x", "y", "z"].include?(team[0])
        stats[team] = {}
        team_stats = []

        row.css("td").each_with_index do |td, j|
          j.between?(0,7) ? team_stats << td.text.strip.to_i : team_stats << td.text.strip
        end

        keys.each_with_index do |key, k|
          stats[team][key] = team_stats[k]
        end
      end

      stats
    end

    def self.build_conference_hash(rows)
      stats = {}
      keys = [:games_played, :wins, :losses, :ot_losses, :points, :goals_for,
              :goals_against, :diff, :home_record, :away_record, :last_10, :streak]
      return "That's not a conference! Try 'East' or 'West'" if @@conference != "Eastern" && @@conference != "Western"
      
      rows.each_with_index do |row, i|
        division = get_division(i)
        stats[division] ||= {}
        team = row.css("th > a").text.strip
        team = team[2..-1] if ["x", "y", "z"].include?(team[0])
        stats[division][team] = {}
        team_stats = []

        row.css("td").each_with_index do |td, j|
          j.between?(0,7) ? team_stats << td.text.strip.to_i : team_stats << td.text.strip
        end

        keys.each_with_index do |key, k|
          stats[division][team][key] = team_stats[k]
        end
      end

      stats
    end

    def self.get_division(i)
      if @@conference == "Eastern"
        if @@year == 2013
          return i.between?(0,7) ? "Atlantic" : "Metropolitan"
        else
          case i
          when 0..4 then return "Northeast"
          when 5..9 then return "Atlantic"
          when 10..14 then return "Southeast"
          end
        end
      else
        if @@year == 2013
          return i.between?(0,6) ? "Central" : "Pacific"
        else
          case i
          when 0..4 then return "Central"
          when 5..9 then return "Pacific"
          when 10..14 then return "Northwest"
          end
        end
      end
    end
  end


  class Player
    def self.search(options = {})
      options[:year] ||= 2013
      options[:season] ||= "season"
      url = "http://sports.yahoo.com/nhl/stats/byposition?pos=C%2CRW%2CLW%2CD&sort=14&conference=NHL&year=#{options[:season]}_#{options[:year]}"
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
      keys = [:team_abbrev, :games_played, :goals, :assists, :points, :plus_minus,
              :penalty_minutes, :hits, :blocks, :faceoff_perc, :power_play_goals,
              :shots, :shot_perc]

      rows.each do |row|
        player = row.css("td")[0].text.strip[1..-1]
        stats[player] = {}

        player_stats = []

        row.css("td").each_with_index do |td, i|
          skips = (3..37).step(2).to_a
          skips += [0, 18, 20, 26, 28, 30, 32]
          next if skips.include?(i)
          if i == 1
            team = td.text.strip
            if team == "COB"
              team = "CBJ"
            end
            if team == "NAS"
              team = "NSH"
            end
            player_stats << team
          elsif i.between?(2,20) || i.between?(24,34)
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


  class Goalie
    def self.search(options = {})
      options[:year] ||= 2013
      options[:season] ||= "season"
      url = "http://sports.yahoo.com/nhl/stats/byposition?pos=G&sort=102&conference=NHL&year=#{options[:season]}_#{options[:year]}"
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
      keys = [:team_abbrev, :games_played, :starts, :minutes, :wins, :losses,
              :ot_losses, :goals_allowed, :goals_against_avg, :saves_attempted,
              :saves, :save_perc, :shutouts]

      rows.each do |row|
        player = row.css("td")[0].text.strip[1..-1]
        stats[player] = {}

        player_stats = []

        row.css("td").each_with_index do |td, i|
          skips = (3..27).step(2).to_a
          skips += [0, 14]
          next if skips.include?(i)
          if i == 1
            team = td.text.strip
            if team == "COB"
              team = "CBJ"
            end
            if team == "NAS"
              team = "NSH"
            end
            player_stats << team
          elsif i == 18 || i == 24
            player_stats << td.text.strip.to_f
          else
            player_stats << td.text.strip.to_i
          end
        end

        keys.each_with_index do |key, i|
          stats[player][key] = player_stats[i]
        end
      end

      Hash[stats.sort_by {|p,v| p.split(" ")[1]}]
    end
  end


  class GameStats1213
    def self.scrape
      game_stats_url = "http://www.nhl.com/ice/schedulebyseason.htm?season=20122013&gameType=2&team=&network=&venue="
      game_stats_page = Nokogiri::HTML(open(game_stats_url))
      game_stats_table = game_stats_page.css(".data.schedTbl")
      game_stats_hash = {}

      (game_stats_table.css("tr").length - 1).times do |i|
        game_stats_hash[i + 1] = {}
      end

      game_stats_table.css("tr").each_with_index do |tr, i|
        next if i == 0
        date = tr.css("td.date .skedStartDateSite").text.strip[4..-1]
        date = Date.parse(date)
        away = tr.css("td.team")[0].css("div a").text.strip
        away = I18n.transliterate(away)
        away = TEAM_ABBREVS[away.downcase]
        home = tr.css("td.team")[1].css("div a").text.strip
        home = I18n.transliterate(home)
        home = TEAM_ABBREVS[home.downcase]
        time = tr.css("td.time .skedStartTimeEST").text.strip[0..-4]
        if date < Date.today
          away_score = tr.css("td.tvInfo span")[0].text.strip.gsub("\n", "")
          home_score = tr.css("td.tvInfo span")[1].text.strip
          result = away_score + " - " + home_score
        else
          result = nil
        end

        game_stats_hash[i][:date] = date.to_s
        game_stats_hash[i][:away] = away
        game_stats_hash[i][:home] = home
        game_stats_hash[i][:time] = time
        game_stats_hash[i][:result] = result
        game_stats_hash[i][:season] = "12-13"
      end

      return game_stats_hash
    end
  end


  # class GameStats1314
  #   def self.scrape
  #     game_stats_url = "http://www.nhl.com/ice/schedulebyseason.htm"
  #     game_stats_page = Nokogiri::HTML(open(game_stats_url))
  #     game_stats_table = game_stats_page.css(".data.schedTbl")
  #     game_stats_hash = {}

  #     1230.times do |i|
  #       game_stats_hash[i + 1] = {}
  #     end

  #     j = 1

  #     game_stats_table.css("tr").each_with_index do |tr, i|
  #       next if i == 0 || tr.css("td").length != 6
  #       date = tr.css("td.date .skedStartDateSite").text.strip[4..-1]
  #       date = Date.parse(date)
  #       away = tr.css("td.team")[0].css(".teamName a").text.strip
  #       away = I18n.transliterate(away)
  #       away = TEAM_ABBREVS[away.downcase]
  #       home = tr.css("td.team")[1].css(".teamName a").text.strip
  #       home = I18n.transliterate(home)
  #       home = TEAM_ABBREVS[home.downcase]
  #       time = tr.css("td.time .skedStartTimeEST").text.strip[0..-4]
  #       if date < Date.today
  #         away_score = tr.css("td.tvInfo span")[0].text.strip.gsub("\n", "")
  #         home_score = tr.css("td.tvInfo span")[1].text.strip
  #         result = away_score + " - " + home_score
  #       else
  #         result = nil
  #       end

  #       game_stats_hash[j][:date] = date.to_s
  #       game_stats_hash[j][:away] = away
  #       game_stats_hash[j][:home] = home
  #       game_stats_hash[j][:time] = time
  #       game_stats_hash[j][:result] = result
  #       game_stats_hash[j][:season] = "13-14"
  #       j += 1
  #     end

  #     return game_stats_hash
  #   end
  # end
end
