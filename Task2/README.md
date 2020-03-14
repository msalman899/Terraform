**Task2**

- Create a new VPC (with internet gateway)
- Create a subnet and routing table
- Attach igw to routing table
- Attach routing table to subnet
- Create an EC2 instance in that subnet
- Create a security group and attach it to EC2 instance
  - Allow incoming traffic for port 22 and 80, any host / cidr block
  - Allow All outgoing traffic
- Tag the server
- Install and enable nginx server when instance is operational, also setup index.html page
- output server public ip / public dns

**update to infrastructure**


- Create a Loadbalancer (with own security group)
- Create another subnet
- Attach routing table to new subnets
- Create another EC2 instances in new subnet
- Add both instances to loadbalancer
- Attach security group to new EC2 instances
  - restrict security group port 80 traffic  from elb only
- Tag the new machine
- Install and enable nginx server when instance is operational, also setup index.html page
- output elb public dns name
