require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(function_name, avatar)
      @location = avatar.path
      @bucket   = avatar.options[:s3_credentials][:bucket]

      lambda = ::Aws::Lambda::Client.new
      lambda.invoke(function_name: function_name, payload: request_body.to_json, invocation_type: "Event")
    rescue ::Aws::Lambda::Errors::ServiceError => e
      @errors = e
    end

    def request_body
      {
        bucket: {
          name: @bucket
        },
        location: @location
      }
    end
  end
end
