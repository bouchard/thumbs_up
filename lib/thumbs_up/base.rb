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
