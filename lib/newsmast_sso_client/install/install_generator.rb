module NewsmastSsoClient
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    def copy_initializer_file
      copy_file "newsmast_initializer.rb", Rails.root + "config/initializers/newsmast.rb"
    end
    
    def rake_db
      rake("newsmast_sso_client:install:migrations")
      rake("db:migrate")
    end
    
  end
end