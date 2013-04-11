require 'rails/generators/active_record'

class ThumbsUpGenerator < Rails::Generators::Base

  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  class_option :unique_voting, :type => :boolean, :default => true, :desc => 'Do you want only one vote allowed per voter? (default: true)'
  class_option :with_voting_tag, :type => :boolean, :default => false, :desc => 'Do you want add options for a voting? (default: false)'

  # Implement the required interface for Rails::Generators::Migration.
  def self.next_migration_number(dirname) #:nodoc:
    next_migration_number = current_migration_number(dirname) + 1
    if ActiveRecord::Base.timestamped_migrations
      [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
    else
      "%.3d" % next_migration_number
    end
  end

  def create_migration
    migration_template 'migration.rb', File.join('db', 'migrate', 'thumbs_up_migration.rb')
  end

  def move_vote_model
    template 'vote.rb', File.join('app', 'models', 'vote.rb')
  end

end
