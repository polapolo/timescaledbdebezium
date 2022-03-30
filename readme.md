# Integrate timescaledb with debezium

- Dockerfile Example to integrate with Debezium https://github.com/paul-ylz-tw/debetime_example/blob/main/Dockerfile
- Docker Image that already integrate with Debezium https://hub.docker.com/r/polokuro/timescaledb-debezium
- https://www.youtube.com/watch?v=YZRHqRznO-o&ab_channel=CodewithIrtiza
- https://github.com/irtiza07/postgres_debezium_cdc
- https://redpanda.com/blog/redpanda-debezium/

# Search Kafka Connect Plugin

- https://www.confluent.io/hub/

# Integrate kafka connect with jdbc source sink plugin

- Kafka Connect Base https://hub.docker.com/r/confluentinc/cp-kafka-connect
- Kafka Connect Plugin JDBC Connector (Source & Sink) https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc
- Connect Worker JDBC Config Options https://docs.confluent.io/kafka-connect-jdbc/current/sink-connector/sink_config_options.html
- https://docs.confluent.io/platform/current/connect/references/restapi.html

# Schema Registry / Converter

- Converter Concept https://www.confluent.io/blog/kafka-connect-deep-dive-converters-serialization-explained
- AVRO https://docs.confluent.io/platform/current/schema-registry/connect.html#avro
- Schema Registry Endpoint https://docs.confluent.io/platform/current/schema-registry/develop/api.html
- Schema Registry Endpoint Usagehttps://docs.confluent.io/platform/current/schema-registry/develop/using.html

# Transform

- https://docs.confluent.io/platform/current/connect/transforms/overview.html

# Create Tables

```
CREATE TABLE IF NOT EXISTS orders (
    id text,
    user_id BIGINT,
    stock_code varchar(6),
    type VARCHAR(1),
    lot BIGINT,
    price int,
    status int,
    created_at TIMESTAMP,
    PRIMARY KEY(id)
);

CREATE TABLE trades (
    order_id BIGINT,
    lot BIGINT,
    lot_multiplier int,
    price int,
    total BIGINT,
    created_at TIMESTAMP NOT null,
    CONSTRAINT trades_pkey PRIMARY KEY (order_id,created_at)
);
SELECT create_hypertable('trades','created_at');
```

# Step By Step

1. Spin up all the services `sudo docker-compose up`
2. Create connector config `curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" 127.0.0.1:8083/connectors/ --data "@connector/order-insert-connector.json"`

# Insert Order

1. Create topic `orders_avro` using http://localhost:9000/topic/create with 10 partitions
2. Run the service & consumer `make run`
3. Hit `http://localhost:8090/publish/orders/insert/avro?numOfUserIDs=100000&numOfOrders=10&numOfTrades=1` to publish 1 million order into topic `orders_avro` that need to be inserted.
4. The consumer will consume it, and use the `COPY` query to insert into db.
5. You can check the CDC here http://localhost:9000/topic/postgres.public.orders

# Create Schema on schema-registry
- Create Schema `curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema":"{\"type\":\"record\",\"name\":\"trade\",\"fields\":[{\"name\":\"order_id\",\"type\":\"long\"},{\"name\":\"lot\",\"type\":\"long\"},{\"name\":\"lot_multiplier\",\"type\":\"int\"},{\"name\":\"price\",\"type\":\"int\"},{\"name\":\"total\",\"type\":\"long\"},{\"name\":\"created_at\",\"type\":\"string\"}]}"}' http://schema-registry:8081/subjects/trades_avro-value/versions`
- Or you can publish 1 message to create a schema `kafka-avro-console-producer --broker-list redpanda2:9092 --property schema.registry.url=http://schema-registry:8081 --topic trades_avro --property value.schema='{"type":"record","name":"trade","fields":[{"name":"order_id","type":"long"},{"name":"lot","type":"long"},{"name":"lot_multiplier","type":"int"},{"name":"price","type":"int"},{"name":"total","type":"long"},{"name":"created_at","type":"string"}]}'`
- `{"order_id": 1, "lot": 10, "lot_multiplier": 100, "price": 1000, "total": 1000000, "created_at": "2021-10-19 10:23:54"}`
- Try to consume it `kafka-avro-console-consumer --bootstrap-server redpanda2:9092 --property schema.registry.url=http://schema-registry:8081 --topic trades_avro --from-beginning --max-messages 1`

# Upsert Trade

1. Create topic `trades_avro` using http://localhost:9000/topic/create with 10 partitions
2. Run the service & consumer `make run`
3. Hit `http://localhost:8090/publish/trades/insert/avro?numOfUserIDs=100000&numOfOrders=10&numOfTrades=1` to publish 1 million order into topic `trades_avro` that need to be inserted.
4. The consumer will consume it, and sequentially upsert data into db.
