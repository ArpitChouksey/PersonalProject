import os
import json
import uuid
from datetime import datetime, timezone

import boto3
from confluent_kafka import Consumer


KAFKA_BOOTSTRAP_SERVERS = os.getenv(
    "KAFKA_BOOTSTRAP_SERVERS",
    "kafka:9092"
)

KAFKA_TOPIC = os.getenv(
    "KAFKA_TOPIC",
    "orders"
)

KAFKA_GROUP_ID = os.getenv(
    "KAFKA_GROUP_ID",
    "orders-s3-consumer"
)

S3_BUCKET = os.getenv(
    "S3_BUCKET",
    "private-eks-platform-raw-logs-211811255273"
)

S3_PREFIX = os.getenv(
    "S3_PREFIX",
    "raw/kafka/orders"
)


consumer_config = {
    "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
    "group.id": KAFKA_GROUP_ID,
    "auto.offset.reset": "earliest",
    "enable.auto.commit": False,
}

consumer = Consumer(consumer_config)

s3 = boto3.client("s3")

consumer.subscribe([KAFKA_TOPIC])


print("=" * 40)
print("Kafka → S3 Consumer Started")
print("=" * 40)
print(f"Kafka Broker  : {KAFKA_BOOTSTRAP_SERVERS}")
print(f"Kafka Topic   : {KAFKA_TOPIC}")
print(f"Consumer Group: {KAFKA_GROUP_ID}")
print(f"S3 Bucket     : {S3_BUCKET}")
print(f"S3 Prefix     : {S3_PREFIX}")
print("=" * 40)


try:

    while True:

        msg = consumer.poll(1.0)

        if msg is None:
            continue

        if msg.error():
            print(f"Kafka error: {msg.error()}")
            continue

        # Kafka metadata
        topic = msg.topic()
        partition = msg.partition()
        offset = msg.offset()

        # Kafka payload
        raw_value = msg.value()

        try:
            payload = raw_value.decode("utf-8")
        except Exception:
            payload = str(raw_value)

        # Event metadata
        event_id = str(uuid.uuid4())

        received_at = datetime.now(timezone.utc).isoformat()

        # Complete event record
        event = {
            "event_id": event_id,
            "received_at": received_at,
            "kafka_topic": topic,
            "kafka_partition": partition,
            "kafka_offset": offset,
            "payload": payload
        }

        print("")
        print("Received Kafka message:")
        print(f"  Topic     : {topic}")
        print(f"  Partition : {partition}")
        print(f"  Offset    : {offset}")
        print(f"  Payload   : {payload}")

        # S3 partition path
        now = datetime.now(timezone.utc)

        s3_key = (
            f"{S3_PREFIX}/"
            f"year={now.year}/"
            f"month={now.month:02d}/"
            f"day={now.day:02d}/"
            f"hour={now.hour:02d}/"
            f"{event_id}.json"
        )

        # Write JSON to S3
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=json.dumps(event).encode("utf-8"),
            ContentType="application/json"
        )

        print("")
        print("Successfully written to S3:")
        print(f"s3://{S3_BUCKET}/{s3_key}")

        # Commit only after successful S3 write
        consumer.commit(message=msg)

        print(
            f"Kafka offset committed: "
            f"{topic}/{partition}/{offset}"
        )

except KeyboardInterrupt:

    print("Stopping Kafka consumer...")

finally:

    consumer.close()

    print("Kafka consumer closed.")
