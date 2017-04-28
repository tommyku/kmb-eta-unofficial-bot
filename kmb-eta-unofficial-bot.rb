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
  when /\/start/i
    @bot.api.send_message(chat_id: message.chat.id, text: 'Your voice will be heard.')
  when /\/route/i
    response = handle_route(param)
    @bot.api.send_message(chat_id: message.chat.id, text: response) if response
  when /\/stops/i
    response = handle_stop(param)
    @bot.api.send_message(chat_id: message.chat.id, text: response) if response
  when /\/eta/i
    response = handle_eta(param)
    @bot.api.send_message(chat_id: message.chat.id, text: response) if response
  end
end

def parse_command(text)
  text.split(' ', 2)
end

def is_command?(message)
  message[:entities].each do |val|
    return true if val[:type] == 'bot_command'
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
      response = ''
      eta.each do |e|
        response += "#{e['t']}\n"
      end
      response
    else
      'wait something is wrong'
    end
  else
    'are you sure this is a route?'
  end
end

Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
  @bot = bot
  @bot.listen do |message|
    ap message
    if is_command?(message)
      handle_command(message)
    else
      handle_message(message)
    end
  end
end

