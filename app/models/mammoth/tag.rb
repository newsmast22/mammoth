module Mammoth
  class Tag < Tag
    self.table_name = 'tags'
    has_many :status_tags, class_name: "Mammoth::StatusTag", foreign_key: "tag_id"
    scope :filter_with_words, ->(words) { where("LOWER(tags.name) like '%#{words}%' OR LOWER(tags.display_name) like '%#{words}%' ") }

  end
end