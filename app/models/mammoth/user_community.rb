module Mammoth
  class UserCommunity < ApplicationRecord
    self.table_name = 'mammoth_communities_users'

    belongs_to :community 
    belongs_to :user

      def self.export_migration_csv
        require 'csv'
        # Query with proper joins and selected fields
        records = Account.joins(user: { user_communities: :community })
                        .select(
                          'accounts.username',
                          'accounts.domain',
                          'mammoth_communities.name',
                          'mammoth_communities.slug',
                          'mammoth_communities_users.is_primary'
                        )
                        .where(
                          'users.is_active = TRUE
                            AND users.step IS NULL
                            AND users.is_account_setup_finished = TRUE'
                        )
        # Generate CSV
        csv_data = CSV.generate(headers: true) do |csv|
          csv << ['username', 'domain', 'name', 'slug', 'is_primary']

          records.each do |record|
            csv << [
              record.username,
              record.domain.presence || 'newsmast.social',
              record.name.presence || '',
              record.slug.presence || '',
              record.is_primary
            ]
          end
        end

        # Save file relative to Rails.root
        file_path = Rails.root.join('user_community_export.csv')
        File.write(file_path, csv_data)
        puts "CSV exported to: #{file_path}"
      end
  end
end