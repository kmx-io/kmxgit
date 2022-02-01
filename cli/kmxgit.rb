#!/usr/bin/env ruby

require 'capybara'
require 'io/console'
require 'json'
require 'open-uri'
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
    FileUtils.mkdir_p "git.kmx.io"
    Capybara.configure do |config|
      config.save_path = "git.kmx.io"
    end
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

def get_links
  local = []
  external = []
  local_img = []
  external_img = []
  links = []
  scripts = []
  @session.all("a").each do |elt|
    href = elt[:href].split("#")[0]
    if href.start_with?("https://git.kmx.io/")
      local << href.slice(18..)
    else
      external << href
    end
  end
  local = local.uniq.compact
  external = external.uniq.compact
  @session.all("img").each do |elt|
    href = elt[:src].split("#")[0]
    if href.start_with?("https://git.kmx.io/")
      local_img << href.slice(18..)
    else
      external_img << href
    end
  end
  local_img = local_img.uniq.compact
  external_img = external_img.uniq.compact
  @session.all("link", visible: false).each do |elt|
    links << elt[:href]
  end
  @session.all("script", visible: false).each do |elt|
    scripts << elt[:src]
  end
  {local: local,
   external: external,
   links: links,
   scripts: scripts}
end

def visited?(path)
  @visited[path]
end

def visited!(path)
  @visited[path] = true
end

def save_visited
  File.write("git.kmx.io/.visited.json", @visited.to_json)
end

def mirror_asset(path)
  p = path
  p = p.sub(/[#].*$/, "")
  p = p.sub(/[?].*$/, "")
  if !visited?(p)
    visited!(p)
    @visited << p
    url = "https://git.kmx.io" + path
    io = open(url)
    IO.copy_stream(io, "git.kmx.io" + p)
    save_visited()
  end
  p
end

def mirror_page(path)
  p = path
  p = p.sub(/[#].*$/, "")
  if p.end_with?("/")
    p = p + "index.html"
  end
  if File.directory?("git.kmx.io" + p)
    p = p + "/index.html"
  end
  if !visited?(p)
    visited!(p)
    url = "https://git.kmx.io" + path
    @session.visit(url)
    dir = "git.kmx.io"
    File.dirname(p).split("/").each do |item|
      dir = "#{dir}/#{item}"
      File.unlink(dir) if File.file?(dir)
    end
    @session.save_page("." + p)
    links = get_links()
    puts links.inspect
    links[:local_img].each do |local_img|
      mirror_asset(local_img)
    end
    links[:links].each do |link|
      mirror_asset(link)
    end
    links[:scripts].each do |script|
      mirror_asset(script)
    end
    links[:local].each do |local|
      mirror_page(local)
    end
    save_visited()
  end
  p
end

def mirror
  @visited = []
  mirror_page("/")
  1
end

main ARGV
