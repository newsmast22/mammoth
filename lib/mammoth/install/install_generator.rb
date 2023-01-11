module Mammoth
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    def copy_initializer_file
      copy_file "mammoth_initializer.rb", Rails.root + "config/initializers/mammoth.rb"
    end
    
    def rake_db
      rake("mammoth:install:migrations")
      rake("db:migrate")
    end
    
  end
end