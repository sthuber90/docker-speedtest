#!/bin/sh
FILE="/opt/speedtest/test_connection.log"
INTERVAL=${TEST_INTERVAL:-900}
DATABASE="${INFLUXDB_DB:-speedtest}"

while true
do
	TIMESTAMP=$(date "+%s")

	echo "Run speedtest ..."
	# timeout and exit with 143 if speed test is not done within 300 seconds (5 minutes)
	timeout 300 speedtest --accept-license --accept-gdpr -u Mbps > $FILE

	EXIT_CODE=$?
	echo "Speedtest exited with $EXIT_CODE"
	# if exit code of speed test command is not 0 the speed test failed and it's save to assume that no internet connection exits
	if [ $EXIT_CODE -ne 0 ]
	then
		if [ $EXIT_CODE -eq 143 ]; then
			echo "Speedtest timed out."
		fi
		echo "Speedtest failed. No internet connection!"
		DOWNLOAD_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "download,host=local value=0")
		echo "Download (0 Mbit/s) send returned with $DOWNLOAD_RESP_CODE"
		UPLOAD_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "upload,host=local value=0")
		echo "Upload (0 Mbit/s) send returned with $UPLOAD_RESP_CODE"
		PL_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "packet_loss,host=local value=100")
		echo "Packet Loss (100 %) send returned with $PL_RESP_CODE"
	else
		DOWNLOAD=$(cat < $FILE | grep "Download:" | awk -F " " '{print $2}')
		UPLOAD=$(cat $FILE | grep "Upload:" | awk -F " " '{print $2}')
		PACKET_LOSS=$(cat $FILE | grep "Packet Loss:" | awk -F " " '{print $3}' | awk -F "%" '{print $1}')
		LATENCY=$(cat $FILE | grep "Latency:" | awk -F " " '{print $2}')
		JITTER=$(cat $FILE | grep "Latency:" | awk -F " " '{print $4}' | awk -F "(" '{print $2}')

		echo "Download: $DOWNLOAD"
		echo "Upload: $UPLOAD"
		echo "Packet Loss: $PACKET_LOSS"
		echo "Latency: $LATENCY"
		echo "Timestamp: $TIMESTAMP"
		DOWNLOAD_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "download,host=local value=$DOWNLOAD")
		echo "Download ($DOWNLOAD Mbit/s) send returned with $DOWNLOAD_RESP_CODE"
		UPLOAD_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "upload,host=local value=$UPLOAD")
		echo "Upload ($UPLOAD Mbit/s) send returned with $UPLOAD_RESP_CODE"
		PL_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "packet_loss,host=local value=$PACKET_LOSS")
		echo "Packet Loss ($PACKET_LOSS %) send returned with $PL_RESP_CODE"
		LAT_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "latency,host=local value=$LATENCY")
		echo "Latency ($LATENCY ms) send returned with $LAT_RESP_CODE"
		JITTER_RESP_CODE=$(curl --silent --show-error --write-out "%{http_code}" -XPOST "http://influxdb:8086/write?db=$DATABASE" --data-binary "jitter,host=local value=$JITTER")
		echo "Jitter ($JITTER ms) send returned with $JITTER_RESP_CODE"
	fi

	END_TIMESTAMP=$(date "+%s")
	DELTA=$(( INTERVAL - (END_TIMESTAMP - TIMESTAMP) ))
	echo "Sleep $INTERVAL before next run. $DELTA s remaining"
	sleep $DELTA

done
