# frozen_string_literal: true
require 'telegram/bot'
require 'envyable'
require_relative 'kmb/get_stops.rb'
require_relative 'kmb/get_eta.rb'

Envyable.load(File.expand_path('env.yml', File.dirname( __FILE__)))


def handle_command(message)
  command, param = parse_command(message.text)
  case command
  when /\/start/i, /\/help/i
    response = command_handler do
      help_message
    end
    respond_with(message.chat.id, response)
  when /\/route/i
    response = command_handler(param, 1, [/^[a-z0-9]+$/i], 'give me a route number like /route 91m') do |params|
      handle_route(params)
    end
    @bot.api.send_message(chat_id: message.chat.id, text: response)
  when /\/stops/i
    response = command_handler(param, 1, [/^[a-z0-9]+$/i], 'give me a route number like /stops 91m') do |params|
      handle_stop(params)
    end
    respond_with(message.chat.id, response, 'which stop?')
  when /\/eta/i
    response = command_handler(param, 2, [/^[a-z0-9]+$/i, nil], 'try running /stops if you donno what you are doing') do |params|
      handle_eta(params)
    end
    @bot.api.send_message(chat_id: message.chat.id, text: response) if response
  end
end

def parse_command(text)
  text.split(' ', 2)
end

def is_command?(message)
  if message.respond_to?(:entities)
    message[:entities].each do |val|
      return true if val[:type] == 'bot_command'
    end
  end
  false
end

def command_handler(param = nil, params_count = 0, param_regexp = [], default_response = 'something is wrong', &block)
  params = (param || '').split(' ')
  param_ok = params.length >= params_count
  params.each_with_index do |p, i|
    if param_regexp[i] && !(p =~ param_regexp[i])
      param_ok = false
    end
  end
  if block && param_ok
    block.call(params)
  else
    default_response
  end
end

def respond_with(chat_id, response = 'something is wrong', extra = nil)
  case response
  when String
    @bot.api.send_message(chat_id: chat_id, text: response)
  when Telegram::Bot::Types::InlineKeyboardMarkup
    @bot.api.send_message(chat_id: chat_id, text: extra, reply_markup: response)
  end
end

def handle_message(message)
  # pass
end

def handle_route(params)
  route = params[0]
  kmbGetStops = Kmb::GetStops.new(route, '1')
  if basic_info = kmbGetStops.basic_info
    orig = basic_info['OriCName']
    dest = basic_info['DestCName']
    "So you are going from #{orig} to #{dest}? Otherwise, add '2' at the end of your command like /stops 91m 2"
  else
    'wait something is wrong'
  end
end

def handle_stop(param)
  route, bound = param
  bound ||= '1'
  kmbGetStops = Kmb::GetStops.new(route, bound)
  if route_stops = kmbGetStops.route_stops
    basic_info = kmbGetStops.basic_info
    kb = []
    route_stops.each do |stop|
      text = "#{stop['CName']} 去 #{basic_info['DestCName']}"
      eta_command = "eta #{route} #{stop['BSICode'].gsub('-', '')} #{bound}"
      kb.push Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: eta_command)
    end
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
    markup
  else
    'wait something is wrong'
  end
end

def handle_eta(param)
  route, bsi, bound = param
  bound ||= '1'
  kmbGetEta= Kmb::GetETA.new(route, bound, bsi)
  if eta = kmbGetEta.eta
    response = "Eta to this stop is:\n"
    eta.each do |e|
      response += "#{e['t']}\n"
    end
    response += eta.empty? ? 'No data' : ''
    response
  else
    'wait something is wrong'
  end
end

def help_message
  """
This bot provides NO WARRANTY and IS NOT affiliated with The Kowloon Motor Bus Co. (1933) Ltd.
To get route information, type something like /route 91m
To get stops information, type something like /stops 91m
To get eta information, follow the instruction after typing /stops 91m
  """
end

Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
  @bot = bot
  @bot.listen do |message|
    if ENV['VERIFIED_USERS'].include?(message.from.username)
      case message
      when Telegram::Bot::Types::CallbackQuery
        if message.data =~ /^eta [a-zA-Z0-9]+ [A-Z0-9]+ [1|2]$/
          command, param = parse_command(message.data)
          response = handle_eta(param.split(' ', 3))
          @bot.api.send_message(chat_id: message.from.id, text: response) if response
          @bot.api.answerCallbackQuery(callback_query_id: message.id)
        end
      when Telegram::Bot::Types::Message
        if is_command?(message)
          handle_command(message)
        else
          handle_message(message)
        end
      end
    else
      @bot.api.send_message(chat_id: message.from.id, text: 'your prayer is not heard')
    end
  end
end

