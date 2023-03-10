module Mammoth
  class Account < Account
    self.table_name = 'accounts'
    belongs_to :media, class_name: "Mammoth::Media",  optional: true
    belongs_to :voice, class_name: "Mammoth::Voice",  optional: true
    belongs_to :contributor_role, class_name: "Mammoth::ContributorRole",  optional: true
    belongs_to :subtitle, class_name: "Mammoth::Subtitle",  optional: true

    scope :primary_timeline_countries_filter,->(country_alpah2_name) {where(country: country_alpah2_name)}
    scope :primary_timeline_contributor_role_filter,->(id) {where( contributor_role_id: id)}
    scope :primary_timeline_voice_filter,->(id) {where(voice_id: id)}
    scope :primary_timeline_media_filter,->(id) {where(media_id: id)}
  end
end