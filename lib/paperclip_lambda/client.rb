require 'aws-sdk'
require_relative 'credential'

module PaperclipLambda
  class Client
    attr_reader :errors

    def initialize(function_name, location, bucket)
      @location = location
      @bucket   = bucket
      lambda    = ::Aws::Lambda::Client.new(aws_options)
      lambda.invoke(function_name: function_name, payload: request_body.to_json, invocation_type: "Event")
    rescue Exception => e
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

    private

    def env_credential
      key =    %w(AWS_ACCESS_KEY_ID     AMAZON_ACCESS_KEY_ID     AWS_ACCESS_KEY)
      secret = %w(AWS_SECRET_ACCESS_KEY AMAZON_SECRET_ACCESS_KEY AWS_SECRET_KEY)
      Credential.new(envar(key), envar(secret))
    end

    def envar(keys)
      keys.each do |key|
        return ENV[key] if ENV.key?(key)
      end

      nil
    end

    def aws_options
      aws_credential_obj = env_credential
      return { } unless aws_credential_obj.set?

      {
        access_key_id: aws_credential_obj.access_key_id,
        secret_access_key: aws_credential_obj.secret_access_key,
        region: "us-west-2"
      }
    end
  end
end
