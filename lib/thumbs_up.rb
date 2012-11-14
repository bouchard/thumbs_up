require 'acts_as_voteable'
require 'acts_as_voter'
require 'has_karma'

module ThumbsUp
  module Base
    # Check if we're connected to a MySQL database.
    def mysql?
      ActiveRecord::Base.connection.adapter_name == 'MySQL'
    end

    def sqlite?
      ActiveRecord::Base.connection.adapter_name == 'SQLite'
    end
  end
end

ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoteable)
ActiveRecord::Base.send(:include, ThumbsUp::ActsAsVoter)
ActiveRecord::Base.send(:include, ThumbsUp::Karma)
