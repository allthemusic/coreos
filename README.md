# Minimal mini-Coreos-cluster provisioning

This is just a small script to create some DigitalOcean Droplets running IPFS on CoreOS, in a new cluster. The purpose is to create a manually-connected, reliable IPFS cluster to develop against, during this time while IPFS nodes are so ephemeral and unreliable.

(Note that the "manually connected" aspect is not yet implemented.)

## Usage

1. `bundle install` - Use a ruby >= 2.0
1. Set environment variables
    ```
    DIGITALOCEAN_API_TOKEN=<your personal access token>
    DIGITALOCEAN_SSH_KEY_ID=<api id for the ssh key you want it to use>
    CLUSTER_DOMAIN=<some domain>
    ```

1. See `cloud-config.userdata.yml` and ensure everything there looks good. The discovery url is represented by `{{discovery_url}}` and is replaced by the launcher tool with a new discovery URL by requesting <https://discovery.etcd.io/new>; you can supply the discovery URL as the only argument to the launcher script if you prefer.

1. Run the launch command
    ```shell
    ./launch_some_servers.rb
    ```

The file `last_batch.json` now contains details about the launched droplets and the IPFS peer IDs.

## Additional

If you have [Tugboat][] installed, you can also kill the cluster using
`./killall-servers.sh`


[Tugboat]: https://github.com/pearkes/tugboat
