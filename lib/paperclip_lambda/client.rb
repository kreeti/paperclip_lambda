require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(lambda_options, attribute_hash)
      @location = lambda_options[:location]
      @bucket   = lambda_options[:bucket]
      @attribute_hash = attribute_hash
      @delete_location = lambda_options[:delete_location]

      lambda = ::Aws::Lambda::Client.new
      lambda.invoke(function_name: lambda_options[:function_name], payload: request_body.to_json, invocation_type: "Event")
    rescue ::Aws::Lambda::Errors::ServiceError => e
      @errors = e
    end

    def request_body
      {
        bucket: {
          name: @bucket
        },
        location: @location,
        delete_location: @delete_location
      }.merge(@attribute_hash)
    end
  end
end
