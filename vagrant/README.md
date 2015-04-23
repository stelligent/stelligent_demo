build development enviroment

```
==> ./vagrant.sh
```

("vagrant up" will not work, due to multiple providers in use)



launches four VMs:

1) jenkins box (virtualbox) :: tcp/8010
2) codedeploy php environment (virtualbox) :: tcp/8011
3) python flask environment (docker) :: tcp/8012
4) mysql database (virtualbox) :: tcp/8013


requires:


1) Vagrant 1.7.2
2) https://github.com/adrienthebo/vagrant-hosts

