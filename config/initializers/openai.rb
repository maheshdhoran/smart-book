require 'openai'

CLIENT = OpenAI::Client.new(access_token: ENV["API_KEY"])
