docker container for python flask slideshow
elastic beanstalk auto-scales this container

docker-amazon: official amazon eb python container running ubuntu
docker-centos: official centos 6.5 latest

```
==> docker build -t [container-name] . && docker run -d -p 8011:8011 [container-name]
```

notes:

- docker on linux requires "docker" group membership for user
- docker on osx requires boot2docker and helper script for port redirection
