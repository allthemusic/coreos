# Bridgefog headless-node CoreOS setup

1. Use [OMC][] to launch an instance:

    ```shell
    omc launch omc/coreos-stack.digitalocean.scm
    ```

2. After this completes, use fleetctl to start the services:

    ```shell
    cd system-units/
    fleetctl start ipfs fog-headless-node@1
    ```

[OMC]: https://github.com/goodguide/omc
