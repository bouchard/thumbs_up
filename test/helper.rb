require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :votes, :force => true do |t|
    t.integer    :vote,     :default => 0
    t.references :voteable, :polymorphic => true, :null => false
    t.references :voter,    :polymorphic => true
    t.timestamps
  end

  add_index :votes, [:voter_id, :voter_type]
  add_index :votes, [:voteable_id, :voteable_type]

  # Comment out the line below to allow multiple votes per voter on a single entity.
  add_index :votes, [:voter_id, :voter_type, :voteable_id, :voteable_type], :unique => true, :name => 'fk_one_vote_per_user_per_entity'

  create_table :users, :force => true do |t|
    t.string :name
    t.timestamps
  end

  create_table :items, :force => true do |t|
    t.string :name
    t.string :description
  end
end

require 'thumbs_up'

class Vote < ActiveRecord::Base

  scope :for_voter, lambda { |*args| where(["voter_id = ? AND voter_type = ?", args.first.id, args.first.class.name]) }
  scope :for_voteable, lambda { |*args| where(["voteable_id = ? AND voteable_type = ?", args.first.id, args.first.class.name]) }
  scope :recent, lambda { |*args| where(["created_at > ?", (args.first || 2.weeks.ago)]) }
  scope :descending, order("created_at DESC")

  belongs_to :voteable, :polymorphic => true
  belongs_to :voter, :polymorphic => true

  attr_accessible :vote, :voter, :voteable

  # Comment out the line below to allow multiple votes per user.
  validates_uniqueness_of :voteable_id, :scope => [:voteable_type, :voter_type, :voter_id]
end

class User < ActiveRecord::Base
  acts_as_voter
end

class Item < ActiveRecord::Base
  acts_as_voteable
end

class Test::Unit::TestCase
end
