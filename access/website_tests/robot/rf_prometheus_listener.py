"""
Listener that posts results to Prometheus

https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#listener-interface

"""

import os
import re
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

ROBOT_LISTENER_API_VERSION = 3

PUSH_GATEWAY = os.environ['PUSH_GATEWAY']
JOB_NAME = os.environ.get('PROMETHEUS_JOB_NAME', 'robot_framework_tests')

registry = CollectorRegistry()

g = Gauge('robot_framework_test_passed', 'Result from a Robot Framework test.', ['name'], registry=registry)
gt = Gauge('robot_framework_test_suite_timestamp', 'Timestamp of a Robot Framework test suite.', ['name'], registry=registry)

def slugify(text):
    text = text.lower()
    return re.sub(r'[\W_]+', '_', text)

def end_suite(suite, result):
    # Record the timestamp of suite execution:
    suite_name = slugify(result.name)
    gt.labels(suite_name).set_to_current_time()

def end_test(test, result):
    # Record the outcome of each test:
    test_name = slugify(result.name)
    if result.passed:
        g.labels(test_name).set(1)
    else:
        g.labels(test_name).set(0)

def close():
    # Push the results somewhere useful...
    push_to_gateway(PUSH_GATEWAY, job=JOB_NAME, registry=registry)
