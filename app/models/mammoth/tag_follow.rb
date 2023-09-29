module Mammoth
    class TagFollow < TagFollow
        belongs_to :tag
        belongs_to :account
    end
end