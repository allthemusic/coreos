(configure 'aws_region "us-west-2")

(define stack-name "coreos-stack")
(define cluster-size "3")

(resource io/http_request "DiscoveryURL" nil
          'url (join "=" "https://discovery.etcd.io/new?size" cluster-size))

(resource aws/cloud_formation/stack nil (list (dep 'discovery io/http_request "DiscoveryURL"))
          'name "InternalTools"
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
                          'name "ClusterSize"
                          'value "3")
                        (aws/cloud_formation/parameter
                          'name "DiscoveryURL"
                          'value `(discovery 'response))
                        (aws/cloud_formation/parameter
                          'name "InstanceType"
                          'value "t2.micro")))


(action aws/cloud_formation/wait_stack nil (list (dep 'stack aws/cloud_formation/stack nil))
        'stack_id `(stack 'stack_id)
        'target_state `(stack 'target_state)
        'timeout 600)

; (action debug/pp "works" (list (dep 'stack aws/cloud_formation/wait_stack nil))
;         'value `(stack 'stack_outputs))

; (action debug/pp "fails" (list
;                            (dep nil debug/pp "works")
;                            (dep 'stack aws/cloud_formation/wait_stack nil))
;         'value `(fetch "ELBDnsName" (stack 'stack_outputs)))
