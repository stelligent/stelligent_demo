#!/bin/bash

vagrant up docker --provider=docker
vagrant up mysql --provider=virtualbox
vagrant up codedeploy --provider=virtualbox
vagrant up jenkins --provider=virtualbox
