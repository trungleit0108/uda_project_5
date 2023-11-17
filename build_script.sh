### DOCKER
psql -h cdr.cnhg9lcikcvo.us-east-2.rds.amazonaws.com -U minhpham postgres


docker-compose down
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -a -q) --force
docker builder prune
docker image prune --all


source set_env.sh

DOCKER_BUILDKIT=0 docker-compose -f docker-compose-build.yaml build --parallel

docker build --no-cache ./udagram-reverseproxy -t $DOCKER_USERNAME/reverseproxy:$DOCKER_IMAGE_LATEST_VERSION
docker build --no-cache ./udagram-frontend     -t $DOCKER_USERNAME/udagram-frontend:$DOCKER_IMAGE_LATEST_VERSION
docker build --no-cache ./udagram-api-feed     -t $DOCKER_USERNAME/udagram-api-feed:$DOCKER_IMAGE_LATEST_VERSION
docker build --no-cache ./udagram-api-user     -t $DOCKER_USERNAME/udagram-api-user:$DOCKER_IMAGE_LATEST_VERSION

docker-compose up

docker push $DOCKER_USERNAME/udagram-api-feed:$DOCKER_IMAGE_LATEST_VERSION
docker push $DOCKER_USERNAME/udagram-api-user:$DOCKER_IMAGE_LATEST_VERSION
docker push $DOCKER_USERNAME/udagram-frontend:$DOCKER_IMAGE_LATEST_VERSION
docker push $DOCKER_USERNAME/reverseproxy:$DOCKER_IMAGE_LATEST_VERSION



### EKSCTL
eksctl create cluster --name minhpham-01 --region=us-east-2 --nodes-min=2 --nodes-max=3 --spot --instance-types=t3.small
kubectl get nodes


kubectl delete pod backend-user-5669fffdc4-mmslp
kubectl delete pod backend-user-5669fffdc4-rzmc2
kubectl delete pod backend-user-5669fffdc4-zgk47
## Deployment
cat ~/.aws/credentials | tail -n 5 | head -n 2 | base64

## Apply env variables and secrets
kubectl apply -f aws-secret.yaml 
kubectl apply -f env-secret.yaml
kubectl apply -f env-configmap.yaml

## Deployments - Double check the Dockerhub image name and version in the deployment files
kubectl apply -f udagram-api-feed/backend-feed-deployment.yaml
kubectl apply -f udagram-api-user/backend-user-deployment.yaml
kubectl apply -f udagram-reverseproxy/reverseproxy-deployment.yaml
kubectl apply -f udagram-frontend/frontend-deployment.yaml

## Service
kubectl apply -f udagram-api-feed/backend-feed-service.yaml
kubectl apply -f udagram-api-user/backend-user-service.yaml
kubectl apply -f udagram-frontend/frontend-service.yaml
kubectl apply -f udagram-reverseproxy/reverseproxy-service.yaml


Expose External IP
## Check the deployment names and their pod status
kubectl get deployments

## Create a Service object that exposes the frontend deployment
## The command below will ceates an external load balancer and assigns a fixed, external IP to the Service.
kubectl expose deployment frontend --type=LoadBalancer --name=publicfrontend
kubectl expose deployment reverseproxy --type=LoadBalancer --name=publicreverseproxy

## Check name, ClusterIP, and External IP of all deployments
kubectl get deployments
kubectl get services 
kubectl get pods # It should show the STATUS as Running
kubectl set image deployment frontend frontend=$DOCKER_USERNAME/udagram-frontend:v28

kubectl autoscale deployment backend-user --cpu-percent=70 --min=2 --max=3
kubectl autoscale deployment backend-feed --cpu-percent=70 --min=2 --max=3