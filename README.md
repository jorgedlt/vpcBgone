##### vpcBgone README.md file
### AWS CLI Creates VPC inventory and Optionally DELETES all of it
09 JULY 2017 - Based on [Private Notes](https://docs.google.com/document/d/1Q8ieik-aJk8XjOsY0FIblK31kbcligHnIggdvnSeqss)

# How to delete a VPC with --all-dependencies                         

#### Really Good cli article - [Link](https://github.com/miztiik/AWS-Demos)

#### A similar approach using HashiCorp'sTeraForm - [Link](https://linuxacademy.com/howtoguides/posts/show/topic/13922-a-complete-aws-environment-with-terraform)

#### How to Destroy (Tear Down) an AWS EC2 Environment - [Link](https://www.build-business-websites.co.uk/assets/it.assets/infrastructure.assets/ec2.assets/ec2.environment.destroy.howto.html)

The issue is AWS vps's can not be deleted if dependencies are there, this is true of heavy AWS link EC2, RDS, LAMDBA's etc, or anything which has an ENI. However, this is where several post around the web gets it wrong, as simply deleted all of the ENI will NOT allow one to then delete the VPC directly as it still has many dependencies. Here in my project's I've list the most common in my cases. However there are more (which I will need to add later, like egress-only-gateway, etc.)

After much trial and effort, I settled on the following sequance, although it is not an officla AWS sequence, I know it to works. Here is the catch; many of the depencies CAN NOT, if the are DEFAULT, be deleted. Not from the CLI, and not from the WEBGUI (unless the delete all depencies check-box is checked). This seems to cause much confussion, not only to me, but others as well. Now once all of the detelateable items have been delete, then the VPC can be deleted, and it will delete all of the undeletable default items with it. Leaving one with a clean AWS once again.

Also, at the time of the this being (aws --version aws-cli/1.11.117 Python/2.7.10 Darwin/16.6.0 botocore/1.5.80 09JULY2017) there is no single global AWSCLI equvialnce to vpcshowall or vpczorchall.

I wrote this my use, and is a work in progress. /Jorge

## 1. Kill EC2 (and RDS ...) 
… use ec2kill for now

## 2. Get Security Groups -- move this to the bottom later

#### sgls
    Security Group: [ sg-6fc4d206 ] SG Name: [ defaultVPCsecuritygroup ]
    TAG: [ default ] VPC: [ vpc-61334e08 ]

    Security Group: [ sg-aa7c8ac3 ] SG Name: [ defaultVPCsecuritygroup ]
    TAG: [ default ] VPC: [ vpc-b28069db ]

    Security Group: [ sg-d1d9cfb8 ] SG Name: [ SecurityGroupforSSHAccess ]
    TAG: [ SSH-vpc08-rds01 ] VPC: [ vpc-61334e08 ]

example here

 	aws ec2 delete-security-group --group-id sg-551f0f3c

 	aws ec2 delete-security-group --group-id sg-6fc4d206 
 
 #### the other default sg need not be deleted by hand, the default sg will be purged by the removal of the vpc later...
 
----
additional steps not needed, but ducumented all the same.

#### aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-b57a8bd3 | grep GroupId | tr -d ' |,|"' | sort | uniq | cut -d':' -f2

aws ec2 revoke-security-group-ingress --group-id sg-6fc4d206 \   # not is needed 
 --protocol all --port -1 --cidr 0.0.0.0/0

aws ec2 revoke-security-group-egress --group-id sg-6fc4d206 \
 --protocol all --port -1 --cidr 0.0.0.0/0

## 3. Get Subnets
#### aws ec2 describe-subnets --filters Name=vpc-id,Values <VPC-ID>

aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-b57a8bd3 | grep SubnetId

            "SubnetId": "subnet-c0ae8b89",
            "SubnetId": "subnet-02ac894b",

    aws ec2 delete-subnet --subnet-id subnet-fc32efb1
    aws ec2 delete-subnet --subnet-id subnet-942df0d9

## 4. Get ACLs
#### aws ec2 describe-network-acls --filters Name=vpc-id,Values=<vpc-id>   

aws ec2 describe-network-acls --filters Name=vpc-id,Values=vpc-fd3b4794 | grep NetworkAclId \
| tr -d ' |,|"' | sort | uniq | cut -d':' -f2 

	aws ec2 delete-network-acl --network-acl-id acl-f615a990 # cannot delete IF default

## 5. Get Internet GW
#### aws ec2 describe-internet-gateways --filters Name=vpc-id,Values=<vpc-id>
 
     aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=vpc-fd3b4794 | grep InternetGatewayId

     aws ec2 detach-internet-gateway --internet-gateway-id=igw-a1860cc8 --vpc-id=vpc-fd3b4794

     aws ec2 delete-internet-gateway --internet-gateway-id=igw-424bc02b  # delte is not need for VPC removal

## 6. Get Route Table 
#### aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-id>

aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-fd3b4794 | grep RouteTableId | tr -d ' |,|"' | sort | uniq | cut -d':' -f2

	aws ec2 delete-route-table --route-table-id rtb-949dd3fd
	
	   
## 7. Addtional Resources and Notes
#### aws ec2 delete-vpc --vpc-id=<vpc-id>

	aws ec2 delete-vpc --vpc-id vpc-fd3b4794

----

## Adtional Resources and Notes
#### Reading AWS Security Groups

It pays to read the security group before you delete the security group so that you know what you have. Use the below command.

	aws ec2 describe-security-groups --group-ids sg-73a99115

You can use --group-names to provide a list of names if you prefer.
The below security group cannot be deleted because it still has a default outbound access all areas rule ingress (egress) rule attached to it.

	{
	  "SecurityGroups":
	  [
	    {
	      "IpPermissions": [],
	      "Description": "The firewall host/port accessibility rules on sandbox.7044.1142.aan@sre.biz.com",
	      "VpcId": "vpc-07566463",
	      "OwnerId": "355368310840",
	      "IpPermissionsEgress":
	      [
	        {
	          "PrefixListIds": [],
	          "IpProtocol": "-1",
	          "UserIdGroupPairs": [],
	          "IpRanges":
	          [
	            {
	              "CidrIp": "0.0.0.0/0"
	            }
	          ]
	        }
	      ],
	      "GroupId": "sg-73a99115",
	      "GroupName": "group.sandbox.7044.1142.aan@sre.biz"
	    }
	  ]
	}
	 
The below security can now be deleted. It does not have any ingress rules attached to it.
	
	aws ec2 describe-security-groups --group-ids sg-73a99115
	{
	  "SecurityGroups": [
	    {
	      "IpPermissions": [],
	      "Description": "The firewall host/port accessibility rules on sandbox.7044.1142.aan@sre.biz.com",
	      "IpPermissionsEgress": [],
	      "GroupId": "sg-73a99115",
	      "VpcId": "vpc-07566463",
	      "OwnerId": "355368310840",
	      "GroupName": "group.sandbox.7044.1142.aan@sre.biz.com"
	    }
	  ]
	}

----

## Creating a Default VPC

If you delete your default VPC, you can create a new one. You cannot restore a previous default VPC that you deleted, and you cannot mark an existing nondefault VPC as a default VPC. If your account supports EC2-Classic, you cannot use these procedures to create a default VPC in a region that supports EC2-Classic.

When you create a default VPC, it is created with the standard components of a default VPC, including a default subnet in each Availability Zone. You cannot specify your own components. The subnet CIDR blocks of your new default VPC may not map to the same Availability Zones as your previous default VPC. For example, if the subnet with CIDR block 172.31.0.0/20 was created in us-east-2a in your previous default VPC, it may be created in us-east-2b in your new default VPC.

If you already have a default VPC in the region, you cannot create another one.

[AWS DOCS - re-creating a default VPC](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/default-vpc.html#create-default-vpc)

### To create a default VPC using the command line

You can use the create-default-vpc AWS CLI command. This command does not have any input parameters.

	aws ec2 create-default-vpc

	{
	    "Vpc": {
	        "VpcId": "vpc-3f139646", 
	        "InstanceTenancy": "default", 
	        "Tags": [], 
	        "Ipv6CidrBlockAssociationSet": [], 
	        "State": "pending", 
	        "DhcpOptionsId": "dopt-61079b07", 
	        "CidrBlock": "172.31.0.0/16", 
	        "IsDefault": true
	    }
	}
