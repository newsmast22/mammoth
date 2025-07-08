module Mammoth
  class UserCommunity < ApplicationRecord
    self.table_name = 'mammoth_communities_users'

    belongs_to :community 
    belongs_to :user

    def self.export_migration_csv
      require 'csv'

      accounts = Account.joins(:user)
                .where(
                  suspended_at: nil,
                  domain: nil,
                  actor_type: ['Person', nil]
                )
                .where(
                  'users.step IS NULL AND users.is_account_setup_finished = TRUE'
                )

      csv_data = CSV.generate(headers: true) do |csv|
        csv << ['handle', 'communities']

        accounts.each do |account|
          joined_communities = {}
          user = User.where(account_id: account.id).last
          user_communities = Mammoth::UserCommunity.where(user_id: user.id).where.not(community_id: 161)

          unless user_communities.empty?
            primary_community = user_communities.where(is_primary: true).last
            if primary_community
              primary_community = Mammoth::Community.find(primary_community.community_id)
              joined_communities.merge!("primary" => primary_community.slug.tr("_","-"))
            end

            other_communities = user_communities.where(is_primary: false)
            if other_communities.any?
              other_communities = Mammoth::Community.where(id: other_communities.pluck(:community_id))
              joined_communities.merge!("others" => other_communities.pluck(:slug).map { |slug| slug.tr("_","-") })
            end

            csv << ["@#{account.username}@newsmast.social", joined_communities.to_json]  
          end
          
        end
      end

      # Save file relative to Rails.root
      file_path = Rails.root.join('user_community_export.csv')
      File.write(file_path, csv_data)
      puts "CSV exported to: #{file_path}"
    end
  end
end