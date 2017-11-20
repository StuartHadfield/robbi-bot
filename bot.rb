require 'sinatra/base'
require 'slack-ruby-client'
require 'httparty'

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

class Events
  def self.message(team_id, event_data)
    user_id = event_data['user']

    # Don't process messages sent from our bot user
    unless user_id == $teams[team_id][:bot_user_id]
      answer = self.assign_message_response(team_id, event_data)

      # SHARED MESSAGE EVENT
      # To check for shared messages, we must check for the `attachments` attribute
      # # and see if it contains an `is_shared` attribute.
      if event_data['attachments'] && event_data['attachments'].first['is_share']
        # We found a shared message
        user_id = event_data['user']
        ts = event_data['attachments'].first['ts']
        channel = event_data['channel']
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
    if event_data['text'].downcase  =~ /help/i
      "I see you asked for help! You can ask me for `help` or for a `menu`, but "\
      "other than that, I don't really know what I'm capable of just yet, nor "\
      "does my creator... check back soon though! :wink:"
    elsif event_data['text'].downcase  =~ /hello/i || event_data['text'].downcase  =~ /hi robbi/i
      "Hello! I'm hearing you loud and clear, over."
    elsif event_data['text'].downcase =~ /menu/i
      "I haven't had time to browse the Molten menu thoroughly yet... You're just gonna get a large cap anyway though right?"
    elsif event_data['text'].downcase =~ /order/i
      order_config = event_data['text'].split(',') rescue ['order', 'flat_white']
      options = {
        body: {
          order: { # your resource
            menu_item: order_config.last, # your columns/data
            name: user_name
          }
        }
      }
      response = HTTParty.post('https://25400ab2.ngrok.io/orders', options)
      if response.code == 200
        response_body = JSON.parse(response.body)
        "Molten server says: #{response_body['message']}, id: #{response['order']['id']}, what you ordered: #{response['order']['menu_item']}, ordered for: #{response['order']['name']}"
      else
        "Fuck.  Order failed."
      end
    else
      "Hey #{user_name}, I'm still growing up and I don't understand English too well.. Please bear with me while I learn!"
    end
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
