require 'paperclip'

module PaperclipLambda
  class Railtie < Rails::Railtie
    initializer "paperclip_lambda.insert_into_active_record" do |app|
      ActiveSupport.on_load :active_record do
        PaperclipLambda::Railtie.insert
      end
    end
  end

  class Railtie
    def self.insert
      ActiveRecord::Base.send(:include, PaperclipLambda::Glue)
      Paperclip::Attachment.send(:include, PaperclipLambda::Attachment)
    end
  end
end
