module ThumbsUp #:nodoc:
  module ActsAsVoter #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_voter

        # If a voting entity is deleted, keep the votes.
        # If you want to nullify (and keep the votes), you'll need to remove
        # the unique constraint on the [ voter, voteable ] index in the database.
        # has_many :votes, :as => :voter, :dependent => :nullify
        # Destroy voter's votes when the voter is deleted.
        has_many ThumbsUp.configuration[:voter_relationship_name],
                 :as => :voter,
                 :dependent => :destroy,
                 :class_name => 'Vote'

        include ThumbsUp::ActsAsVoter::InstanceMethods
        extend  ThumbsUp::ActsAsVoter::SingletonMethods
      end
    end

    # This module contains class methods
    module SingletonMethods
    end

    # This module contains instance methods
    module InstanceMethods

      # wraps the dynamic, configured, relationship name
      def _votes_on(tag = nil)
        args = tag ? {voteable_tag: tag} : nil
        self.send(ThumbsUp.configuration[:voteable_relationship_name]).where(args)
      end

      # Usage user.vote_count(:up)              # All +1 votes
      #       user.vote_count(:down)            # All -1 votes
      #       user.vote_count()                 # All votes
      #       user.vote_count('test_tag')       # All votes for 'test_tag'
      #       user.vote_count(:up, 'test_tag')  # All +1 votes for 'test_tag'
      # vote_count('test_tag')
      def vote_count(for_or_against = :all, tag = nil)
        v = Vote.where(:voter_id => id).where(:voter_type => self.class.base_class.name)
        #v = case for_or_against
        #  when :all   then v
        #  when :up    then v.where(:vote => true)
        #  when :down  then v.where(:vote => false)
        #
        #end
        #v.count
        args = case for_or_against
                 when :all, nil  then tag ? {voteable_tag: tag} : nil
                 when :up  then tag ? {:vote => true, voteable_tag: tag} : {:vote => true}
                 when :down  then tag ? {:vote => false, voteable_tag: tag} : {:vote => false}
                 else {voteable_tag: for_or_against}
               end
        v.where(args).count
      end

      def voted_for?(voteable, tag = nil)
        voted_which_way?(voteable, :up, tag)
      end

      def voted_against?(voteable, tag = nil)
        voted_which_way?(voteable, :down, tag)
      end

      def voted_on?(voteable, tag = nil)
        args = {
          :voter_id => self.id,
          :voter_type => self.class.base_class.name,
          :voteable_id => voteable.id,
          :voteable_type => voteable.class.base_class.name
        }
        args.merge!({voteable_tag: tag}) if tag
        0 < Vote.where(args).count
      end

      def vote_for(voteable, tag = nil)
        args = { :direction => :up, :exclusive => false }
        args.merge!({tag: tag}) if tag
        self.vote(voteable, args)
      end

      def vote_against(voteable, tag = nil)
        args = { :direction => :down, :exclusive => false }
        args.merge!({tag: tag}) if tag
        self.vote(voteable, args)
      end

      def vote_exclusively_for(voteable, tag = nil)
        args = { :direction => :up, :exclusive => true }
        args.merge!({tag: tag}) if tag
        self.vote(voteable, args)
      end

      def vote_exclusively_against(voteable, tag = nil)
        args = { :direction => :down, :exclusive => true }
        args.merge!({tag: tag}) if tag
        self.vote(voteable, args)
      end

      def vote(voteable, options = {})
        raise ArgumentError, "you must specify :up or :down in order to vote" unless options[:direction] && [:up, :down].include?(options[:direction].to_sym)
        if options[:exclusive]
          self.unvote_for(voteable, options[:tag])
        end
        direction = (options[:direction].to_sym == :up)
        args = {vote: direction, voteable: voteable, voter: self}
        args.merge!({voteable_tag: options[:tag]}) unless options[:tag].blank?
        v = Vote.create!(args)
      end

      def unvote_for(voteable, tag = nil)
        args = {
          voter_id: self.id,
          voter_type: self.class.base_class.name,
          voteable_id: voteable.id,
          voteable_type: voteable.class.base_class.name
        }
        args.merge!({voteable_tag: tag}) if tag
        Vote.where(args).map(&:destroy)
      end

      alias_method :clear_votes, :unvote_for

      def voted_which_way?(voteable, direction, tag = nil)
        raise ArgumentError, "expected :up or :down" unless [:up, :down].include?(direction)
        args = {
          voter_id: self.id,
          voter_type: self.class.base_class.name,
          vote: direction == :up,
          voteable_id: voteable.id,
          voteable_type: voteable.class.base_class.name
        }
        args.merge!({voteable_tag: tag}) if tag
        0 < Vote.where(args).count
      end

    end
  end
end
