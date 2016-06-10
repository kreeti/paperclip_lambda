require 'paperclip_lambda/client'
require 'paperclip_lambda/attachment'
require 'paperclip_lambda/railtie' if defined?(Rails)

module PaperclipLambda
  class << self
    def options
      @options ||= {
        function_name: nil,
        rotator: nil
      }
    end

    def invoke_client(obj, attachment_name, destroy = false)
      avatar = obj.send(attachment_name)
      rotate_attr = obj.class.name.constantize.paperclip_definitions[attachment_name][:lambda][:rotator]

      lambda_options = {
        function_name: obj.class.name.constantize.paperclip_definitions[attachment_name][:lambda][:function_name],
        degree: (rotate_attr && obj.respond_to?(rotate_attr)) ? obj.send(rotate_attr) : 0,
        location: avatar.path,
        bucket: avatar.options[:bucket],
        destroy: destroy
      }

      PaperclipLambda::Client.new(lambda_options)
    end
  end

  module Glue
    def self.included(base)
      base.extend(ClassMethods)
      base.send :include, InstanceMethods
    end
  end

  module ClassMethods
    def process_in_lambda(name, function_name, options = { })
      paperclip_definitions[name][:lambda] = { }
      paperclip_definitions[name][:lambda][:function_name] = function_name

      {
        rotator: PaperclipLambda.options[:rotator]
      }.each do |option, default|
        paperclip_definitions[name][:lambda][option] = options.key?(option) ? options[option] : default
      end

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
      if attachment_changed = previous_changes[:image_updated_at] && attachment_changed.first.present?
        PaperclipLambda.invoke_client(self, name, previous_changes[:image_file_name].first)
      else
        PaperclipLambda.invoke_client(self, name)
      end
    end

    def enqueue_delete_processing_for(name)
      PaperclipLambda.invoke_client(self, name, true)
    end

    def prepare_enqueueing_for(name)
      @_attachment_for_lambda_processing ||= []
      @_attachment_for_lambda_processing << name
    end
  end
end
