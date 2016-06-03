module PaperclipLambda

  class Credential
    attr_reader :access_key_id, :secret_access_key

    def initialize(access_key_id, secret_access_key)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
    end

    def set?
      !access_key_id.nil? && !access_key_id.empty? &&
      !secret_access_key.nil? && !secret_access_key.empty?
    end
  end

end
