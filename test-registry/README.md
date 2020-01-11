
# Registry with tls on aws for onprem

##### Obtain sslcerts for os-registry.cf-cd.com + os-registry-pub.cf-cd.com  
for letsencypt:  
```
certbot certonly --dns-route53 -d os-registry.cf-cd.com --work-dir . --logs-dir /tmp/ --config-dir .
```
copy the certrificates to ssl/ folder

##### generate basic password  
```
htpasswd -c -B -b registry/htpasswd codefresh cf12345
```

##### Install docker
https://docs.docker.com/install/ 


on ec2-linux:  
```bash
yum update -y
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add docker repository.
amazon-linux-extras install -y docker

# Restart docker.
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user
```

##### copy files to server
copy run-registry.sh, ssl/config.yml, htpasswd to the server

##### run 
```
./run-registry.sh 
```
