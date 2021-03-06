#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'
require 'tmail'
require 'net/imap'
require 'net/http'

config = YAML.load(File.read(File.join(File.dirname(__FILE__), 'config.yml')))

SLEEP_TIME = 5

loop do
  begin
    puts "Connecting"
    imap = Net::IMAP.new(config['host'], config['port'], true)
    imap.login(config['username'], config['password'])
    imap.select('callstoplace')
    
    30.times do
      puts 'Checking for new mail'
    
      imap.uid_search(["NOT", "DELETED"]).each do |uid|
        source   = imap.uid_fetch(uid, ['RFC822']).first.attr['RFC822']
      
        email = TMail::Mail.parse(source)
        number_to_call = email.body.strip
        number_to_call = "435" + number_to_call if number_to_call.length == 7 
        puts command = "./caller #{number_to_call} #{config['forwarding_number']}"
        puts `#{command}`
      
        imap.uid_copy(uid, "callsplaced")
        imap.uid_store(uid, "+FLAGS", [:Seen, :Deleted])
      end
    
      imap.expunge
      
      sleep(1)
    end
    imap.logout
    imap.disconnect
  rescue Net::IMAP::NoResponseError => e
    puts "NoResponseError: #{e.message}"
  rescue Net::IMAP::ByeResponseError => e
    puts "ByeResponseError: #{e.message}"
  rescue => e
    puts "Error: #{e.message}"
  end
  
  sleep(SLEEP_TIME)
end