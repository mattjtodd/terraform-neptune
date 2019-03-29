# terraform-neptune
A very simple AWS Neptune terraform plan

## Overview

This terraform plan will create a new vpc and two subnets, each in a different avilability zone.  
In addition it will create a bastion through which you can tunnel to the vpc endpoint where the cluster presents it's service.

The outputs from the terraform template will give you a suggestion for how to do the port forwarding so it should be a case of 
just copy and paste and you'll have local access to your cluster endpoints.
