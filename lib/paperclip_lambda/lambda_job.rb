require 'aws-sdk'

module PaperclipLambda
  class LambdaJob < ActiveJob::Base
    def perform(klass, object_id, attachment_name, options = {})
      if instance = klass.constantize.find_by_id(object_id)
        instance.send(attachment_name).process_update_in_lambda(options)
      else
        klass.constantize.process_delete_in_lambda(attachment_name, options)
      end
    end
  end
end
