module Mammoth
    class AlttextGetAccount
        
        attr_accessor :name, :webhook_url, :notification_email, :usage, :usage_limit, :whitelabel, :default_lang, :subscription, :errors

        def initialize(attributes = {})
            @name = attributes['name']
            @webhook_url = attributes['webhook_url']
            @notification_email = attributes['notification_email']
            @usage = attributes['usage']
            @usage_limit = attributes['usage_limit']
            @whitelabel = attributes['whitelabel']
            @default_lang = attributes['default_lang']
            @subscription = attributes['subscription']
            @errors = attributes['errors'] || nil
        end

        def has_errors?
            @errors.present?
        end
    end
end