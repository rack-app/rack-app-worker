rack-app-worker
===============

Rack::App Worker extension so you can use scalable async message processing 


# ENV Variables

## RABBITMQ_URL
 
this is required for connecting to rabbitmq 

## WORKER_CLUSTER

this is an optional env variable, this defines the workers cluster such as 'backup' or 'secondary'. 
This is useful when you have two seperated database and you want populate both at once,
but you only want one public web api which accept the incoming content.
