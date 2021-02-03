#//# --------------------------------------------------------------------------------------
#//# Created using Sequence Diagram for Mac
#//# https://www.macsequencediagram.com
#//# https://itunes.apple.com/gb/app/sequence-diagram/id1195426709?mt=12
#//# --------------------------------------------------------------------------------------
#
# Trivial AWS Lambda function that performs a
# simple interaction with an arbitrary endpoint
# to illustrate data & identifiers and wall
# clock timings captured and sent to the
# AWS CloudWatch Logs service...
#
title "Lambda & CloudWatch Embedded Metrics"

participant Lambda
participant Endpoint
participant "CloudWatch Logs" as Logs

*->+Lambda: Invoke...
Lambda->Lambda: Store salient identifiers
activate Lambda
Lambda->Lambda: Store wall clock time\ninteraction start
Lambda->>+Endpoint: Connect

Lambda->Endpoint: Request
Lambda->Lambda: Store wall clock time\nrequested
||50||
Endpoint->Lambda: Response
destroy Endpoint
Lambda->-Lambda: Store wall clock time\nresponse received

Lambda->Lambda: Process Response

Lambda->+Lambda: Construct Metrics
note over (:---:) Lambda
"""
Counters, atomic durations etc. and
high cardinality data such as
unique & non-unique identifiers
"""
end note

Lambda->>+Logs: print(metrics)
deactivate Lambda
