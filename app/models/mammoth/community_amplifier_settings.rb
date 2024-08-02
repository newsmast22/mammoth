module Mammoth
  class CommunityAmplifierSettings < ApplicationRecord
    self.table_name = 'mammoth_community_amplifier_settings'
    belongs_to :user, class_name: "Mammoth::User"
    belongs_to :mammoth_community, class_name: "Mammoth::Community"

    def get_amplifier_status 
      amplifier_setting&.dig("is_filter_turn_on") || false
    end
  end
end