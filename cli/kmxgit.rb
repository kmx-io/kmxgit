#!/usr/bin/env ruby

require 'capybara'
require 'io/console'
require 'optparse'

Options = Struct.new(:cmd, :user)

def usage()
  puts """Usage :
$ kmxgit (-h | --help)
    Display this help message and exit.
$ kmxgit [OPTIONS] (-m | --mirror)
    Mirror website
Available options :
  -u USER | --user=USER         Login as USER.
"""
end

def main(argv)
  @options = Options.new(nil, nil)
  OptionParser.new do |opts|
    opts.on("-h", "--help") do
      @options.cmd = :help
    end
    opts.on("-m", "--mirror") do
      @options.cmd = :mirror
    end
    opts.on("-uUSER", "--user=USER") do |user|
      @options.user = user
    end
  end.parse!
  case @options.cmd
  when :help
    usage()
    return 0
  when :mirror
    @session = Capybara::Session.new(:selenium)
    if @options.user
      login()
    end
    return mirror()
  else
    usage()
    return 1
  end
end

def login()
  @session.visit("https://git.kmx.io/_log_in")
  while @session.has_selector?('form #user_password')
    password = IO::console.getpass("Password: ")
    @session.fill_in 'Login', with: @options.user
    @session.fill_in 'Password', with: password
    @session.click_button 'Submit'
  end
  while @session.has_selector?('form #user_totp')
    totp = IO::console.getpass("TOTP: ")
    @session.fill_in 'TOTP', with: totp
    @session.click_button 'Submit'
  end
  if @session.current_path == "/_log_in"
    raise "Failed to login"
  end
end

def mirror
  1
end

main ARGV
