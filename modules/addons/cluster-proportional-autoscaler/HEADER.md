# Horizontal cluster-proportional-autoscaler

Horizontal cluster-proportional-autoscaler watches over the number of schedulable nodes and cores of the cluster and resizes the number of replicas for the required resource. This functionality may be desirable for applications that need to be autoscaled with the size of the cluster, such as DNS and other services that scale with the number of nodes/pods in the cluster.

For more details checkout [cluster-proportional-autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler) docs
