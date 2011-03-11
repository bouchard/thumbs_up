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

=begin

SELECT users.*, joined_votes.Vote_Total FROM `users` LEFT OUTER JOIN 
(SELECT DISTINCT votes.*, 
     (IFNULL(vfor.Votes_For, 0)-IFNULL(against.Votes_Against, 0)) AS Vote_Total
FROM (votes
  LEFT JOIN
    (SELECT voteable_id, COUNT(vote) as Votes_Against FROM votes WHERE vote = 0 GROUP BY voteable_id) AS against ON
    votes.voteable_id = against.voteable_id)
  LEFT JOIN 
    (SELECT voteable_id, COUNT(vote) as Votes_For FROM votes WHERE vote = 1 GROUP BY voteable_id) as vfor
    ON votes.voteable_id = vfor.voteable_id) AS joined_votes ON users.id = joined_votes.voteable_id

  WHERE (joined_votes.voteable_type = 'User') AND (joined_votes.created_at >= '2011-03-09 23:28:18') 
      AND (joined_votes.created_at <= '2011-03-10 23:28:18') GROUP BY joined_votes.voteable_id, 
      users.id, users.username, users.email, users.encrypted_password, users.salt, users.admin, 
      users.created_at, users.updated_at, users.image, users.blurb HAVING COUNT(joined_votes.voteable_id) 
      > 0 ORDER BY joined_votes.Vote_Total DESC LIMIT 10
      
      Compare this to original:
      
      SELECT  users.*, COUNT(votes.voteable_id) AS vote_count FROM `users` LEFT OUTER JOIN votes 
      ON users.id = votes.voteable_id WHERE (votes.voteable_type = 'User') AND (votes.created_at 
      >= '2011-03-09 23:28:18') AND (votes.created_at <= '2011-03-10 23:28:18') GROUP BY 
      votes.voteable_id, users.id, users.username, users.email, users.encrypted_password, 
      users.salt, users.admin, users.created_at, users.updated_at, users.image, users.blurb HAVING 
      COUNT(votes.voteable_id) > 0 ORDER BY vote_count DESC LIMIT 10
=end      

      # The point of this function is to return rankings based on the difference between up and down votes
      # assuming equal weighting (i.e. a user with 1 up vote and 1 down vote has a Vote_Total of 0. 
      # First the votes table is joined twiced so that the Vote_Total can be calculated for every ID
      # Then this table is joined against the specific table passed to this function to allow for 
      # ranking of the items within that table based on the difference between up and down votes.
      def rank_tally(*args)
	debugger
	options = args.extract_options!

	t = self
	t.joins("LEFT OUTER JOIN (SELECT DISTINCT #{Vote.table_name}.*, 
	  (IFNULL(vfor.Votes_For, 0)-IFNULL(against.Votes_Against, 0)) AS Vote_Total
	    FROM (#{Vote.table_name} LEFT JOIN
	      (SELECT voteable_id, COUNT(vote) as Votes_Against FROM #{Vote.table_name} WHERE vote = 0 
	       GROUP BY voteable_id) AS against ON #{Vote.table_name}.voteable_id = against.voteable_id)
	    LEFT JOIN 
	      (SELECT voteable_id, COUNT(vote) as Votes_For FROM #{Vote.table_name} WHERE vote = 1 
	      GROUP BY voteable_id) as vfor ON #{Vote.table_name}.voteable_id = vfor.voteable_id) 
	    AS joined_#{Vote.table_name} ON #{self.table_name}.#{self.primary_key} = 
	      joined_#{Vote.table_name}.voteable_id")
	
	t = t.group("joined_#{Vote.table_name}.voteable_id, #{column_names_for_tally}")
        t = t.limit(options[:limit]) if options[:limit]
        t = t.where("#{Vote.table_name}.created_at >= ?", options[:start_at]) if options[:start_at]
        t = t.where("#{Vote.table_name}.created_at <= ?", options[:end_at]) if options[:end_at]
        t = t.where(options[:conditions]) if options[:conditions]
        t = options[:ascending] ? t.order("joined_#{Vote.table_name}.Vote_Total")
	                                  : t.order("joined_#{Vote.table_name}.Vote_Total DESC")
        
        t = t.having("joined_#{Vote.table_name}.voteable_id > 0")
	
	t.select("#{self.table_name}.*, joined_#{Vote.table_name}.Vote_Total")
      end
	
      
      def tally(*args)
        options = args.extract_options!
        
        # Use the explicit SQL statement throughout for Postgresql compatibility.
        vote_count = "COUNT(#{Vote.table_name}.voteable_id)"
        
        t = self.where("#{Vote.table_name}.voteable_type = '#{self.name}'")

        # We join so that you can order by columns on the voteable model. 
	# LEFT OUTER JOIN votes ON users.id = votes.voteable_id
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
