class User < ApplicationRecord
  rolify
  belongs_to :organization
  accepts_nested_attributes_for :organization
  validates :password, length: { maximum: 10 }
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
end
