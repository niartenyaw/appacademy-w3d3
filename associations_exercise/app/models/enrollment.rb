class Enrollment < ActiveRecord::Base
  validates :student_id, presence: true
  validates :course_id, presence: true


  belongs_to :student,
    primary_key: :id,
    foreign_key: :student_id,
    class_name: :User

  belongs_to :course,
    primary_key: :id,
    foreign_key: :course_id,
    class_name: :Course
end
