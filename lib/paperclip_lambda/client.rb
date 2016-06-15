require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(lambda_options)
      @path = lambda_options[:path]
      @bucket   = lambda_options[:bucket]
      @attributes = lambda_options[:attributes]
      @old_path = lambda_options[:old_path]

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
        path: @path,
        old_path: @old_path,
        attributes: @attributes
      }
    end
  end
end
