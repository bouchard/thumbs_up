require 'acts_as_voteable'
require 'acts_as_voter'
require 'has_karma'

module ThumbsUp
  VOTES = {
    :up => 1,
    :down => -1,
    :neutral => 0
  }
end

ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoteable)
ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoter)
ActiveRecord::Base.send(:include, ThumbsUp::Karma)
