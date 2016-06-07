module PaperclipLambda
  module Attachment
    def self.included(base)
      base.send :include, InstanceMethods
      base.send(:alias_method, :save_without_lambda, :save)
      base.send(:alias_method, :save, :save_with_lambda)
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
    end
  end
end
