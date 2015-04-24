build development enviroment

```
==> vagrant up
```




launches four VMs:

- jenkins box (virtualbox) :: tcp/8010
- codedeploy php environment (virtualbox) :: tcp/8011
- python flask environment (docker) :: tcp/8012
- mysql database (virtualbox) :: tcp/8013


requires:


- Vagrant 1.7.2
- https://github.com/adrienthebo/vagrant-hosts

