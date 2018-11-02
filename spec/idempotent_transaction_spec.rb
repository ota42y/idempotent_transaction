require 'models/application_record'
require 'models/user_post'
require 'models/idempotent_executor'

RSpec.describe IdempotentTransaction do
  it 'correct' do
    user_id = 1

    exec_1 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false

    exec_1.idempotent_transaction do
      UserPost.create!(user_id: user_id, title: 'test post 1')
    end

    expect(UserPost.count).to eq 1
    expect(exec_1.finished?).to eq true
    expect(exec_1.executed?).to eq true

    exec_2 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    expect(exec_2.finished?).to eq true
    expect(exec_2.executed?).to eq false

    exec_2.idempotent_transaction do
      UserPost.create!(user_id: user_id, title: 'test post 1')
    end

    expect(UserPost.count).to eq 1
    expect(exec_2.finished?).to eq true
    expect(exec_2.executed?).to eq false
  end

  it 'block raise error' do
    user_id = 1

    exec_1 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false

    expect do
      exec_1.idempotent_transaction do
        UserPost.create!(user_id: user_id, title: 'test post 1')
        raise 'block raise error'
      end
    end.to raise_error(StandardError).with_message('block raise error')

    expect(IdempotentExecutor.count).to eq 0
    expect(UserPost.count).to eq 0
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false
  end

  it 'block raise RecordNotUnique' do
    user_id = 1

    exec_1 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false

    expect do
      exec_1.idempotent_transaction do
        UserPost.create!(user_id: user_id, title: 'test post 1')
        raise ActiveRecord::RecordNotUnique, 'not unique'
      end
    end.to raise_error(ActiveRecord::RecordNotUnique).with_message('not unique')

    expect(IdempotentExecutor.count).to eq 0
    expect(UserPost.count).to eq 0
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false
  end

  it 'block raise rollback' do
    user_id = 1

    exec_1 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false

    exec_1.idempotent_transaction do
      UserPost.create!(user_id: user_id, title: 'test post 1')
      raise ActiveRecord::Rollback, 'rallback'
    end

    expect(IdempotentExecutor.count).to eq 0
    expect(UserPost.count).to eq 0
    expect(exec_1.finished?).to eq false
    expect(exec_1.executed?).to eq false
  end

  it 'force execute' do
    user_id = 1

    exec_1 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    exec_1.idempotent_transaction do
      UserPost.create!(user_id: user_id, title: 'test post 1')
    end

    exec_2 = IdempotentExecutor.new(user_id: user_id, transaction_type: :post_create, signature: 'abcdefg')
    expect(exec_2.finished?).to eq true
    expect(exec_2.executed?).to eq false

    exec_2.idempotent_transaction(force: true) do
      UserPost.create!(user_id: user_id, title: 'test post 1')
    end

    expect(UserPost.count).to eq 2
    expect(IdempotentExecutor.count).to eq 1
    expect(exec_2.finished?).to eq true
    expect(exec_2.executed?).to eq true
  end

  it 'returns block result as is' do
    exec_1 = IdempotentExecutor.new(user_id: 1, transaction_type: :post_create, signature: 'abcdefg')

    block = proc { 'Block result' }

    expect(exec_1.idempotent_transaction(&block)).to eq('Block result')
  end
end
