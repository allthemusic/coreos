(configure 'aws_region "us-west-2")

(define stack-name "coreos-stack")
(define core-cluster-size "1")
(define worker-cluster-size "1")

(resource io/get_uri "DiscoveryURL" nil
          'uri (join "=" "https://discovery.etcd.io/new?size" core-cluster-size))

; (define discovery-url "https://discovery.etcd.io/ed718f2bb2cfadf33e1b4a6ef00de12c")

(resource aws/cloud_formation/stack nil (list (dep 'discovery io/get_uri "DiscoveryURL"))
          'name "coreos"
          'template_url "file://../cloudformation/coreos-stack.template"
          'timeout_in_minutes 600
          'notification_arn "arn:aws:sns:us-east-1:529134598602:aws-notifications"
          ; 'notification_arn "arn:aws:sns:us-west-2:529134598602:aws-notifications"
          'tags (vector (aws/tag 'name "Application" 'value stack-name))
          'parameters (vector
                        (aws/cloud_formation/parameter
                          'name "KeyPair"
                          'value "main")
                        (aws/cloud_formation/parameter
                          'name "CoreClusterSize"
                          'value core-cluster-size)
                        (aws/cloud_formation/parameter
                          'name "WorkerClusterSize"
                          'value worker-cluster-size)
                        (aws/cloud_formation/parameter
                          'name "DiscoveryURL"
                          'value `(discovery 'contents)
                          ; 'value discovery-url
                          )
                        (aws/cloud_formation/parameter
                          'name "WorkerInstanceType"
                          'value "t2.medium")
                        (aws/cloud_formation/parameter
                          'name "CoreInstanceType"
                          'value "t2.micro")))


(action aws/cloud_formation/wait_stack nil (list (dep 'stack aws/cloud_formation/stack nil))
        'stack_id `(stack 'stack_id)
        'operation `(stack 'operation)
        'timeout 600)

; (action debug/pp "works" (list (dep 'stack aws/cloud_formation/wait_stack nil))
;         'value `(stack 'stack_outputs))

; (action debug/pp "fails" (list
;                            (dep nil debug/pp "works")
;                            (dep 'stack aws/cloud_formation/wait_stack nil))
;         'value `(fetch "ELBDnsName" (stack 'stack_outputs)))
