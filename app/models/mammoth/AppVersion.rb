module Mammoth

  class AppVersion < ApplicationRecord
    self.table_name = 'mammoth_app_versions'
    has_many :app_version_hostories, class_name: "Mammoth::AppVersionHistory"

  end
end