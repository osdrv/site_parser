#! /usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'digest/sha1'
require 'logger'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-synchrony/fiber_iterator'
require 'nokogiri'
require 'mandrill'
require 'funda_listing_parser'
require 'email_tmpl_funda'

SOURCES    = 'SOURCES'
RECIPIENTS = 'RECIPIENTS'
# LOCK       = 'LOCK'
LAST_RUN   = 'LAST_RUN'
INDEX_EXT  = '.index'

$log = nil

def parse_response(response)
  doc = Nokogiri::HTML(response)
  elements = doc.css(FundaListingParser.listing_element_css)
  res = []
  elements.each do |element|
    parsed_obj = FundaListingParser.parse_slop(element)
    res.push parsed_obj
  end
  
  res
end

def notify_if_new(channel, items, to)
  return if !items.length
  channel_id = Digest::SHA1.hexdigest(channel)
  index_file_name = "#{channel_id}#{INDEX_EXT}"
  last_index = nil
  f = File.open(index_file_name, 'a+')
  f.each_line do |line|
    last_index = line
    break
  end
  new_items = []
  new_index = items.first[:id]
  items.each do |item|
    if item[:id] == last_index
      break
    end
    new_items.push item
  end

  $log.debug "Last index: #{last_index}"
  $log.debug "New index: #{new_index}"
  $log.debug "Found #{new_items.length} new items"

  if new_items.length == 0
    $log.info "No new items found. Omitting"
    return
  end
  
  msg_body = EmailTmplFunda.render(channel, new_items)
  send_email(to, {
    from:    'me@4pcbr.com',
    subject: 'New apartments found',
    body:    msg_body
  })
  
  f.close
  f = File.open(index_file_name, 'w')
  f.write(new_index)
  f.close
end

def send_email(to, opts={})
  m = Mandrill::API.new(ENV['MANDRIL_API_KEY'])
  message = {  
   :subject=> opts[:subject],
   :from_name=> "Oleg S",
   :to => to.map { |e|
     {
       :email => e,
       :type => 'to'
     }
   },
   :html => opts[:body],
   :from_email => opts[:from]
  }
  m.messages.send message
end

def main

  $log = Logger.new(STDOUT)
  $log.level = Logger::DEBUG

  $log.info 'Reading the sources file'
  
  sources = []
  File.new(SOURCES, 'r').each_line { |line|
    sources.push line
  }.close
  
  sources = sources.map { |s| s.strip }
  $log.debug "Sources: #{sources}"
  
  recipients = []
  File.new(RECIPIENTS, 'r').each_line { |line|
    recipients.push line
  }.close
  
  recipients = recipients.map { |r| r.strip }
  $log.debug "Recipients: #{recipients}"
  
  EM.synchrony do
    
    Signal.trap('INT')  { EM.stop }
    Signal.trap('TERM') { EM.stop }
    
    concurrency = 2
    
    EM::Synchrony.add_periodic_timer(5 * 60) do 
    
      EM::Synchrony::FiberIterator.new(sources, concurrency).each do |src|
        response = EM::HttpRequest.new(src).get.response
        begin
          notify_if_new(src, parse_response(response), recipients)
        rescue Exception => e
          $log.error(e)
        end
      end

      $log.info "Done."
    
    end
    
  end
end

main()
