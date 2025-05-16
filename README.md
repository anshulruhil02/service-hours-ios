***Architecture Decision Log***

**Related Feature/Area:** Service Hours Application Backend Deployment

**Decision/Tradeoff:**

**Options Considered:**
    1. Deploying backend directly on EC2 instances
    2. Using AWS Elastic Beanstalk for simplified deployment
    3. Using containerization with ECS/Fargate for scalability and isolation
    4. Serverless approach with AWS Lambda and API Gateway
- **Selected Option:** Containerization with AWS ECS Fargate
- **Rationale:** Chose containerization with ECS Fargate for its balance of control, scalability, and reduced operational overhead. This approach allows containerized deployment without managing the underlying server infrastructure.

**Pros of Chosen Option:**

- No EC2 instance management required (serverless containers)
- Simplified scaling and management compared to direct EC2 deployment
- Better isolation and consistency across environments through Docker containers
- Direct integration with other AWS services (RDS, ECR, etc.)
- Improved resource utilization compared to dedicated EC2 instances

**Cons of Chosen Option:**

- Higher complexity than Elastic Beanstalk for initial setup
- More expensive than EC2 for constant workloads
- Cold starts possible for infrequently accessed applications
- Docker knowledge required for maintenance and updates

**Deferred Risks or Future Tasks:**

- Security groups currently allow open access to port 3000 - needs IP restrictions for production
- Using hardcoded database credentials in task definitions - should use AWS Secrets Manager
- No HTTPS/TLS implemented - required for production
- No CI/CD pipeline - manual deployment process is error-prone
- Running directly on port 3000 - should use Application Load Balancer with proper port mapping
- Default VPC and networking - needs proper network design for production
- No proper logging or monitoring strategy implemented
- Single container instance without auto-scaling
- No domain name configured - using direct IP address
