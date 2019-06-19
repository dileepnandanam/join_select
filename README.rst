Join Select

Join select is a gem for writing queries with inner joins with only specifying the association.

To get started:

.. code:: bash

    #Gemfile
    gem 'join_select'
    
    #example usage

    #user.rb
    has_many :groups

    #group.rb
    has_many :posts

    #post.rb
    has_many :comments

    #comments.rb
    has_many :votes

    suppose we need to get count of posts under a users group with comments upvoted by user#id 10
    in general it will be
    current_user.groups
      .joins('inner join posts on posts.group_id = groups.id')
      .joins('inner join comments on comments.post_id = posts.id')
      .joins('inner join votes on votes.comment_id = comments.id')
      .where(votes:{type: 'UpVote', user_id: 10})
      .count('distinct posts.id')
    with join_select, we can do
    User.with(id: current_user.id, groups:{ posts: { comments: {votes: {type: 'UpVote', user_id: 10}}}}).select('distinct posts.id')

    
 Todo
 
Handle polymorphic relations

tests
