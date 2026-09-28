# AWS deployment

This application is packaged as one immutable PHP 8.3/Apache image (`../../Dockerfile` from this directory). The image is suitable for **Amazon ECS on Fargate** or **AWS App Runner**. Run the web process from the default image command and run the same image with `php artisan queue:work` for a worker service.

## Recommended production services

- ECS/Fargate or App Runner for the web container.
- Amazon RDS for MySQL 8.
- ElastiCache for Redis (sessions, cache, and queues if desired).
- S3 for `FILESYSTEM_DISK=s3` and generated/user files.
- SQS for `QUEUE_CONNECTION=sqs`.
- Secrets Manager or SSM Parameter Store for `APP_KEY`, database credentials, and seeded-account secrets.
- CloudWatch Logs for container stdout/stderr.

The web service should listen on container port 80. Set `RUN_MIGRATIONS=true` only for a one-shot release/migration task, not on every web replica. Set `RUN_OPTIMIZE=true` on the release task after the environment variables and `APP_KEY` are present.

## Local AWS integration with Floci

Floci is an AWS-compatible emulator on port 4566. The compose file starts Floci, MySQL, Redis, creates the S3 bucket and SQS queue, then starts the Laravel web and queue containers:

```bash
cp .env.floci.example .env.floci
# Set APP_KEY in .env.floci; this command writes only to your ignored local env file.
docker compose -f docker-compose.floci.yml up --build
```

Open <http://localhost:8080>. To stop while retaining emulator and database state:

```bash
docker compose -f docker-compose.floci.yml down
```

The Floci state is stored under `storage/floci/`, which is ignored by git. The local configuration intentionally uses dummy credentials (`test`) and path-style S3 URLs; use IAM task roles and virtual-hosted S3 URLs in AWS instead.

## AWS environment variables

At minimum, set these in the task/service secret configuration:

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-hostname.example
APP_KEY=base64:...
DB_CONNECTION=mysql
DB_HOST=your-rds-endpoint
DB_DATABASE=blueprint_hr
DB_USERNAME=...
DB_PASSWORD=...
SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=sqs
FILESYSTEM_DISK=s3
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-production-bucket
SQS_PREFIX=https://sqs.us-east-1.amazonaws.com/your-account-id
SQS_QUEUE=blueprint-hr
SANCTUM_STATEFUL_DOMAINS=your-hostname.example
SESSION_SECURE_COOKIE=true
```

Do not set `AWS_ENDPOINT` or `AWS_USE_PATH_STYLE_ENDPOINT=true` in AWS unless you are intentionally using a compatible private endpoint. The Laravel S3 and SQS clients use the task role credentials automatically when explicit access-key variables are absent.

## Release checklist

1. Build and scan the image, then push it to ECR.
2. Run a one-shot migration task with `RUN_MIGRATIONS=true` and `RUN_OPTIMIZE=true`.
3. Deploy the web service and a separate queue worker service from the same image.
4. Configure an EventBridge scheduled task for `php artisan schedule:run` every minute if scheduled jobs are added.
5. Ensure the task security group can reach RDS, ElastiCache, S3, and SQS through the configured VPC endpoints/NAT path.
6. Put TLS, request-size limits, health checks, and access logging at the ALB/App Runner boundary.
7. Back up RDS and enable S3 versioning/lifecycle policies for production files.
