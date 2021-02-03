#
# a trivial function to demonstrate CloudWatch Embedded metrics with as much focus on that
# as possible, which is another way of saying much of it is a tad clumsy, but it works and
# it was created to be as simple as possible...
# 
# ¯\_(ツ)_/¯
#

import logging
import random
import http.client
import json
import time
from urllib.parse import urlparse

#
# https://pypi.org/project/aws-embedded-metrics/
#
# There is a Python module that can be used, however, in order to keep things simple for getting
# this function into AWS (i.e. no messing with a build process), a Python dictionary is used to
# keep things Python native... however, it'd look something along these lines(ish):
#
# from aws_embedded_metrics import metric_scope
# from aws_embedded_metrics.config import get_config
# Config = get_config()
# Config.service_name = "ServiceName"
#
# @metric_scope
# def lambda_handler(event, context):
#
#   metrics.set_namespace("Example/Namespace")
#   metrics.set_dimensions({"Endpoint": endpoint}) 
#   metrics.put_metric("Success", success, "Count")
#   metrics.put_metric("ResponseLatency", response_latency, "Milliseconds")
#   metrics.set_property("CorrelationId", correlation_id)
#   metrics.set_property("FullPath", random_path)


current_milli_time = lambda: int(round(time.time() * 1000))

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info('{} ({}) with event: {}'.format(context.function_name, context.function_version, event)) # https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html

    #
    # loop a few times, purely to generate some variation in the example data
    #
    for _ in range((current_milli_time() % 20) + 1):

        #
        # inject an error from time-to-time, and randomise the endpoint API to invoke
        #
        target = "httpbin.org"
        paths = ["/uuid", "/anything?a=b&c=d", "/get?location={}".format(random.choice(["Manchester", "London"])), "/status/102,203,303,418,505"]
        endpoint = random.choices([target, "inv@lid"], weights=(98,2), k=1)[0]
        random_path = random.choice(paths)

        success = 0
        error = 0
        connection_time = 0
        response_time = 0
        response = None
        message = ""

        try:
            start_time = current_milli_time()
            connection = http.client.HTTPSConnection(endpoint, timeout=3)
            connection.connect() # not required, but demonstrates the point about timings
            connection_time = current_milli_time() - start_time
            logger.debug("HTTPS connection to {} took {}ms".format(endpoint, connection_time))

            start_time = current_milli_time()
            connection.request("GET", random_path)
            response = connection.getresponse()
            response_time = current_milli_time() - start_time
            logger.debug("Request/Response took {}ms".format(response_time))
            success = 1
            message = response.reason

            #
            # byte sequence returned, so deserialise directly to a dictionary
            #
            try:
                json_response = json.loads(response.read().decode('utf-8'))
                if logger.isEnabledFor(logger.DEBUG):
                    for quay in json_response.keys():
                        logger.debug("k=[{}]: v=[{}]".format(quay, json_response[quay]))
            except:
                pass
            
        except Exception as e:
            logger.exception("Exception attempting to retrieve from {}: {}".format(endpoint, e))
            error = 1
            message = str(e)

        #
        # Build the dictionary according to the CloudWatch Embedded Metrics spec: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html
        #
        # A custom namespace is defined that'll show up in CloudWatch Metrics, the metric 
        # Dimensions are needed like any metric, and they are classified, so integers and
        # milliseconds in this case. The high cardinality data is rendered so that queries
        # can be made via CloudWatch Insights as necessary.
        #
        # The first four are examples of a Dimension (Endpoint), Counter (Success), Duration
        # (ResponseLatency) and finally a Property [aka high cardinality data] (CorrelationId)
        #
        metrics = {
            "Endpoint": endpoint,
            "Success": success,
            "ResponseLatency": response_time,
            "CorrelationId": context.aws_request_id,

            "Operation": urlparse(random_path).path.split('/', 2)[1],
            "FullPath": random_path,
            "Error": error,
            "Invocations": 1,
            "ConnectionLatency": connection_time,
            "Status": response.status if response else 0,
            "Message": message,

            "_aws": {
                "Timestamp": current_milli_time(),
                "CloudWatchMetrics": [
                    {
                        "Dimensions": [
                            [
                                "Endpoint"
                            ],
                            [
                                "Endpoint",
                                "Operation"
                            ]
                        ],
                        "Metrics": [
                            {
                                "Name": "Success",
                                "Unit": "Count"
                            },
                            {
                                "Name": "Error",
                                "Unit": "Count"
                            },
                            {
                                "Name": "Invocations",
                                "Unit": "Count"
                            },
                            {
                                "Name": "ConnectionLatency",
                                "Unit": "Milliseconds"
                            },
                            {
                                "Name": "ResponseLatency",
                                "Unit": "Milliseconds"
                            }
                        ],
                        "Namespace": "Example/Namespace"
                    }
                ]
            }
        }

        #
        # Not all fields need to be present, only add if there was a payload in the response...
        #
        try:
            json_response
            metrics['Data'] = json_response
        except:
            pass

        #
        # The data can be print with or without the logger - strong preference is for without,
        # so that when Insights is used, the @message doesn't have unnecessary prefix text
        # plus it means that if log levels were altered (best practice would be to have the
        # level externalised) there is no risk that the log level could be set and result in
        # the data not being written - using ERROR or WARN to avoid that, seems wrong as this
        # isn't either of those things...
        #
        print(json.dumps(metrics))
    
    return