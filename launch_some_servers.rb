#!/usr/bin/env ruby
#
require 'bundler/setup'
Bundler.require

require 'open-uri'

SSH_KEY_ID = ENV.fetch('DIGITALOCEAN_SSH_KEY_ID')

IMAGES = {
  coreos_stable: 'coreos-stable',
  coreos_beta: 'coreos-beta',
  coreos_alpha: 'coreos-alpha',
}

NODE_COUNT = 3

DOMAIN_NAME = ENV.fetch('CLUSTER_DOMAIN', 'allthemusic.org')

def user_data
  return @user_data if defined?(@user_data)
  file = File.read(File.expand_path('../cloud-config.userdata.yml', __FILE__))
  @user_data ||= file.gsub('{{discovery_url}}', cluster_discovery_address)
end

def cluster_discovery_address
  return @cluster_discovery_address if defined?(@cluster_discovery_address)
  if (@cluster_discovery_address = ARGV.shift)
    URI.parse(@cluster_discovery_address)
  else
    @cluster_discovery_address = open('https://discovery.etcd.io/new').read
    warn "Cluster Discovery Address = #{@cluster_discovery_address}"
  end
  @cluster_discovery_address
end

def node_data(nodeid)
  {
    name: format("core-%02d.%s", nodeid, DOMAIN_NAME),
    region: "sfo1",
    size: "2gb",
    image: IMAGES[:coreos_beta],
    user_data: user_data,
    ssh_keys: [SSH_KEY_ID],
    ipv6: true,
  }
end

def wait_for_ipfs(ip_address)
  count = 0
  begin
    open("http://#{ip_address}:5001/api/v0/id")
  rescue => ex
    # p count: count, ip_address: ip_address, ex: ex
    count += 1
    unless count >= 300
      Thread.pass
      sleep 1
      STDERR.putc ?.
      retry
    end
    raise
  end
end

client = DropletKit::Client.new(access_token: ENV.fetch('DIGITALOCEAN_API_TOKEN'))

existing_nodes = client.droplets.all.to_a.select {|n| /core-\d+.allthemusic.org/.match(n.name) }

nodes = (existing_nodes.length...(existing_nodes.length + NODE_COUNT)).map { |nodeid|
  droplet = DropletKit::Droplet.new(node_data(nodeid + 1))
  warn "Creating #{droplet.name}..."
  response = client.droplets.create(droplet)
  unless response.is_a?(DropletKit::Droplet)
    raise RuntimeError, response
  end
  response
}

ready_nodes, new_nodes = [], nodes

until new_nodes.empty?
  new_nodes = new_nodes.map { |node|
    warn "Checking on #{node.name}..."
    node = client.droplets.find(id: node.id)

    if node.networks.v4.empty?
      node
    else
      ready_nodes << node
      nil
    end
  }.compact
  sleep 1
end

warn "\n\n"

node_details = {}
ready_nodes.each do |node|
  ip_address = node.networks.v4.detect{ |n| n.type == 'public' }.ip_address
  warn "Node #{node.name} is available at #{ip_address}"

  node_details[node.name] = {
    digital_ocean_id: node.id,
    name: node.name,
    ip_address: ip_address,
    ssh_user: 'core',
  }
end

warn "\n\n"

warn "Running `ssh-keygen -R` for each node IP..."
node_details.each_value do |node|
  system "ssh-keygen", "-R", node[:ip_address]
end

warn "\nWaiting for IPFS to become available..."
threads = []
node_details.each_value do |n|
  threads << Thread.new(n) do |node|
    response = wait_for_ipfs(node[:ip_address])

    warn "\n#{node[:name]} is ready\n"
    node[:ipfs_peer_id] = Oj.load(response.read)['ID']

    node_webui = "http://#{node[:ip_address]}:5001/webui"
    system "open", node_webui
  end
end
threads.each(&:join)

File.open('last_batch.json', 'w') do |file|
  data = {
    discovery: cluster_discovery_address,
    nodes: node_details,
  }
  file.puts Oj.dump(data, mode: :compat, indent: 2)
end

puts
puts 'Use this to add these domains to /etc/hosts'
puts %q{ (echo ; jq -r '.nodes[] | "\(.ip_address)\t\(.name)"' < last_batch.json) >> /etc/hosts" }
