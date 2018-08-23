# == Schema Information
#
# Table name: trainings
#
#  id          :bigint(8)        not null, primary key
#  time        :datetime
#  price       :integer
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#  client_id   :integer
#  status      :integer
#

class Training < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :clients
  belongs_to :client
  has_many :exercises

  validates :client_id, :time, presence: true
  validates :price, :numericality => { :greater_than => 0 }
  validates :description, presence: false

  enum status: [:planned, :complete, :canceled]
end
