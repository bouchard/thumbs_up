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
      
      # Calculate the plusminus for a group of voteables in one database query.
      # This returns an Arel relation, so you can add conditions as you like chained on to
      # this method call.
      # i.e. Posts.tally.where('votes.created_at > ?', 2.days.ago)
      def plusminus_tally
        t = self.joins("LEFT OUTER JOIN #{Vote.table_name} ON #{self.table_name}.id = #{Vote.table_name}.voteable_id")
        t = t.order("plusminus DESC")
        t = t.group("#{self.column_names_for_tally}")
        t = t.select("#{self.table_name}.*")
        t = t.select("SUM(CASE CAST(#{Vote.table_name}.vote AS #{ActiveRecord::Base.connection.type_to_sql(:integer)}) WHEN 1 THEN 1 WHEN 0 THEN -1 ELSE 0 END) AS plusminus")
        t = t.select("COUNT(#{Vote.table_name}.id) AS vote_count")
      end

      # #rank_tally is depreciated.
      alias_method :rank_tally, :plusminus_tally

      # Calculate the vote counts for all voteables of my type.
      # This method returns all voteables (even without any votes) by default.
      # The vote count for each voteable is available as #vote_count.
      # This returns an Arel relation, so you can add conditions as you like chained on to
      # this method call.
      # i.e. Posts.tally.where('votes.created_at > ?', 2.days.ago)
      def tally(*args)
        t = self.joins("LEFT OUTER JOIN #{Vote.table_name} ON #{self.table_name}.id = #{Vote.table_name}.voteable_id")
        t = t.order("vote_count DESC")
        t = t.group("#{self.table_name}.id")
        t = t.select("#{self.table_name}.*")
        t = t.select("#{Vote.table_name}.*")
        t = t.select("COUNT(#{Vote.table_name}.id) AS vote_count")
      end

      def column_names_for_tally
        column_names.map { |column| "#{self.table_name}.#{column}" }.join(', ')
      end

    end

    module InstanceMethods

      def votes_for
        self.votes.where(:vote => true).count
      end

      def votes_against
        self.votes.where(:vote => false).count
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
              :voter_id => voter.id
            ).count
      end

    end
  end
end
