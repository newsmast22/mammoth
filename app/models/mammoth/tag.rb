module Mammoth
  class Tag < Tag
    self.table_name = 'tags'
    scope :filter_with_words, ->(words) { where("LOWER(tags.name) like '%#{words}%' OR LOWER(tags.display_name) like '%#{words}%' ") }

  end
end