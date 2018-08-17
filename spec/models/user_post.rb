ActiveRecord::Schema.define do
  create_table :user_posts do |t|
    t.integer :user_id, null: false
    t.string :title, null: false

    t.index [:user_id]

    t.timestamps null: false
  end
end

class UserPost < ApplicationRecord
end
