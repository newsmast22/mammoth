module Mammoth

  class AppVersionHistory < ApplicationRecord
    self.table_name = 'mammoth_app_version_historys'
    belongs_to :app_version, class_name: "Mammoth::AppVersion"
  end
end