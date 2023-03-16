module Mammoth
  class AboutMeTitleOption < ApplicationRecord
    self.table_name = 'mammoth_about_me_title_options'
    belongs_to :about_me_title, class_name: "Mammoth::AboutMeTitle"
  end
end