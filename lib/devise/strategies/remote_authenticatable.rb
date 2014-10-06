require 'httparty'
require 'json'

module Devise
  module Strategies
    class RemoteAuthenticatable < Authenticatable
      #
      # Method called by warden to authenticate a resource.
      #
      def authenticate!
        #
        # authentication_hash doesn't include the password
        #
        auth_params = authentication_hash
        auth_params[:password] = password

        # Check with the UK Server for the user
        uk_user_details = remote_authentication_uk_user(auth_params)

        # Fail if the user doesn't exist
        return fail!('Invalid email or password.') unless (uk_user_details and uk_user_details["status"] == "success")

        #
        # mapping.to is a wrapper over the resource model
        #
        
        # A UK user exists, so first try and find if they already have a local rails account
        resource = mapping.to.find_for_database_authentication(:email => uk_user_details["data"]["email"])
        
        # Rails.logger.debug "Resource pre-build: #{resource.to_json}"

        if not resource
          # If they don't have a rails account, make one
          resource = mapping.to.new
          build_user_from_uk_info(resource, uk_user_details)

          unless resource.save
            fail!(resource.unauthenticated_message)
            Rails.logger.debug "FAILED: #{resource.unauthenticated_message}"
          end

          # Rails.logger.debug "Resource built: #{resource.to_json}"
        else
          # TODO: They do have an account, so lets sync it with the UK data.
          Rails.logger.debug "Resource already here: #{resource.to_json}"
        end

        return fail! unless resource

        # validate is a method defined in Devise::Strategies::Authenticatable. It takes
        #a block which must return a boolean value.
        #
        # If the block returns true the resource will be loged in
        # If the block returns false the authentication will fail!
        #
        if validate(resource){ validate_resource(resource) }
          success!(resource)
        else
          fail!
        end
      end

      private

      def remote_authentication_uk_user(authentication_hash)
        # Returns a hash with the result

        api_endpoint = ENV["NI_UK_SUBSCRIBER_API"] + authentication_hash[:login] + "/" + authentication_hash[:password] + "/" + ENV["NI_UK_SUBSCRIBER_API_SECRET"]
        response = HTTParty.get(
          api_endpoint,
          headers: {}
        )
        
        if response.code == 200
          # Success!
          body = JSON.parse(response.body)
          Rails.logger.debug "SUCCESS! Found UK user: #{body["data"]["lname"]}, expiry: #{body["data"]["expiry"]}"
          return body
        elsif response.code == 404
          # User not found!
          body = JSON.parse(response.body)
          Rails.logger.debug "NOT FOUND! Can't find UK user with ID: #{authentication_hash[:login]}, lname: #{authentication_hash[:password]}"
          return body
        else
          # FAIL! server error.
          Rails.logger.debug "FAIL! UK Response code: #{response.code}"
          return nil
        end
      end

      def build_user_from_uk_info(user, uk_info)
        if user and uk_info
          user.email = uk_info["data"]["email"]
          user.username = uk_info["data"]["fname"] + uk_info["data"]["lname"]
          user.password = uk_info["data"]["lname"]
          user.password_confirmation = nil # So that Devise automatically encrypts the new password
          # TODO: Not in db yet...
          # user.uk_expiry = uk_info["data"]["uk_expiry"]
          # user.uk_id = uk_info["data"]["id"]
        end
      end

      def validate_resource(resource)
        if not resource.email.nil?
          return true
        else
          return false
        end
      end

    end
  end
end
