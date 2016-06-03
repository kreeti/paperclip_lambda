require 'paperclip_lambda/client'

module PaperclipLambda
  class Base
    def initialize(options = { })
      @function_name = options[:function_name]
      @location      = options[:location_style]
      @bucket        = options[:bucket]
    end

    def invoke
      client = PaperclipLambda::Client.new(@function_name, @location, @bucket)

      if client.errors.present?
        return { success: false, error: client.errors.message }
      end

      { success: true }
    end
  end
end
