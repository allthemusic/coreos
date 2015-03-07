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
    puts "Cluster Discovery Address = #{@cluster_discovery_address}"
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

client = DropletKit::Client.new(access_token: ENV.fetch('DIGITALOCEAN_API_TOKEN'))

nodes = NODE_COUNT.times.map { |nodeid|
  droplet = DropletKit::Droplet.new(node_data(nodeid + 1))
  warn "Creating #{droplet.name}..."
  client.droplets.create(droplet)
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

ready_nodes.each do |node|
  puts format("%-30s %s", node.name, node.networks.v4.select{ |n| n.type == 'public' }.map(&:ip_address).join(' '))
end
