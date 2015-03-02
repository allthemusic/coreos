#!/usr/bin/env ruby
#
require 'bundler/setup'
Bundler.require

NODE_COUNT = 3

client = DropletKit::Client.new(access_token: ENV.fetch('DIGITALOCEAN_API_TOKEN'))

def node_data(nodeid)
  {
    name: format("core-%02d.allthemusic.org", nodeid),
    region: "sfo1",
    size: "2gb",
    image: "10679356",
    user_data: File.read(File.expand_path('../cloud-config.userdata.yml', __FILE__)),
    ssh_keys: [236464],
    ipv6: true,
  }
end


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
