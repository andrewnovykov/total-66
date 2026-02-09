# Technical Integrations Specification

> Technical configuration for integrations. Business requirements live in `integrations.md`.

## Integration Overview

| Service          | SDK / Package                 | Version | Env Vars Required                      | Status |
| ---------------- | ----------------------------- | ------- | -------------------------------------- | ------ |
| File Storage     | S3-compatible (AWS SDK) | TBD     | `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | MVP (required) |
| Email Service    | Provider SDK (TBD)            | TBD     | `EMAIL_PROVIDER_API_KEY`, `EMAIL_FROM` | Future (Phase 2) |

---

## Per-Integration Configuration

### File Storage (Images)

```yaml
service: file_storage
provider: s3-compatible
sdk: TBD
env_vars:
  - S3_BUCKET
  - S3_REGION
  - S3_ACCESS_KEY_ID
  - S3_SECRET_ACCESS_KEY

upload_config:
  use_cases:
    - goal images
    - user avatars
    - challenge images (optional)
  max_file_size_mb: 10
  allowed_mime_types:
    - image/jpeg
    - image/png
    - image/webp
  path_pattern: "uploads/{user_id}/{timestamp}-{filename}"
  presigned_url_expiry_seconds: 3600
```

### Email Service (Optional in MVP, recommended Phase 2)

```yaml
service: email
provider: TBD
sdk: TBD
env_vars:
  - EMAIL_PROVIDER_API_KEY
  - EMAIL_FROM

templates:
  - name: verification
    variables: [verify_url, user_name]
  - name: password_reset
    variables: [reset_url, expires_in]
  - name: notification
    variables: [actor_name, target_title, action_url]

retry_strategy:
  max_retries: 2
  backoff: linear
  initial_delay_ms: 2000
```

---

## Abstraction Layer Design

All third-party integrations should be wrapped in a small adapter module per service so providers can be swapped later without touching business logic.

---

## Health Check Endpoints

| Integration    | Health Check Endpoint   | Check Method          |
| -------------- | ----------------------- | --------------------- |
| File Storage   | `/health/storage`       | Credential check / list bucket |
| Email Service  | `/health/email`         | Provider ping (when enabled) |

**Aggregate health endpoint:** `GET /health`
