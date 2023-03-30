module Mammoth
  class Engine < ::Rails::Engine
    isolate_namespace Mammoth

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    # initializer :append_services do |app|
    #   unless app.root.to_s.match root.to_s
    #     config.paths["app/services/mammoth"].expanded.each do |expanded_path|
    #       app.config.paths["app/services/mammoth"] << expanded_path
    #     end
    #   end
    # end

    config.autoload_paths << File.expand_path("../app/services/mammoth", __FILE__)
    config.autoload_paths << File.expand_path("../app/workers/mammoth", __FILE__)

  end
end
