build development enviroment

```
==> ./vagrant.sh
```

("vagrant up" will not work, due to multiple providers in use)



launches four VMs:

1) codedeploy php environment (virtualbox)
2) mysql database (virtualbox)
3) jenkins box (virtualbox)
4) python flask environment (docker)


requires:


1) Vagrant 1.7.2
2) https://github.com/adrienthebo/vagrant-hosts

