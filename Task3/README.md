**Task3**

- Create a new VPC (with internet gateway)
- Create 2 subnets and routing table
- Attach igw to routing table
- Attach routing table to both subnets 

<br/><br/>
- Create an EC2 instance in each subnet
- Create a security group and attach it to both EC2 instances
  - Allow incoming traffic for port 22 and 80, any host / cidr block
  - Allow All outgoing traffic
  - restrict security group port 80 traffic from elb only
- setup provisioner
  - get web files from s3 bucket
  - push web logs to s3 bucket
  
<br/><br/>
- Create a Loadbalancer (with own security group)
- Add both instances to loadbalancer

<br/><br/>
- create s3 bucket
- both EC2 insntances should have read/write access to s3 bucket

<br/><br/>
- Tag all objects
- Install and enable nginx server when instance is operational, also setup index.html page
- output server public ip / public dns
