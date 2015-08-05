(define stack-name "coreos-stack")
(define region "sfo1")

(resource io/get_uri "DiscoveryURL" nil
          'uri (join "=" "https://discovery.etcd.io/new?size" core-cluster-size))

; (define discovery-url "https://discovery.etcd.io/ed718f2bb2cfadf33e1b4a6ef00de12c")

(resource io/get_uri "cloud-config" nil
          'uri "file:../cloud-config/digitalocean.yml")

(resource mustache/render "cloud-config" (list (dep 'template io/get_uri "cloud-config")
                                        (dep 'discovery io/get_uri "DiscoveryURL"))
          'template `(template 'contents)
          'bindings (vector
                      (mustache/binding "discovery_url" `(discovery 'contents))
                      (mustache/binding "fleet_metadata" (join "=" "region" region))))

(action coreos/validate_cloud_config "cloud-config" (list (dep 'cloud-config mustache/render "cloud-config"))
        'contents `(cloud-config 'contents))

(resource digital_ocean/droplet "core" (list (dep 'cloud-config mustache/render "cloud-config")
                                             (dep nil coreos/validate_cloud_config "cloud-config"))
          'name "coreos"
          'region region
          'size "2gb"
          'image "coreos-stable"
          'ssh_keys (vector
                      (digital_ocean/query/ssh_key "Macbook"))
          'backups #f
          'ipv6 #t
          'private_networking #t
          'user_data `(cloud-config 'contents))
