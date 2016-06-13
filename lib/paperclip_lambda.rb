require 'paperclip_lambda/client'
require 'paperclip_lambda/attachment'
require 'paperclip_lambda/railtie' if defined?(Rails)

module PaperclipLambda
  class << self
    def options
      @options ||= {
        function_name: nil,
        processor: [:rotation]
      }
    end

    def invoke_client(obj, attachment_name, destroy = false)
      avatar = obj.send(attachment_name)
      rotate_attr = obj.class.name.constantize.paperclip_definitions[attachment_name][:lambda][:rotation]

      lambda_options = {
        function_name: obj.class.name.constantize.paperclip_definitions[attachment_name][:lambda][:function_name],
        degree: (rotate_attr && obj.respond_to?(rotate_attr)) ? obj.send(rotate_attr) : 0,
        location: avatar.path,
        delete_location: destroy,
        bucket: avatar.options[:bucket]
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

      PaperclipLambda.options[:processor].each do |option|
        paperclip_definitions[name][:lambda][option] = option if options[:processor].include?(option)
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

      (@_attachment_for_lambda_deleting || []).each_with_index do |name, index|
        enqueue_delete_processing_for(name, @_attachment_deleting_path[index])
      end

      @_attachment_for_lambda_processing = []
      @_attachment_for_lambda_deleting = []
      @_attachment_deleting_path = []
    end

    def enqueue_post_processing_for(name)
      attachment_changed = previous_changes[name.to_s + "_updated_at"]

      if attachment_changed && attachment_changed.first.present?
        path = send(name).path.split('/')
        delete_path = path.tap(&:pop).concat([previous_changes[name.to_s + "_file_name"].first]).join('/')

        PaperclipLambda.invoke_client(self, name, delete_path)
      else
        PaperclipLambda.invoke_client(self, name)
      end
    end

    def enqueue_delete_processing_for(name, delete_path)
      PaperclipLambda.invoke_client(self, name, delete_path)
    end

    def prepare_enqueueing_for(name)
      @_attachment_for_lambda_processing ||= []
      @_attachment_for_lambda_processing << name
    end

    def prepare_deleting_for(name)
      @_attachment_for_lambda_deleting ||= []
      @_attachment_for_lambda_deleting << name

      @_attachment_deleting_path ||= []
      @_attachment_deleting_path << send(name).path
    end
  end
end
