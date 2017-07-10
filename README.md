##### vpcBgone README.md file
### AWS CLI Creates VPC inventory and Optionally DELETES all of it
09 JULY 2017 - Based on [Private Notes](https://docs.google.com/document/d/1Q8ieik-aJk8XjOsY0FIblK31kbcligHnIggdvnSeqss)

# How to delete a VPC with --all-dependencies                         

#### Really Good cli article - [Link](https://github.com/miztiik/AWS-Demos)

#### A similar approach using HashiCorp'sTeraForm - [Link](https://linuxacademy.com/howtoguides/posts/show/topic/13922-a-complete-aws-environment-with-terraform
)

#### How to Destroy (Tear Down) an AWS EC2 Environment - [Link](https://www.build-business-websites.co.uk/assets/it.assets/infrastructure.assets/ec2.assets/ec2.environment.destroy.howto.html)

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
