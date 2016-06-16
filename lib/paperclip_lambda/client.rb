require 'aws-sdk'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(function_name, payload = {})
      lambda = ::Aws::Lambda::Client.new
      lambda.invoke(function_name: function_name, payload: payload.to_json, invocation_type: "Event")
    rescue ::Aws::Lambda::Errors::ServiceError => e
      @errors = e
    end
  end
end
