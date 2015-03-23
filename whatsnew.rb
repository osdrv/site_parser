#! /usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'digest/sha1'
require 'logger'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-synchrony/fiber_iterator'
require 'nokogiri'
require 'funda_listing_parser'

SOURCES    = 'SOURCES'
RECIPIENTS = 'RECIPIENTS'
LOCK       = 'LOCK'
LAST_RUN   = 'LAST_RUN'

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

def notify_if_new(channel, items)
  #TODO
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
    
    EM::Synchrony::FiberIterator.new(sources, concurrency).each do |src|
      response = EM::HttpRequest.new(src).get.response
      notify_if_new(Digest::SHA1.hexdigest(src), parse_response(response))
    end

    $log.info "Done."
    
    EM.stop

  end
end

main()
