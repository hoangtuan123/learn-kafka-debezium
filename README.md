# Example CDC (PostgreSQL and Debezium)
## Setup
- docker
- docker-compose

## Required
- Postgres:
  - wal_level=logical
  - create publication and use it in kafka connect
- Kafka connect
  - connector have permission in Postgres
  - connector use publication created before

## Run
### Init system
```bash
docker-compose up
```
### Create DB
```sql
create database sourcea;
create database desb;
```
### Create tables on database by
Create souce tables
```bash
create-source-db.sql
```
Create des tables
```bash
create-des-db.sql
```
### Create connector
*Use API of Kafka Connect*

Required:
- source connector: as publisher catch `change stream` and send to `topic`
- sink connector: take data from topic and `insert/update/delete` to `table` des

**Create source connector**
```bash
curl --location 'http://localhost:8083/connectors' \
--header 'Content-Type: application/json' \
--data '{
    "name": "test1-connector",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.hostname": "postgres",
        "database.port": "5432",
        "database.user": "dbzuser",
        "database.password": "dbzpass",
        "database.dbname": "sourcea",
        "database.server.name": "sourcea",
        "table.include.list": "public.*",
        "schema.include.list": "public",
        "slot.name": "kafkaconnectpublication",
        "plugin.name": "pgoutput",
        "snapshot.mode": "initial",
        "topic.prefix": "dbz.kafka",
        "transforms": "route",
        "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
        "transforms.route.regex": "([^.]+).([^.]+).([^.]+)",
        "transforms.route.replacement": "$3",
        "key.converter": "io.apicurio.registry.utils.converter.AvroConverter",
        "key.converter.apicurio.registry.url": "http://apicurio:8080/apis/registry/v2",
        "key.converter.apicurio.registry.auto-register": "true",
        "key.converter.apicurio.registry.find-latest": "true",
          "value.converter": "io.apicurio.registry.utils.converter.AvroConverter",
        "value.converter.apicurio.registry.url": "http://apicurio:8080/apis/registry/v2",
        "value.converter.apicurio.registry.auto-register": "true",
        "value.converter.apicurio.registry.find-latest": "true"
    }
}'
```
**Create sink connector**
```bash
curl --location 'http://localhost:8083/connectors' \
--header 'Content-Type: application/json' \
--data '{
    "name": "test1-sink-connector",
    "config": {
        "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
        "tasks.max": "1",
        "connection.url": "jdbc:postgresql://postgres:5432/desb",
        "connection.username": "dbzuser",
        "connection.password": "dbzpass",
        "insert.mode": "upsert",
        "delete.enabled": "true",
        "primary.key.mode": "record_key",
        "schema.evolution": "basic",
        "database.time_zone": "UTC",
        "topics": "dbz.kafka.public.test1",
        "table.name.format": "test1",
        "pk.fields": "id",
        "transforms": "unwrap",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "auto.create": "true",

          "key.converter": "io.apicurio.registry.utils.converter.AvroConverter",
        "key.converter.apicurio.registry.url": "http://apicurio:8080/apis/registry/v2",
          "value.converter": "io.apicurio.registry.utils.converter.AvroConverter",
        "value.converter.apicurio.registry.url": "http://apicurio:8080/apis/registry/v2"
    }
}'
```
## Testing
With connector setup
```bash
 "snapshot.mode": "initial",
```
The CDC will run snapshot and publish all records in source db and send to topics as config in source connector
We also can test by insert a new records to source db:
```sql
insert into test1 values ('1', 'test for 1');
```
and test on des db:
```sql
select * from test1;
```
