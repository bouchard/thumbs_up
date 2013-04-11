class ThumbsUpMigration < ActiveRecord::Migration
  def self.up
    create_table :votes, :force => true do |t|

      t.boolean    :vote,     :default => false,    :null => false
      t.references :voteable, :polymorphic => true, :null => false
      t.references :voter,    :polymorphic => true
<% if options[:with_voting_tag] == true %>
      t.string :voteable_tag,    :polymorphic => true
<% end %>
        t.timestamps

    end

    add_index :votes, [:voter_id, :voter_type]
<% if options[:with_voting_tag] == true %>
    add_index :votes, [:voteable_id, :voteable_type, :voteable_tag]
<% else %>
    add_index :votes, [:voteable_id, :voteable_type]
<% end %>
  <% if options[:unique_voting] == true %>
    # Comment out the line below to allow multiple votes per voter on a single entity.
  <% if options[:with_voting_tag] == true %>
    add_index :votes, [:voter_id, :voter_type, :voteable_id, :voteable_type, :voteable_tag], :unique => true, :name => 'fk_one_vote_per_user_per_entity'
  <% else %>
    add_index :votes, [:voter_id, :voter_type, :voteable_id, :voteable_type], :unique => true, :name => 'fk_one_vote_per_user_per_entity'
  <% end %>
<% end %>
  end

    def self.down
      drop_table :votes
    end

end
