# app/models/drafted_status_wrapper.rb
module Mammoth

  class DraftedStatusWrapper
    include ActiveModel::Model

    attr_accessor :date, :data

    def initialize(attributes = {})
    @date = attributes[:date]
    @data = attributes[:data]
    end

    def self.model_name
    ActiveModel::Name.new(self, nil, "DraftedStatusWrapper")
    end
  end
end
