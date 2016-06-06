require 'paperclip_lambda/client'
require 'paperclip_lambda/attachment'
require 'paperclip_lambda/railtie' if defined?(Rails)

module PaperclipLambda
  class << self
    def options
      @options ||= {
        function_name: nil
      }
    end

    def invoke_client(obj, attachment_name)
      avatar = obj.send(attachment_name)
      lambda_options = obj.class.name.constantize.paperclip_definitions[attachment_name][:lambda]
      return nil unless avatar.options[:s3_credentials]

      PaperclipLambda::Client.new(obj.send(lambda_options[:function_name]), avatar)
    end
  end

  module Glue
    def self.included(base)
      base.extend(ClassMethods)
      base.send :include, InstanceMethods
    end
  end

  module ClassMethods
    def process_in_lambda(name, function_name)
      paperclip_definitions[name][:lambda] = { }
      paperclip_definitions[name][:lambda][:function_name] = function_name

      if respond_to?(:after_commit)
        after_commit :process_lambda
      else
        after_save :process_lambda
      end
    end

    def paperclip_definitions
      @paperclip_definitions ||= if respond_to? :attachment_definitions
        attachment_definitions
      end
    end
  end

  module InstanceMethods
    def process_lambda
      (@_attachment_for_lambda_processing || []).each do |name|
        enqueue_post_processing_for(name)
      end

      @_attachment_for_lambda_processing = []
    end

    def enqueue_post_processing_for(name)
      PaperclipLambda.invoke_client(self, name)
    end

    def prepare_enqueueing_for(name)
      @_attachment_for_lambda_processing ||= []
      @_attachment_for_lambda_processing << name
    end
  end
end
