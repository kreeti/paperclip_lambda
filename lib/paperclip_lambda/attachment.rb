module PaperclipLambda
  module Attachment
    def self.included(base)
      base.send :include, InstanceMethods
      base.send(:alias_method, :save_without_lambda, :save)
      base.send(:alias_method, :save, :save_with_lambda)


      base.send(:alias_method, :queue_all_for_delete_without_lambda, :queue_all_for_delete)
      base.send(:alias_method, :queue_all_for_delete, :queue_all_for_delete_with_lambda)
#      base.send(:alias_method, :destroy_without_lambda, :destroy)
 #     base.send(:alias_method, :destroy, :destroy_with_lambda)
    end

    module InstanceMethods
      def save_with_lambda
        was_dirty = @dirty

        save_without_lambda.tap do
          if was_dirty
            instance.prepare_enqueueing_for(name)
          end
        end
      end

      def process_update_in_lambda(options = {})
        lambda_definitions = instance.class.paperclip_definitions[name][:lambda]
        attributes_hash = { }

        lambda_definitions[:attributes].each do |attribute|
          attributes_hash[attribute] = instance.send(attribute)
        end

        payload = {
          path: path,
          old_path: options[:old_path],
          bucket: instance.send(name).options[:bucket],
          attributes: attributes_hash
        }

        PaperclipLambda::Client.new(lambda_definitions[:function_name], payload)

        if instance.respond_to?(:"#{name}_processing?")
          instance.send("#{name}_processing=", false)
          instance.class.where(instance.class.primary_key => instance.id).update_all({ "#{name}_processing" => false })
        end
      end

      def queue_all_for_delete_with_lambda
        instance.prepare_enqueueing_for_deletion(name)
        queue_all_for_delete_without_lambda
      end
    end
  end
end
