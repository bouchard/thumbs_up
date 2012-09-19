require File.join(File.expand_path(File.dirname(__FILE__)), 'test_helper')

class TestThumbsUp < Test::Unit::TestCase
  def setup
    Vote.delete_all
    User.delete_all
    Item.delete_all
  end

  def test_acts_as_voter_instance_methods
    user_for = User.create(:name => 'david')
    user_against = User.create(:name => 'brady')
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')

    assert_not_nil user_for.vote_for(item)
    assert_raises(ActiveRecord::RecordInvalid) do
      user_for.vote_for(item)
    end
    assert_equal true, user_for.voted_for?(item)
    assert_equal false, user_for.voted_against?(item)
    assert_equal true, user_for.voted_on?(item)
    assert_equal 1, user_for.vote_count
    assert_equal 1, user_for.vote_count(:up)
    assert_equal 0, user_for.vote_count(:down)
    assert_equal true, user_for.voted_which_way?(item, :up)
    assert_equal false, user_for.voted_which_way?(item, :down)
    assert_raises(ArgumentError) do
      user_for.voted_which_way?(item, :foo)
    end

    assert_not_nil user_against.vote_against(item)
    assert_raises(ActiveRecord::RecordInvalid) do
      user_against.vote_against(item)
    end
    assert_equal false, user_against.voted_for?(item)
    assert_equal true, user_against.voted_against?(item)
    assert_equal true, user_against.voted_on?(item)
    assert_equal 1, user_against.vote_count
    assert_equal 0, user_against.vote_count(:up)
    assert_equal 1, user_against.vote_count(:down)
    assert_equal false, user_against.voted_which_way?(item, :up)
    assert_equal true, user_against.voted_which_way?(item, :down)
    assert_raises(ArgumentError) do
      user_against.voted_which_way?(item, :foo)
    end

    assert_not_nil user_against.vote_exclusively_for(item)
    assert_equal true, user_against.voted_for?(item)

    assert_not_nil user_for.vote_exclusively_against(item)
    assert_equal true, user_for.voted_against?(item)

    user_for.unvote_for(item)
    assert_equal 0, user_for.vote_count

    user_against.unvote_for(item)
    assert_equal 0, user_against.vote_count

    assert_raises(ArgumentError) do
      user_for.vote(item, {:direction => :foo})
    end
  end

  def test_acts_as_voteable_instance_methods
    user_for = User.create(:name => 'david')
    another_user_for = User.create(:name => 'name')
    user_against = User.create(:name => 'brady')
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')

    user_for.vote_for(item)
    another_user_for.vote_for(item)

    assert_equal 2, item.votes_for
    assert_equal 0, item.votes_against
    assert_equal 2, item.plusminus

    user_against.vote_against(item)

    assert_equal 1, item.votes_against
    assert_equal 1, item.plusminus

    assert_equal 3, item.votes_count

    assert_equal 67, item.percent_for
    assert_equal 33, item.percent_against

    voters_who_voted = item.voters_who_voted
    assert_equal 3, voters_who_voted.size
    assert voters_who_voted.include?(user_for)
    assert voters_who_voted.include?(another_user_for)
    assert voters_who_voted.include?(user_against)

    non_voting_user = User.create(:name => 'random')

    assert_equal true, item.voted_by?(user_for)
    assert_equal true, item.voted_by?(another_user_for)
    assert_equal true, item.voted_by?(user_against)
    assert_equal false, item.voted_by?(non_voting_user)
  end

  def test_tally_empty
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    assert_equal 0, Item.tally.having('vote_count > 0').length
  end

  def test_tally_has_id
    item1 = Item.create(:name => 'XBOX', :description => 'XBOX console')
    item2 = Item.create(:name => 'XBOX2', :description => 'XBOX2 console')
    user = User.create(:name => 'david')

    user.vote_for(item2)

    assert_not_nil Item.tally.all.first.id
  end

  def test_tally_starts_at
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    user = User.create(:name => 'david')

    vote = user.vote_for(item)
    vote.created_at = 3.days.ago
    vote.save

    assert_equal 0, Item.tally.where('created_at > ?', 2.days.ago).length
    assert_equal 1, Item.tally.where('created_at > ?', 4.days.ago).length
  end

  def test_tally_end_at
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    user = User.create(:name => 'david')

    vote = user.vote_for(item)
    vote.created_at = 3.days.from_now
    vote.save

    assert_equal 0, Item.tally.where('created_at < ?', 2.days.from_now).length
    assert_equal 1, Item.tally.where('created_at < ?', 4.days.from_now).length
  end

  def test_tally_between_start_at_end_at
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    another_item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    user = User.create(:name => 'david')

    vote = user.vote_for(item)
    vote.created_at = 2.days.ago
    vote.save

    vote = user.vote_for(another_item)
    vote.created_at = 3.days.from_now
    vote.save

    assert_equal 1, Item.tally.where('created_at > ?', 3.days.ago).where('created_at < ?', 2.days.from_now).length
    assert_equal 2, Item.tally.where('created_at > ?', 3.days.ago).where('created_at < ?', 4.days.from_now).length
  end

  def test_tally_count
    Item.tally.count
  end

  def test_tally_any
    Item.tally.any?
  end

  def test_tally_empty
    Item.tally.empty?
  end

  def test_plusminus_tally_not_empty_without_conditions
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    assert_equal 1, Item.plusminus_tally.length
  end

  def test_plusminus_tally_empty
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    assert_equal 0, Item.plusminus_tally.having('vote_count > 0').length
  end

  def test_plusminus_tally_starts_at
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    user = User.create(:name => 'david')

    vote = user.vote_for(item)
    vote.created_at = 3.days.ago
    vote.save

    assert_equal 0, Item.plusminus_tally.where('created_at > ?', 2.days.ago).length
    assert_equal 1, Item.plusminus_tally.where('created_at > ?', 4.days.ago).length
  end

  def test_plusminus_tally_end_at
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    user = User.create(:name => 'david')

    vote = user.vote_for(item)
    vote.created_at = 3.days.from_now
    vote.save

    assert_equal 0, Item.plusminus_tally.where('created_at < ?', 2.days.from_now).length
    assert_equal 1, Item.plusminus_tally.where('created_at < ?', 4.days.from_now).length
  end

  def test_plusminus_tally_between_start_at_end_at
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    another_item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    user = User.create(:name => 'david')

    vote = user.vote_for(item)
    vote.created_at = 2.days.ago
    vote.save

    vote = user.vote_for(another_item)
    vote.created_at = 3.days.from_now
    vote.save

    assert_equal 1, Item.plusminus_tally.where('created_at > ?', 3.days.ago).where('created_at < ?', 2.days.from_now).length
    assert_equal 2, Item.plusminus_tally.where('created_at > ?', 3.days.ago).where('created_at < ?', 4.days.from_now).length
  end

  def test_plusminus_tally_inclusion
    user = User.create(:name => 'david')
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    item_not_included = Item.create(:name => 'Playstation', :description => 'Playstation console')

    assert_not_nil user.vote_for(item)

    assert (Item.plusminus_tally.having('vote_count > 0').include? item)
    assert (not Item.plusminus_tally.having('vote_count > 0').include? item_not_included)
  end

  def test_plusminus_tally_voting_for
    user1 = User.create(:name => 'david')
    item = Item.create(:name => 'Playstation', :description => 'Playstation console')

    assert_not_nil user1.vote_for(item)

    assert_equal 1, Item.plusminus_tally[0].vote_count
    assert_equal 1, Item.plusminus_tally[0].plusminus
  end

  def test_plusminus_tally_voting_against
    user1 = User.create(:name => 'david')
    user2 = User.create(:name => 'john')
    item = Item.create(:name => 'Playstation', :description => 'Playstation console')

    assert_not_nil user1.vote_against(item)
    assert_not_nil user2.vote_against(item)

    assert_equal 2, Item.plusminus_tally[0].vote_count
    assert_equal -2, Item.plusminus_tally[0].plusminus
  end

  def test_plusminus_tally_default_ordering
    user1 = User.create(:name => 'david')
    user2 = User.create(:name => 'john')
    item_twice_for = Item.create(:name => 'XBOX2', :description => 'XBOX2 console')
    item_for = Item.create(:name => 'XBOX', :description => 'XBOX console')
    item_against = Item.create(:name => 'Playstation', :description => 'Playstation console')

    assert_not_nil user1.vote_for(item_for)
    assert_not_nil user1.vote_for(item_twice_for)
    assert_not_nil user2.vote_for(item_twice_for)
    assert_not_nil user1.vote_against(item_against)

    assert_equal item_twice_for, Item.plusminus_tally[0]
    assert_equal item_for, Item.plusminus_tally[1]
    assert_equal item_against, Item.plusminus_tally[2]
  end
  
  def test_plusminus_tally_limit
    users = (0..9).map{ |u| User.create(:name => "User #{u}") }
    items = (0..9).map{ |u| Item.create(:name => "Item #{u}", :description => "Item #{u}") }
    users.each{ |u| items.each { |i| u.vote_for(i) } }
    assert_equal 10, Item.plusminus_tally.length
    assert_equal 2, Item.plusminus_tally.limit(2).length
  end

  def test_plusminus_tally_ascending_ordering
    user = User.create(:name => 'david')
    item_for = Item.create(:name => 'XBOX', :description => 'XBOX console')
    item_against = Item.create(:name => 'Playstation', :description => 'Playstation console')

    assert_not_nil user.vote_for(item_for)
    assert_not_nil user.vote_against(item_against)

    assert_equal item_for, Item.plusminus_tally.reorder('plusminus_tally ASC')[1]
    assert_equal item_against, Item.plusminus_tally.reorder('plusminus_tally ASC')[0]
  end

  def test_plusminus_tally_count
    Item.plusminus_tally.count
  end

  def test_plusminus_tally_any
    Item.plusminus_tally.any?
  end

  def test_plusminus_tally_empty
    Item.plusminus_tally.empty?
  end

  def test_karma
    users = (0..1).map{ |u| User.create(:name => "User #{u}") }
    items = (0..1).map{ |u| users[0].items.create(:name => "Item #{u}", :description => "Item #{u}") }
    users.each{ |u| items.each { |i| u.vote_for(i) } }
    
    assert_equal 4, users[0].karma
    assert_equal 0, users[1].karma
  end

  def test_plusminus_tally_scopes_by_voteable_type
    user = User.create(:name => 'david')
    item = Item.create(:name => 'XBOX', :description => 'XBOX console')
    another_item = OtherItem.create(:name => 'Playstation', :description => 'Playstation console')

    user.vote_for(item)
    user.vote_for(another_item)

    assert_equal 1, Item.plusminus_tally.sum(&:plusminus_tally).to_i
    assert_equal 1, OtherItem.plusminus_tally.sum(&:plusminus_tally).to_i
  end

end
