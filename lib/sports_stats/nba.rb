module NBA
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