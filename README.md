# IdempotentTransaction

This gem execute passed block by once using database unique key.  

```ruby
class IdempotentExecutor < ApplicationRecord
  #  user_id             :bigint(8)      not null
  #  transaction_type    :integer(11)    not null
  #  signature           :string(255)    not null
  #  expired_time        :datetime       not null
  #
  # Indexes
  #
  #  unique_index  (user_id, type, signature) UNIQUE

  include IdempotentTransaction

  enum transaction_type: [:post_create]

  register_idempotent_column :user_id, :transaction_type, :signature
end

exec = IdempotentExecutor.new(user_id: user.id, transaction_type: :post_create, signature: 'abcdefg')
exec.idempotent_transaction do
  user.user_posts.create(params[:new_post])
end

# we don't execute block and raise IdempotentTransaction::IdempotentError
exec.idempotent_transaction do
  user.user_posts.create(params[:new_post])
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'idempotent_transaction'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install idempotent_transaction

## Usage

### Basic
```ruby
exec_1 = IdempotentExecutor.new(user_id: user.id, transaction_type: :post_create, signature: 'abcdefg')

# first time, we got no error and executed block 
exec_1.finished?
# => false

exec.idempotent_transaction do
  user.user_posts.create(params[:new_post])
end

user.user_posts.count
# => 1

exec_1.finished?
# => true

exec_1.executed?
# => true

# second time, we didn't execute block
exec_2 = IdempotentExecutor.new(user_id: user.id, transaction_type: :post_create, signature: 'abcdefg')
exec_2.finished?
# => true
exec_2.executed?
# => false

exec_2.idempotent_transaction do
  user.user_posts.create(params[:new_post])
end

user.user_posts.count
# => 1 we don't execute block

exec_2.finished?
# => true
exec_2.executed?
# => false
```

### Force execute
When you pass force option, we always execute block and update state.

```ruby
exec.finished?
# => true

exec.idempotent_transaction(force: true) do
  user.user_posts.create(params[:new_post])
end

exec.executed?
# => true
```

### Stop execute block
If you raise error in block, we stop execute block and rollback state.

```ruby
exec.idempotent_transaction do
  raise 'error'
end

# when retry, execute block because above block didn't completed
exec.idempotent_transaction do
  user.user_posts.create(params[:new_post])
end

```

## Background
```ruby
exec = IdempotentExecutor.new(user_id: user.id, type: :post_create, signature: 'abcdefg')
exec.idempotent_transaction do
  user.user_posts.create(params[:new_post])
end
```

We use transaction so we rewrite this code like this. 

```ruby
exec = IdempotentExecutor.new(user_id: user.id, type: :post_create, signature: 'abcdefg')

ActiveRecord::Base.transaction do
  user.user_posts.create(params[:new_post])

  begin
    exec.save!
    exec.executed = true
    exec.finished = true
  rescue => ActiveRecord::RecordNotUnique
    exec.finished = true
    exec.executed = false
  end 
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/idempotent_transaction. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the IdempotentTransaction project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/idempotent_transaction/blob/master/CODE_OF_CONDUCT.md).
