# frozen_string_literal: true

# Define application-wide browser permissions policy.
Rails.application.config.permissions_policy do |policy|
  policy.camera :none
  policy.microphone :none
  policy.geolocation :none
end
