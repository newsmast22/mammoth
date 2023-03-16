module Mammoth
  class AboutMeTitle < ApplicationRecord
    self.table_name = 'mammoth_about_me_titles'
    has_many :about_me_title_options, class_name: "Mammoth::AboutMeTitleOption"

  end
end