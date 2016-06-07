require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(function_name, avatar)
      @location = avatar.path
      @bucket   = avatar.options[:s3_credentials][:bucket]

      lambda    = ::Aws::Lambda::Client.new(access_key_id: avatar.options[:s3_credentials][:access_key_id], secret_access_key: avatar.options[:s3_credentials][:secret_access_key], region: avatar.options[:s3_region])
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
