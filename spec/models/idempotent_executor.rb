ActiveRecord::Schema.define do
  create_table :idempotent_executors do |t|
    t.integer :user_id, null: false
    t.integer :transaction_type, null: false
    t.string :signature, null: false

    t.index %i[user_id transaction_type signature], unique: true, name: :unique_index

    t.timestamps null: false
  end
end

class IdempotentExecutor < ApplicationRecord
  include ::IdempotentTransaction

  enum transaction_type: [:post_create]

  register_idempotent_column :user_id, :transaction_type, :signature
end
