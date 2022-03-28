# Reference
- https://www.youtube.com/watch?v=YZRHqRznO-o&ab_channel=CodewithIrtiza
- https://github.com/irtiza07/postgres_debezium_cdc
- https://redpanda.com/blog/redpanda-debezium/

- https://github.com/paul-ylz-tw/debetime_example/blob/main/Dockerfile
- https://hub.docker.com/r/polokuro/timescaledb-debezium

# Order Table
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

# Upsert Trade

1. Create topic `trades_avro` using http://localhost:9000/topic/create with 10 partitions
2. Run the service & consumer `make run`
3. Hit `http://localhost:8090/publish/trades/insert/avro?numOfUserIDs=100000&numOfOrders=10&numOfTrades=1` to publish 1 million order into topic `trades_avro` that need to be inserted.
4. The consumer will consume it, and sequentially upsert data into db.
