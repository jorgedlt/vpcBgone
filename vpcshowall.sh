# My Colors
   export BLACK=$(tput setaf 0)
   export RED=$(tput setaf 1)
   export GREEN=$(tput setaf 2)
   export YELLOW=$(tput setaf 3)
   export BLUE=$(tput setaf 4)
   export MAGENTA=$(tput setaf 5)
   export CYAN=$(tput setaf 6)
   export WHITE=$(tput setaf 7)
   export GRAY=$(tput setaf 8)
   export GREY=$(tput setaf 8)
   export BOLD=$(tput bold)
   export REVERSE=$(tput rev)
   export RESET=$(tput sgr0)
#

_jsonprsh ()
{
  # json parse with head
  echo "${1}" | grep -w ${2} | head -1 | cut -d':' -f2- | tr -d ' |,|"' | sort | uniq
}

_jsonprst ()
{
 # json parse with tail
  echo "${1}" | grep -w ${2} | tail -1 | cut -d':' -f2- | tr -d ' |,|"' | sort | uniq
}

_jsonprsr ()
{
 # json parse with raw queue
  echo "${1}" | grep -w ${2} | cut -d':' -f2- | tr -d ' |,|"' | tr '\012' ','
}

descDUMP ()
{
  echo "    ${GRAY}$1: [ ${YELLOW}$2 ${GRAY}]"
}

vpczorch ()
{
    if (( $# < 1 )); then
        echo usage: Needs at least one argument {VPC ID#};
        return;
    fi;
}

vpcID=$1
        # VPC
        descDUMP 'VPC ID' $vpcID;
        echo

        # subnet[s]
        NETlist=$( aws ec2 describe-subnets --filters Name=vpc-id,Values="${vpcID}" );
        _NETlist=$( _jsonprsr "$NETlist" SubnetId );
        descDUMP 'Subnets ID' $_NETlist;

        # aws ec2 delete-security-group --group-id sg-551f0f3c

        # security group[s]
        SGlist=$( aws ec2 describe-security-groups --filters Name=vpc-id,Values="${vpcID}" );
        _SGlist=$( _jsonprsr "$SGlist" GroupId );
        descDUMP 'Security Groups' $_SGlist;

        # aws ec2 delete-subnet --subnet-id subnet-fc32efb1

        # ACL[s]
        ACLlist=$( aws ec2 describe-network-acls --filters Name=vpc-id,Values="${vpcID}" );
        _ACLlist=$( _jsonprsh "$ACLlist" NetworkAclId );
        descDUMP 'Access Control List' $_ACLlist;

        # aws ec2 delete-network-acl --network-acl-id acl-f615a990 # cannot delete IF default

        # InternetGateway
        IGWid=$( aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcID");
        _iGWid=$( _jsonprsh "$IGWid" InternetGatewayId );
        descDUMP 'Internet Gateway ID' $_iGWid;

        #  aws ec2 detach-internet-gateway --internet-gateway-id=igw-a1860cc8 --vpc-id=vpc-fd3b4794
        # aws ec2 delete-internet-gateway --internet-gateway-id=igw-424bc02b  # delte is not need for VPC removal

        # RouteTable
        RTABid=$( aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcID" --query 'RouteTables[?Associations[0].Main != `true`]' );
        _RTBid=$( _jsonprst "$RTABid" RouteTableId );
        descDUMP 'Route Tables ID' $_RTBid;

        # ec2kill - aws ec2 terminate-instances --instance-ids "$@"

        # EC2[s]
        EC2list=$( aws ec2 describe-instances --filters Name=vpc-id,Values="${vpcID}" );
        _EC2list=$( _jsonprsr "$EC2list" InstanceId );
        descDUMP 'EC2 instances' $_EC2list;

        echo
        aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,VpcId,InstanceType,PrivateIpAddress,PublicIpAddress,Tags[?Key==`Name`].Value[]]' \
        --output json | tr -d '\n[] "' | perl -pe 's/i-/\ni-/g' | tr ',' '\t' | sed -e 's/null/None/g' \
        | grep '^i-' | column -t | ccze -A | grep "${vpcID}"
        echo

        # RDS[s]
        # RDSlist=$( aws rds describe-db-instances --filters Name=VpcId,Values="${vpcID}" );
        # _RDSlist=$( _jsonprsr "$RDSlist" InstanceId );
        # descDUMP 'RDS instances' $_RDSlist;

        echo; echo ${MAGENTA} NOTE: rds, lambda, apigw, dynomodb currently not supported by this command. ${RESET}


        # zorch vpc - aws ec2 delete-vpc --vpc-id vpc-fd3b4794
