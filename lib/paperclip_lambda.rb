require 'paperclip_lambda/client'
require 'paperclip_lambda/attachment'
require 'paperclip_lambda/lambda_job'
require 'paperclip_lambda/railtie' if defined?(Rails)

module PaperclipLambda
  class << self
    def process_delete_in_lambda(klass, attachment_name, options = {})
      PaperclipLambda::Client.new(klass.name.constantize.paperclip_definitions[attachment_name][:lambda][:function_name], options)
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
      paperclip_definitions[name][:lambda][:attributes] = options[:attributes] || []

      if respond_to?(:after_commit)
        after_commit :enqueue_lambda_processing
      else
        after_save :enqueue_lambda_processing
      end
    end

    def paperclip_definitions
      @paperclip_definitions ||= if respond_to? :attachment_definitions
        attachment_definitions
      end
    end
  end

  module InstanceMethods
    def enqueue_lambda_processing
      mark_enqueue_lambda_processing

      (@_attachment_for_lambda_processing || []).each do |name|
        enqueue_post_processing_for(name)
      end

      (@_attachment_for_lambda_deleting || []).each do |name_and_path|
        unless name_and_path.blank?
          enqueue_delete_processing_for(name_and_path)
        end
      end

      @_attachment_for_lambda_processing = []
      @_attachment_for_lambda_deleting = []
    end

    def mark_enqueue_lambda_processing
      unless @_attachment_for_lambda_processing.blank? # catches nil and empty arrays
        updates = @_attachment_for_lambda_processing.collect{|n| "#{n}_processing = :true" }.join(", ")
        updates = ActiveRecord::Base.send(:sanitize_sql_array, [updates, {:true => true}])
        self.class.where(:id => id).update_all(updates)
      end
    end

    def enqueue_post_processing_for(name)
      attachment_changed = previous_changes[name.to_s + "_updated_at"]
      file_array = previous_changes[name.to_s + "_file_name"]

      if attachment_changed && attachment_changed.first.present? && (file_array.uniq.length == file_array.length)
        old_path = send(name).path.split('/')
        old_path = old_path.tap(&:pop).concat([file_array.first]).join('/')
        PaperclipLambda::LambdaJob.perform(self.class, self.id, name, { old_path: old_path })
      else
        PaperclipLambda::LambdaJob.perform(self.class, self.id, name)
      end
    end

    def enqueue_delete_processing_for(name_and_path)
      name, old_path = name_and_path
      PaperclipLambda::LambdaJob.perform(self.class, self.id, name, { bucket: send(name).options[:bucket], old_path: old_path })
    end

    def prepare_enqueueing_for(name)
      @_attachment_for_lambda_processing ||= []
      @_attachment_for_lambda_processing << name
    end

    def prepare_enqueueing_for_deletion(name)
      @_attachment_for_lambda_deleting ||= []
      @_attachment_for_lambda_deleting << [name, send(name).path]
    end
  end
end
