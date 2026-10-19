# Static Asset Delivery Platform

Global CDN for static assets: **S3 (private) + CloudFront (OAC) + AWS WAF + Route 53**, deployed with **GitHub Actions (OIDC)** and automatic cache invalidation.

```
GitHub push -> GitHub Actions (OIDC role) -> S3 (private) <- CloudFront (OAC) <- WAF <- Route 53 <- Viewer
                      \__ create-invalidation ______________/
```

## Deploy the infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```
Requires an existing Route 53 hosted zone for `root_domain`. First apply takes ~10 min (CloudFront).

## Wire up GitHub
Repo > Settings > Secrets and variables > Actions > **Variables**, add the Terraform outputs:
`AWS_ROLE_ARN`, `S3_BUCKET`, `CF_DISTRIBUTION_ID`.
Push a change under `site/` to `main`; the workflow syncs to S3 and invalidates the cache.
The workflow file lives at `.github/workflows/deploy.yml` and must be in the repo root.

## Roll out WAF safely
`waf_count_mode = true` (default) only counts matches. Review the WAF log group, then set it to `false` and apply to start blocking.

## Validate
```bash
curl -I https://assets.example.com/assets/app.js        # run twice: x-cache: Hit from cloudfront
curl -I https://<bucket>.s3.ap-south-1.amazonaws.com/index.html   # expect 403
curl -I https://assets.example.com | grep -i strict-transport      # security headers
hey -n 5000 -c 50 https://assets.example.com/           # rate limit test (after blocking enabled)
```

## Cost notes
Origin Shield, WAF (per rule + per request) and Bot Control add cost. Disable Origin Shield in `cloudfront.tf` for a cheaper setup.

## Clean up
Empty the buckets (including all versions), then `terraform destroy`.
