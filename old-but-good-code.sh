#

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

_jsonselect ()
{
  echo "${1}" | grep -w ${2} | head -1 | cut -d':' -f2- | tr -d ' |,|"'
}

_jsonparse ()
{
  echo "${1}" | grep -w ${2} | cut -d':' -f2- | tr -d ' |,|"'
}

prettyp ()
{
  echo "    ${GRAY}$1: [ ${YELLOW}$2 ${GRAY}]"
}

deletep ()
{
  echo "    ${GRAY}$1: [ ${RED}$2 ${GRAY}]"
}

vpcview ()
{
    if (( $# < 1 )); then
        echo usage: Needs at least one argument {VPC ID#};
        return;
    fi;

    vpcID=$1
#
    prettyp 'VPC ID' $vpcID;
    #
    IGWid=$( aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcID" );
        _iGWid=$( _jsonselect "$IGWid" InternetGatewayId );
        prettyp 'Internet Gateway ID' $_iGWid;
    #
    RTABid=$( aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcID" );
        _RTBid=$( _jsonselect "$RTABid" RouteTableId );
        prettyp 'Route Tables ID' $_RTBid;
    #
    SUBNid=$( aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcID" );
        _SUBNid=$( _jsonparse "$SUBNid" subnet );

       for i in $_SUBNid; do
         prettyp 'SubNet ID' $i;
       done
    # regretably I could not use fancy query for not-default SGid
    SGid=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcID \
           --output text | grep SECURITYGROUPS | grep -vw default \
           | tr '\t' '\012' | grep 'sg-')
     prettyp 'Security GRoup' $SGid;
}

vpckill ()
{
    if (( $# < 1 )); then
        echo usage: Needs at least one argument {VPC ID#};
        return;
    fi;

    vpcID=$1
#
    deletep 'VPC ID' $vpcID;
    #
    #
    SUBNid=$( aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcID" );
        _SUBNid=$( _jsonparse "$SUBNid" subnet );

       for i in $_SUBNid; do
         deletep 'SubNet ID' $i;
         aws ec2 delete-subnet --subnet-id "$i"
       done
    #
    IGWid=$( aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcID" );
        _iGWid=$( _jsonselect "$IGWid" InternetGatewayId );
        deletep 'Internet Gateway ID' $_iGWid;
        aws ec2 detach-internet-gateway --internet-gateway-id="$_iGWid" --vpc-id="$vpcID"
    #
    RTABid=$( aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcID" );
        _RTBid=$( _jsonselect "$RTABid" RouteTableId );
        deletep 'Route Tables ID' $_RTBid;
        aws ec2 delete-route-table --route-table-id "$_RTBid"

    # regretably I could not use fancy query for not-default SGid
    SGid=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcID \
           --output text | grep SECURITYGROUPS | grep -vw default \
           | tr '\t' '\012' | grep 'sg-')
     deletep 'Security GRoup' $SGid;
     aws ec2 delete-security-group --group-id "$SGid"

     #
     aws ec2 delete-vpc --vpc-id "$vpcID"
}

vpcrest ()
{

cd $HOME/code/vpc2ec2

rm *.json
chmod 666 *.pem
rm *.pem

#
 _keys=$(aws ec2 describe-key-pairs | grep KeyName \
  | cut -d':' -f2 | tr -d '"|:| |,')

 echo "deleting ..."
 for key in $_keys; do
     echo "${key}"
     aws ec2 delete-key-pair --key-name "${key}"
 done

#
 aws ec2 describe-key-pairs | jq .
#

cd $HOME/code/vpcBgone

}

# echo source ./vpcshow.sh; _vpcview XXXXXXXXX
# echo source ./vpcshow.sh; vpckill XXXXXXXXX
# echo source ./vpcshow.sh; vpcrest
