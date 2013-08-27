require 'acts_as_voteable'
require 'acts_as_voter'
require 'has_karma'
require 'thumbs_up/configuration'
require 'thumbs_up/base'
require 'thumbs_up/version'

module ThumbsUp

  class << self

    # An ThumbsUp::Configuration object. Must act like a hash and return sensible
    # values for all ThumbsUp::Configuration::OPTIONS. See ThumbsUp::Configuration.
    attr_writer :configuration

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   ThumbsUp.configure do |config|
    #     config.voteable_relationship_name = :votes_on
    #     config.voter_relationship_name    = :votes_by
    #   end
    def configure
      yield(configuration)
    end

    # The configuration object.
    # @see ThumbsUp::Configuration
    def configuration
      @configuration ||= Configuration.new
    end
  end

end

ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoteable)
ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoter)
ActiveRecord::Base.send(:include, ThumbsUp::Karma)
