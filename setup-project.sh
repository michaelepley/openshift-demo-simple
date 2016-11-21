# Configuration

. ./config.sh

echo "Setup sample PHP + MySQL demo application: connect frontend and backend"
. ./setup-login.sh

echo "	--> getting limits"
oc get limitranges/limits -o json

echo "	--> setting custom quotas"
oc patch  resourcequotas/quota  -p '{"spec" : { "limits" : { "hard" : [ { "cpu" : "2", "memory" : "3Gi", "pods" : "10", "resourcequotas" : "1", "services" : "10" } ] } } }' 
echo "	--> setting custom limits"
oc patch  limitranges/limits -p '{ "spec": {
        "limits": [
            {   "type": "Pod",
                "max": { "cpu": "1", "memory": "2Gi" },
                "min": { "cpu": "100m", "memory": "6Mi" } },
            {   "type": "Container",
                "max": { "cpu": "1", "memory": "2Gi" },
                "min": { "cpu": "100m", "memory": "4Mi" },
                "default": { "cpu": "500m", "memory": "512Mi" },
                "defaultRequest": { "cpu": "200m", "memory": "256Mi" },
                "maxLimitRequestRatio": { "cpu": "10" }
            }
        ]
    }
}'

echo "Done."