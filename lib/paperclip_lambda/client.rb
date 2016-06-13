require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(lambda_options)
      @location = lambda_options[:location]
      @bucket   = lambda_options[:bucket]
      @degree = lambda_options[:degree]
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
        rotation: @degree,
        delete_location: @delete_location
      }
    end
  end
end
