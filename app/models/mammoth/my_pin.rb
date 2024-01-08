# frozen_string_literal: true

# == Schema Information
#
# Table name: my_pins
#
#  id              :bigint(8)        not null, primary key
#  account_id      :bigint(8)
#  rank            :integer
#  pinned_obj_type :string
#  pinned_obj_id   :bigint(8)
#  pin_type        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class MyPin < ApplicationRecord
  enum pin_type: { community: 0, hashtag: 1, menu: 2, other: 3 } 
  belongs_to :account
  belongs_to :pinned_obj, polymorphic: true
end
