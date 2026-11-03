set dotenv-load

# teardown existing, start: minio, when ready create: nisshi and lake buckets, and then: iceberg catalog and nisshi
up: docker-compose-down minio-up minio-ready-local minio-local-alias minio-nisshi-bucket minio-lake-bucket nisshi-up

[private]
docker-compose-up *args:
    docker compose up --detach --wait {{args}}

[private]
docker-compose-down *args:
    docker compose down --volumes {{args}}

[private]
docker-compose-ps:
    docker compose ps

[private]
docker-compose-logs *args:
    docker compose logs {{args}}

[private]
minio-up: (docker-compose-up "minio")

[private]
minio-down: (docker-compose-down "minio")

[private]
docker-compose-exec service command *args:
    docker compose exec {{service}} {{command}} {{args}}

minio-mc +args: (docker-compose-exec "minio" "mc" args)

[private]
minio-local-alias: (minio-mc "alias" "set" "local" "http://localhost:9000" "minioadmin" "minioadmin")

[private]
minio-nisshi-bucket: (minio-mc "mb" "local/nisshi")

[private]
minio-lake-bucket: (minio-mc "mb" "local/lake")

[private]
minio-ready-local: (minio-mc "ready" "local")

[private]
nisshi-up: (docker-compose-up "nisshi")

[private]
nisshi-down: (docker-compose-down "nisshi")

[private]
topic-create topic *args: (docker-compose-exec "nisshi" "/nisshi" "topic" "create" topic args)

[private]
topic-delete topic: (docker-compose-exec "nisshi" "/nisshi" "topic" "delete" topic)

[private]
cat-produce topic file: (docker-compose-exec "nisshi" "/nisshi" "cat" "produce" topic file)

[private]
cat-consume topic: (docker-compose-exec "nisshi" "/nisshi" "cat" "consume" topic "--max-wait-time-ms=5000")

[private]
duckdb *sql:
    duckdb -markdown -init duckdb-init.sql :memory: {{sql}}

## Employee

# create employee topic with schema/employee.proto
employee-topic-create: (topic-create "employee" "--config" "nisshi.lake.partition=meta.year,meta.month,meta.day" "--config" "nisshi.lake.normalize=true")

# produce data/persons.json with schema/person.json
employee-produce: (cat-produce "employee" "data/employees.json")

# consume employee topic
employee-consume: (cat-consume "employee")

# employee duckdb delta lake
employee-duckdb-delta: (duckdb "\"select * from delta_scan('s3://lake/nisshi.employee');\"")


## Person

# create person topic with schema/person.json
person-topic-create: (topic-create "person" "--partitions" "1" "--config" "nisshi.lake.partition=meta.year,meta.month,meta.day" "--config" "nisshi.lake.normalize=true" "--config" "nisshi.lake.sink=true")

# produce data/persons.json with schema/person.json
person-produce: (cat-produce "person" "data/persons.json")

# person duckdb delta lake
person-duckdb-delta: (duckdb "\"select * from delta_scan('s3://lake/nisshi.person');\"")


## Search

# create search topic with schema/search.proto
search-topic-create: (topic-create "search")

# produce data/searches.json with schema/search.proto
search-produce: (cat-produce "search" "data/searches.json")

# search duckdb delta lake
search-duckdb-delta: (duckdb "\"select * from delta_scan('s3://lake/nisshi.search');\"")


## Observation

# create observation topic with schema etc/schema/observation.avsc
observation-topic-create: (topic-create "observation")

# produce data/observations.json with schema/observation.avsc
observation-produce: (cat-produce "observation" "data/observations.json")

# observation duckdb delta lake
observation-duckdb-delta: (duckdb "\"select * from delta_scan('s3://lake/nisshi.observation');\"")


## Taxi

# create taxi topic with schema etc/schema/taxi.proto
taxi-topic-create: (topic-create "taxi")

# produce data/trips.json with schema schema/taxi.proto
taxi-produce: (cat-produce "taxi" "data/trips.json")

# taxi duckdb delta lake
taxi-duckdb-delta: (duckdb "\"select * from delta_scan('s3://lake/nisshi.taxi');\"")


## Grade

# create grade topic with schema etc/schema/grades.proto
grade-topic-create: (topic-create "grade" "--config" "nisshi.lake.partition=meta_year" "--config" "nisshi.lake.normalize.separator=_" "--config" "nisshi.lake.z_order=value_grade" "--config" "nisshi.lake.normalize=true")

# produce data/grades.json with schema schema/grades.proto
grade-produce: (cat-produce "grade" "data/grades.json")

# grade duckdb delta lake
grade-duckdb-delta: (duckdb "\"select * from delta_scan('s3://lake/nisshi.grade');\"")
