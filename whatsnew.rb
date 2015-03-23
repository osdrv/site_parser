#! /usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-synchrony/fiber_iterator'
require 'nokogiri'
require 'funda_listing_parser'

SOURCES             = 'SOURCES'
LOCK                = 'LOCK'
LAST_RUN            = 'LAST_RUN'

$log = nil

def parse_response(response)
  doc = Nokogiri::HTML(response)
  elements = doc.css(FundaListingParser.listing_element_css)
  elements.each do |element|
    parsed_obj = FundaListingParser.parse_slop(element)
    $log.debug parsed_obj
  end
end

def main

  $log = Logger.new(STDOUT)
  $log.level = Logger::DEBUG

  $log.info 'Reading the sources file'
  
  sources = []
  File.new(SOURCES, 'r').each_line do |line|
    sources.push line
  end
  
  EM.synchrony do
    
    Signal.trap('INT')  { EM.stop }
    Signal.trap('TERM') { EM.stop }
    
    concurrency = 2
    
    EM::Synchrony::FiberIterator.new(sources, concurrency).each do |src|
      response = EM::HttpRequest.new(src).get.response
      parse_response response
    end

    $log.info "Done."
    
    EM.stop

  end
end

main()
