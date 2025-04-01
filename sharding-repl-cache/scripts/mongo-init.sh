#!/bin/bash

###
# Инициализируем бд
###

docker compose exec -T configSrv mongosh  --port 27020 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27020" }
    ]
  }
)
EOF

docker compose exec -T shard1_a mongosh --port 27016 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_a:27016" },
        { _id : 1, host : "shard1_b:27018" },
        { _id : 2, host : "shard1_c:27019" }
      ]
    }
)
EOF

docker compose exec -T shard2_a mongosh --port 27026 <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2_a:27026" },
        { _id : 1, host : "shard2_b:27028" },
        { _id : 2, host : "shard2_c:27029" }
      ]
    }
)
EOF

docker compose exec -T mongos_router mongosh --port 27017 <<EOF
sh.addShard( "shard1/shard1_a:27016")
sh.addShard( "shard2/shard2_a:27026")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
db.helloDoc.countDocuments()
EOF

