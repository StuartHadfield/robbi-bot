require 'sinatra/base'
require 'slack-ruby-client'

# This class contains all of the webserver logic for processing incoming requests from Slack.
class API < Sinatra::Base
  # This is the endpoint Slack will post Event data to.
  post '/events' do
    # Extract the Event payload from the request and parse the JSON
    request_data = JSON.parse(request.body.read)
    # Check the verification token provided with the request to make sure it matches the verification token in
    # your app's setting to confirm that the request came from Slack.
    unless SLACK_CONFIG[:slack_verification_token] == request_data['token']
      halt 403, "Invalid Slack verification token received: #{request_data['token']}"
    end

    case request_data['type']
      # When you enter your Events webhook URL into your app's Event Subscription settings, Slack verifies the
      # URL's authenticity by sending a challenge token to your endpoint, expecting your app to echo it back.
      # More info: https://api.slack.com/events/url_verification
      when 'url_verification'
        request_data['challenge']

      when 'event_callback'
        # Get the Team ID and Event data from the request object
        team_id = request_data['team_id']
        event_data = request_data['event']

        # Events have a "type" attribute included in their payload, allowing you to handle different
        # Event payloads as needed.
        case event_data['type']
          when 'message'
            # Event handler for messages, including Share Message actions
            Events.message(team_id, event_data)
          else
            # In the event we receive an event we didn't expect, we'll log it and move on.
            puts "Unexpected event:\n"
            puts JSON.pretty_generate(request_data)
        end
        # Return HTTP status code 200 so Slack knows we've received the Event
        status 200
    end
  end

  post '/flat_white' do
    # test event
  end
end

# This class contains all of the Event handling logic.
class Events
  # You may notice that user and channel IDs may be found in
  # different places depending on the type of event we're receiving.

  def self.message(team_id, event_data)
    user_id = event_data['user']
    # Don't process messages sent from our bot user
    unless user_id == $teams[team_id][:bot_user_id]
      # This is where our `message` event handlers go:
      answer = self.assign_message_response(team_id, event_data)
      # SHARED MESSAGE EVENT
      # To check for shared messages, we must check for the `attachments` attribute
      # # and see if it contains an `is_shared` attribute.
      if event_data['attachments'] && event_data['attachments'].first['is_share']
        # We found a shared message
        user_id = event_data['user']
        ts = event_data['attachments'].first['ts']
        channel = event_data['channel']
        # Update the `share` section of the user's tutorial
        # Update the user's tutorial message
        self.send_response(team_id, user_id, channel, ts, answer)
      else
        user_id = event_data['user']
        channel = event_data['channel']
        self.send_response(team_id, user_id, channel, answer)
      end
    end
  end

  def self.assign_message_response(team_id, event_data)
    user_name = $teams[team_id]['client'].users_info(user: event_data['user'])['user']['name']
    "Hey #{user_name}, I'm still growing up and I don't understand English too well.. Please bear with me while I learn!"
  end

  # Send a response to an Event via the Web API.
  def self.send_response(team_id, user_id, channel, ts = nil, text)
    $teams[team_id]['client'].chat_postMessage(
      as_user: 'true',
      channel: channel,
      text: text
    )
  end

end
