# frozen_string_literal: true
require 'telegram/bot'
require 'envyable'
require 'awesome_print'
require_relative 'kmb/get_stops.rb'
require_relative 'kmb/get_eta.rb'

Envyable.load(File.expand_path('env.yml', File.dirname( __FILE__)))


def handle_command(message)
  command, param = parse_command(message.text)
  case command
  when /\/start/i, /\/help/i
    @bot.api.send_message(chat_id: message.chat.id, text: help_message)
  when /\/route/i
    response = handle_route(param)
    @bot.api.send_message(chat_id: message.chat.id, text: response) if response
  when /\/stops/i
    response = handle_stop(param)
    if response.is_a?(Telegram::Bot::Types::InlineKeyboardMarkup)
      @bot.api.send_message(chat_id: message.chat.id, text: 'Which stop?', reply_markup: response)
    else
      @bot.api.send_message(chat_id: message.chat.id, text: response)
    end
  when /\/eta/i
    response = handle_eta(param)
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

def handle_message(message)
  # pass
end

def handle_route(param)
  route = param
  if route =~ /^[a-z0-9]+$/i
    kmbGetStops = Kmb::GetStops.new(route, '1')
    if basic_info = kmbGetStops.basic_info
      orig = basic_info['OriCName']
      dest = basic_info['DestCName']
      "if you are going from #{dest} to #{orig}, add '2' when you call /stops or /eta, otherwise, there is no need to add '2'"
    else
      'wait something is wrong'
    end
  else
    'are you sure this is a route?'
  end
end

def handle_stop(param)
  route, bound = param.split(' ', 2)
  bound ||= '1'
  if route =~ /^[a-z0-9]+$/i
    kmbGetStops = Kmb::GetStops.new(route, bound)
    if route_stops = kmbGetStops.route_stops
      basic_info = kmbGetStops.basic_info
      kb = []
      route_stops.each do |stop|
        text = "#{basic_info['OriCName']} 去 #{stop['CName']}"
        eta_command = "eta #{route} #{stop['BSICode'].gsub('-', '')} #{bound}"
        kb.push Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: eta_command)
      end
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      markup
    else
      'wait something is wrong'
    end
  else
    'are you sure this is a route?'
  end
end


def handle_stop_old(param)
  route, bound = param.split(' ', 2)
  bound ||= '1'
  if route =~ /^[a-z0-9]+$/i
    kmbGetStops = Kmb::GetStops.new(route, bound)
    if route_stops = kmbGetStops.route_stops
      response = "To see the ETA to these stations, use these code\n"
      route_stops.each do |stop|
        response += "#{stop['CName']} #{stop['BSICode'].gsub('-', '')}\n"
      end
      eta_command = "/eta #{route} #{route_stops[0]['BSICode'].gsub('-', '')}"
      eta_command += bound == '1' ? '' : ' 2'
      response += "If you want to know the ETA to #{route_stops[0]['CName']}, type '#{eta_command}'"
      response
    else
      'wait something is wrong'
    end
  else
    'are you sure this is a route?'
  end
end

def handle_eta(param)
  route, bsi, bound = param.split(' ', 3)
  bound ||= '1'
  if route =~ /^[a-z0-9]+$/i
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
  else
    'are you sure this is a route?'
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
    ap message
    case message
    when Telegram::Bot::Types::CallbackQuery
      if message.data =~ /^eta [a-zA-Z0-9]+ [A-Z0-9]+ [1|2]$/
        command, param = parse_command(message.data)
        response = handle_eta(param)
        @bot.api.send_message(chat_id: message.from.id, text: response) if response
      end
    when Telegram::Bot::Types::Message
      if is_command?(message)
        handle_command(message)
      else
        handle_message(message)
      end
    end
  end
end

