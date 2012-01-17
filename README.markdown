ThumbsUp
=======

A ridiculously straightforward and simple package 'o' code to enable voting in your application, a la stackoverflow.com, etc.
Allows an arbitrary number of entities (users, etc.) to vote on models.

### Mixins
This plugin introduces three mixins to your recipe book:

1. **acts\_as\_voteable** : Intended for content objects like Posts, Comments, etc.
2. **acts\_as\_voter** : Intended for voting entities, like Users.
3. **has\_karma** : Adds some helpers to acts\_as\_voter models for calculating karma.

### Inspiration

This plugin started as an adaptation / update of vote\_fu for use with Rails 3. It adds some speed, removes some cruft, and is adapted for use with ActiveRecord / Arel in Rails 3. It maintains the awesomeness of the original vote\_fu.

Installation
============

### Require the gem:

    gem 'thumbs_up'

### Create and run the ThumbsUp migration:

    rails generate thumbs_up
    rake db:migrate

Usage
=====

## Getting Started

### Turn your AR models into something that can be voted upon.

    class SomeModel < ActiveRecord::Base
      acts_as_voteable
    end

    class Question < ActiveRecord::Base
      acts_as_voteable
    end

### Turn your Users (or any other model) into voters.

    class User < ActiveRecord::Base
      acts_as_voter
      # The following line is optional, and tracks karma (up votes) for questions this user has submitted.
      # Each question has a submitter_id column that tracks the user who submitted it.
      # The option :weight value will be multiplied to any karma from that voteable model (defaults to 1).
      # You can track any voteable model.
      has_karma(:questions, :as => :submitter, :weight => 0.5)
    end

    class Robot < ActiveRecord::Base
      acts_as_voter
    end

### To cast a vote for a Model you can do the following:

#### Shorthand syntax
    voter.vote_for(voteable)     	# Adds a +1 vote
    voter.vote_against(voteable) 	# Adds a -1 vote
    voter.vote(voteable, vote) 	# Adds either a +1 or -1 vote: vote => true (+1), vote => false (-1)

    voter.vote_exclusively_for(voteable)	# Removes any previous votes by that particular voter, and votes for.
    voter.vote_exclusively_against(voteable)	# Removes any previous votes by that particular voter, and votes against.

    vote.unvote_for(voteable)  # Clears all votes for that user

### Querying votes

Did the first user vote for the Car with id = 2 already?

    u = User.first
    u.vote_for(Car.find(2))
    u.voted_on?(Car.find(2)) #=> true
	
Did the first user vote for or against the Car with id = 2?

    u = User.first
    u.vote_for(Car.find(2))
    u.voted_for?(Car.find(2)) #=> true
    u.voted_against?(Car.find(2)) #=> false

#### Tallying Votes

You can easily retrieve voteable object collections based on the properties of their votes:

    @items = Item.tally(
      {  :at_least => 1,
          :at_most => 10000,
          :start_at => 2.weeks.ago,
          :end_at => 1.day.ago,
          :limit => 10,
          :order => "items.name DESC"
      })

This will select the Items with between 1 and 10,000 votes, the votes having been cast within the last two weeks (not including today), then display the 10 last items in an alphabetical list. *This tallies all votes, regardless of whether they are +1 (up) or -1 (down).*


##### Tally Options:
    :start_at    - Restrict the votes to those created after a certain time
    :end_at      - Restrict the votes to those created before a certain time
    :conditions  - A piece of SQL conditions to add to the query
    :limit       - The maximum number of voteables to return
    :order       - A piece of SQL to order by. Eg 'votes.count desc' or 'voteable.created_at desc'
    :at_least    - Item must have at least X votes
    :at_most     - Item may not have more than X votes

#### Tallying Rank ("Plusminus")

**You most likely want to use this over the normal tally**

This is similar to tallying votes, but this will return voteable object collections based on the sum of the differences between up and down votes (ups are +1, downs are -1). For Instance, a voteable with 3 upvotes and 2 
downvotes will have a plusminus of 1.

    @items = Item.plusminus_tally(
      {  :at_least => 1,
          :at_most => 10000,
          :start_at => 2.weeks.ago,
          :end_at => 1.day.ago,
          :limit => 10,
          :order => "items.name DESC"
      })

##### Plusminus Tally Options:
    :start_at    - Restrict the votes to those created after a certain time
    :end_at      - Restrict the votes to those created before a certain time
    :conditions  - A piece of SQL conditions to add to the query
    :limit       - The maximum number of voteables to return
    :ascending   - Boolean Default false.  If specified true, results will be returned in ascending order (from bottom up)
    :at_least    - Item must have at least X votes
    :at_most     - Item may not have more than X votes

#### Lower level queries

    positiveVoteCount = voteable.votes_for
    negativeVoteCount = voteable.votes_against
    plusminus         = voteable.plusminus  # Votes for, minus votes against.

	voter.voted_for?(voteable) # True if the voter voted for this object.
	voter.vote_count(:up | :down | :all) # returns the count of +1, -1, or all votes

	voteable.voted_by?(voter) # True if the voter voted for this object.
	@voters = voteable.voters_who_voted


### One vote per user!

ThumbsUp by default only allows one vote per user. This can be changed by removing:

#### In vote.rb:

    validates_uniqueness_of :voteable_id, :scope => [:voteable_type, :voter_type, :voter_id]

#### In the migration, the unique index:

    add_index :votes, ["voter_id", "voter_type", "voteable_id", "voteable_type"], :unique => true, :name => "uniq_one_vote_only"

You can also use `--unique-voting false` when running the generator command:

    rails generate thumbs_up --unique-voting false

Credits
=======

Basic scaffold is from Peter Jackson's work on VoteFu / ActsAsVoteable. All code updated for Rails 3, cleaned up for speed and clarity, karma calculation fixed, and (hopefully) zero introduced bugs.
