module Mammoth
  class Account < Account
    self.table_name = 'accounts'
    belongs_to :media, class_name: "Mammoth::Media",  optional: true
    belongs_to :voice, class_name: "Mammoth::Voice",  optional: true
    belongs_to :contributor_role, class_name: "Mammoth::ContributorRole",  optional: true
    belongs_to :subtitle, class_name: "Mammoth::Subtitle",  optional: true

    scope :filter_timeline_with_countries,->(country_alpah2_name) {where(country: country_alpah2_name)}
    scope :filter_timeline_with_contributor_role,->(id) {where( "contributor_role_id && ARRAY[?]::integer[]",id)}
    scope :filter_timeline_with_voice,->(id) {where("voice_id && ARRAY[?]::integer[] ", id)}
    scope :filter_timeline_with_media,->(id) {where("media_id && ARRAY[?]::integer[] ", id)}
  end
end