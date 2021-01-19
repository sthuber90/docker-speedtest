#!/bin/sh

INTERVAL=${TEST_INTERVAL:-60}
MINUTE_INTERVAL=$((INTERVAL / 60))

# check that speed test runs regularly by checking that file has been modified within $MINUTE_INTERVAL minutes
if [ "$(find /opt/speedtest -mmin -$MINUTE_INTERVAL -type f -name "test_connection.log" 2>/dev/null)" ]
then
  CHECK_EXIT_CODE=0
else
  CHECK_EXIT_CODE=1
fi

if [ $CHECK_EXIT_CODE -ne 0 ]
then
  echo "File \"/opt/speedtest/test_connection.log\" has not been changed by script for longer than $MINUTE_INTERVAL minutes"
fi


# ping InfluxDB and check connection works
INFLUXDB_URL="http://influxdb:8086/ping"
curl --fail -s "$INFLUXDB_URL"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]
then
  echo "InfluxDB cannot be reached at $INFLUXDB_URL"
fi

# end health check
if [ $CHECK_EXIT_CODE -ne 0 ] || [ $EXIT_CODE -ne 0 ]
then
  exit 1
fi

exit 0
