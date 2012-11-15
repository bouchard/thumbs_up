require 'acts_as_voteable'
require 'acts_as_voter'
require 'has_karma'

module ThumbsUp
  module Base
    def quoted_true
      ActiveRecord::Base.connection.quoted_true
    end

    def quoted_false
      ActiveRecord::Base.connection.quoted_false
    end
  end
end

ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoteable)
ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoter)
ActiveRecord::Base.send(:include, ThumbsUp::Karma)
