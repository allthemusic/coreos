# Bridgefog headless-node CoreOS setup

1. Have this repo available locally.
1. Use [OMC][] to launch an instance:

    ```shell
    omc launch ./omc/coreos-stack.digitalocean.scm
    ```

2. After this completes, use `fleetctl` to start the services.

    1. `cd` into the `systemd-units` directory.

    2. Also, make sure you have a recent-ish version of `fleetctl` installed locally.

    3. Set these variables set in your shell (they will be automatically set by direnv [see the `.envrc` file]):

        ```shell
        FLEETCTL_DRIVER=etcd
        FLEETCTL_ENDPOINT=http://localhost:2379
        ```

    4. Then ssh into the node while forwarding port 2379:

        ```shell
        ssh -L 2379:localhost:2379 -l core <IP>
        ```

    5. Now you can interact with the node (or more accurately, the whole cluster, via this node), using `fleetctl`:

        ```shell
        fleetctl list-machines
        ```

    6. To start the `ipfs` and `fog-headless-node` services, do this (this is where you must be in the `systemd-units` directory):

        ```shell
        fleetctl start ipfs fog-headless-node@1
        ```

        > Note: the `1` here in `fog-headless-node@1` is an arbitrary ID, not a
        > count or other meaningful value. It can be anything you like.

[OMC]: https://github.com/goodguide/omc
