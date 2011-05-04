module ThumbsUp
  module ActsAsVoteable #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_voteable
        has_many :votes, :as => :voteable, :dependent => :destroy

        include ThumbsUp::ActsAsVoteable::InstanceMethods
        extend  ThumbsUp::ActsAsVoteable::SingletonMethods
      end
    end

    module SingletonMethods

      # The point of this function is to return rankings based on the difference between up and down votes
      # assuming equal weighting (i.e. a user with 1 up vote and 1 down vote has a Vote_Total of 0.
      # First the votes table is joined twiced so that the Vote_Total can be calculated for every ID
      # Then this table is joined against the specific table passed to this function to allow for
      # ranking of the items within that table based on the difference between up and down votes.
            # Options:
      #  :start_at    - Restrict the votes to those created after a certain time
      #  :end_at      - Restrict the votes to those created before a certain time
      #  :conditions  - A piece of SQL conditions to add to the query
      #  :limit       - The maximum number of voteables to return
      #  :ascending   - Default false - normal order DESC (i.e. highest rank to lowest)
      #  :at_least    - Item must have at least X votes
      #  :at_most     - Item may not have more than X votes
      def rank_tally(*args)
	options = args.extract_options!

	tsub0 = Vote
	tsub0 = tsub0.where("vote = ?", false)
	tsub0 = tsub0.where("voteable_type = ?", self.name)
	tsub0 = tsub0.group("voteable_id")
	tsub0 = tsub0.select("DISTINCT voteable_id, COUNT(vote) as Votes_Against")

	tsub1 = Vote
	tsub1 = tsub1.where("vote = ?", true)
	tsub1 = tsub1.where("voteable_type = ?", self.name)
	tsub1 = tsub1.group("voteable_id")
	tsub1 = tsub1.select("DISTINCT voteable_id, COUNT(vote) as Votes_For")

	t = self.joins("LEFT OUTER JOIN (SELECT DISTINCT #{Vote.table_name}.*,
	  (COALESCE(vfor.Votes_For, 0)-COALESCE(against.Votes_Against, 0)) AS Vote_Total
	    FROM (#{Vote.table_name} LEFT JOIN
	      (#{tsub0.to_sql}) AS against ON #{Vote.table_name}.voteable_id = against.voteable_id)
	    LEFT JOIN
	      (#{tsub1.to_sql}) as vfor ON #{Vote.table_name}.voteable_id = vfor.voteable_id)
	    AS joined_#{Vote.table_name} ON #{self.table_name}.#{self.primary_key} =
	      joined_#{Vote.table_name}.voteable_id")

	t = t.where("joined_#{Vote.table_name}.voteable_type = '#{self.name}'")
	t = t.group("joined_#{Vote.table_name}.voteable_id, joined_#{Vote.table_name}.Vote_Total, #{column_names_for_tally}")
        t = t.limit(options[:limit]) if options[:limit]
        t = t.where("joined_#{Vote.table_name}.created_at >= ?", options[:start_at]) if options[:start_at]
        t = t.where("joined_#{Vote.table_name}.created_at <= ?", options[:end_at]) if options[:end_at]
        t = t.where(options[:conditions]) if options[:conditions]
        t = options[:ascending] ? t.order("joined_#{Vote.table_name}.Vote_Total") : t.order("joined_#{Vote.table_name}.Vote_Total DESC")

        t = t.having(["COUNT(joined_#{Vote.table_name}.voteable_id) > 0",
	        (options[:at_least] ? "joined_votes.Vote_Total >= #{sanitize(options[:at_least])}" : nil),
		(options[:at_most] ? "joined_votes.Vote_Total <= #{sanitize(options[:at_most])}" : nil)
		].compact.join(' AND '))

	t.select("#{self.table_name}.*, joined_#{Vote.table_name}.Vote_Total")
      end

      # Calculate the vote counts for all voteables of my type.
      # This method returns all voteables with at least one vote.
      # The vote count for each voteable is available as #vote_count.
      #
      # Options:
      #  :start_at    - Restrict the votes to those created after a certain time
      #  :end_at      - Restrict the votes to those created before a certain time
      #  :conditions  - A piece of SQL conditions to add to the query
      #  :limit       - The maximum number of voteables to return
      #  :order       - A piece of SQL to order by. Eg 'vote_count DESC' or 'voteable.created_at DESC'
      #  :at_least    - Item must have at least X votes
      #  :at_most     - Item may not have more than X votes
      def tally(*args)
        options = args.extract_options!

        # Use the explicit SQL statement throughout for Postgresql compatibility.
        vote_count = "COUNT(#{Vote.table_name}.voteable_id)"

        t = self.where("#{Vote.table_name}.voteable_type = '#{self.name}'")

        # We join so that you can order by columns on the voteable model.
        t = t.joins("LEFT OUTER JOIN #{Vote.table_name} ON #{self.table_name}.#{self.primary_key} = #{Vote.table_name}.voteable_id")

        t = t.group("#{Vote.table_name}.voteable_id, #{column_names_for_tally}")
        t = t.limit(options[:limit]) if options[:limit]
        t = t.where("#{Vote.table_name}.created_at >= ?", options[:start_at]) if options[:start_at]
        t = t.where("#{Vote.table_name}.created_at <= ?", options[:end_at]) if options[:end_at]
        t = t.where(options[:conditions]) if options[:conditions]
        t = options[:order] ? t.order(options[:order]) : t.order("#{vote_count} DESC")

        # I haven't been able to confirm this bug yet, but Arel (2.0.7) currently blows up
        # with multiple 'having' clauses. So we hack them all into one for now.
        # If you have a more elegant solution, a pull request on Github would be greatly appreciated.
        t = t.having([
            "#{vote_count} > 0",
            (options[:at_least] ? "#{vote_count} >= #{sanitize(options[:at_least])}" : nil),
            (options[:at_most] ? "#{vote_count} <= #{sanitize(options[:at_most])}" : nil)
            ].compact.join(' AND '))
        # t = t.having("#{vote_count} > 0")
        # t = t.having(["#{vote_count} >= ?", options[:at_least]]) if options[:at_least]
        # t = t.having(["#{vote_count} <= ?", options[:at_most]]) if options[:at_most]
        t.select("#{self.table_name}.*, COUNT(#{Vote.table_name}.voteable_id) AS vote_count")
      end

      def column_names_for_tally
        column_names.map { |column| "#{self.table_name}.#{column}" }.join(', ')
      end

    end

    module InstanceMethods

      def votes_for
        Vote.where(:voteable_id => id, :voteable_type => self.class.name, :vote => true).count
      end

      def votes_against
        Vote.where(:voteable_id => id, :voteable_type => self.class.name, :vote => false).count
      end

      def percent_for
        (votes_for.to_f * 100 / (self.votes.size + 0.0001)).round
      end

      def percent_against
        (votes_against.to_f * 100 / (self.votes.size + 0.0001)).round
      end

      # You'll probably want to use this method to display how 'good' a particular voteable
      # is, and/or sort based on it.
      def plusminus
        votes_for - votes_against
      end

      def votes_count
        self.votes.size
      end

      def voters_who_voted
        self.votes.map(&:voter).uniq
      end

      def voted_by?(voter)
        0 < Vote.where(
              :voteable_id => self.id,
              :voteable_type => self.class.name,
              :voter_type => voter.class.name,
              :voter_id => voter.id
            ).count
      end

    end
  end
end
