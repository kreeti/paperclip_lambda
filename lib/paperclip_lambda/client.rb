require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(lambda_options, avatar)
      @location = avatar.path
      @bucket   = avatar.options[:bucket]
      @degree = lambda_options[:degree]

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
        rotation: @degree
      }
    end
  end
end
