#//# --------------------------------------------------------------------------------------
#//# Created using Sequence Diagram for Mac
#//# https://www.macsequencediagram.com
#//# https://itunes.apple.com/gb/app/sequence-diagram/id1195426709?mt=12
#//# --------------------------------------------------------------------------------------
#
# Illustrative diagram to show 
#
title "Lambda & CloudWatch Embedded Metrics"

box "AWS CloudWatch" #ffff00 .1
participant Logs
participant Metrics
participant Insights
end box

note over (:---:) Metrics
"""
The behaviour show here is illustrative!
"""
end note
*->+Logs: print(metrics)\nto Log Group
||50||

Logs->+Logs: Write to\nLog Stream
Logs->Logs: Parse for\nEmbedded Metrics

opt [ Metrics Found ]
Logs->+Metrics: Push Metrics\nto custom\nNamespace
deactivate Logs
Metrics->Metrics: Process\nMetrics
note over (:---:) Metrics
"""
The custom metrics can be
viewed, consumed and applied
just like all other metrics
"""
end note
end
deactivate Metrics

== Need to analyse logging arises... ==

activate Insights
loop [ Log Analysis ]
Insights->Logs: Query Log Group
note over (:---:) Insights
"""
The queries can be rich and detailed
exploring and retrieving all aspects
of the stored data, including the
metrics that feed CloudWatch Metrics
but also the invocation specific data
such as unique identifiers
"""
end note
Logs-->Insights: Results
end

deactivate Insights
