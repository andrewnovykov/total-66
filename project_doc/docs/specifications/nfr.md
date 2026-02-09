# Non-Functional Requirements (NFR)

## Performance Targets

| Metric              | Target             | Measurement Tool       |
| ------------------- | ------------------ | ---------------------- |
| API response (p95)  | < 200ms            | k6 / Phoenix telemetry |
| API response (p99)  | < 500ms            | k6 / Phoenix telemetry |
| Page load (LCP)     | < 2.5s             | Lighthouse             |
| Time to interactive  | < 3.5s            | Lighthouse             |
| First Contentful Paint | < 1.8s          | Lighthouse             |
| Cumulative Layout Shift | < 0.1          | Lighthouse             |
| JS bundle size (gzipped) | < 200KB      | Build output            |

## Scalability

| Metric                 | Target                   |
| ---------------------- | ------------------------ |
| Concurrent users       | 1,000                    |
| Requests per second    | 500 RPS                  |
| Database connections   | pool of 20               |
| Horizontal scaling     | Stateless app instances behind a load balancer |
| Max data volume        | 1M records in primary tables (goals/posts/activities) |

---

## Security Checklist

### OWASP Top 10

| Risk                          | Mitigation                                     |
| ----------------------------- | ---------------------------------------------- |
| Injection (SQL, NoSQL, OS)    | Parameterized queries via Ecto, input validation |
| Broken authentication         | Session tokens with Bcrypt; see `auth-strategy.md` |
| Sensitive data exposure       | HTTPS everywhere, encrypt at rest, no secrets in code |
| XML external entities         | Not applicable (no XML parsing)                |
| Broken access control         | Ownership checks in contexts + LiveView guards |
| Security misconfiguration     | Secure headers, remove defaults                |
| XSS                           | Phoenix auto-escaping, CSP header              |
| Insecure deserialization      | Changeset validation on all inputs             |
| Using components with known vulns | Dependency scanning in CI                   |
| Insufficient logging          | Audit logging for auth/admin actions           |

### Security Headers

```
Content-Security-Policy: default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'
Strict-Transport-Security: max-age=63072000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), camera=(), microphone=()
```

### CORS Configuration

| Setting           | Value                        |
| ----------------- | ---------------------------- |
| Allowed origins   | APP_URL only                 |
| Allowed methods   | GET, POST, PATCH, DELETE     |
| Allowed headers   | Content-Type, Authorization  |
| Credentials       | true                         |

### Input Validation

- All user input validated via Ecto changesets at the boundary
- File uploads: max size 10 MB, allowed types: jpg/png/webp
- Rate limiting on auth endpoints (see `api-design.md`)

---

## Accessibility

| Requirement              | Target                        |
| ------------------------ | ----------------------------- |
| WCAG conformance level   | 2.1 AA                       |
| Keyboard navigation      | All interactive elements reachable |
| Screen reader support    | ARIA labels, semantic HTML  |
| Color contrast ratio     | 4.5:1 minimum                |
| Focus indicators         | Visible focus ring on all interactive elements |
| Skip navigation link     | yes                          |
| Form error announcements | aria-live regions           |

---

## Browser & Device Support

| Browser          | Minimum Version   | Priority   |
| ---------------- | ----------------- | ---------- |
| Chrome           | last 2 versions   | Primary    |
| Firefox          | last 2 versions   | Primary    |
| Safari           | last 2 versions   | Primary    |
| Edge             | last 2 versions   | Primary    |
| Mobile Safari    | iOS 16+           | Primary    |
| Chrome Android   | last 2 versions   | Primary    |

| Device           | Support Level     |
| ---------------- | ----------------- |
| Desktop (1024px+) | Full             |
| Tablet (768px+)   | Full             |
| Mobile (320px+)   | Full / Responsive |

---

## Internationalization (i18n)

| Setting              | Value                         |
| -------------------- | ----------------------------- |
| Default locale       | en-US                         |
| Supported locales    | en-US (MVP only)              |
| i18n library         | Gettext                        |
| RTL support          | no                            |
| Date/number format   | locale-aware                  |
| Translation strategy | PO files; no CMS for MVP      |

---

## Compliance

| Regulation | Applicable? | Key Requirements                      |
| ---------- | ----------- | ------------------------------------- |
| GDPR       | yes (future) | Privacy policy, data export/deletion, consent where required |
| SOC 2      | no          | —                                     |
| HIPAA      | no          | —                                     |
| PCI DSS    | no          | — (no card storage; payments not in MVP) |
| CCPA       | yes (future) | Privacy disclosures, opt-out          |

---

## Uptime & Availability

| Metric        | Target              |
| ------------- | ------------------- |
| Uptime SLA    | 99.9%               |
| Maintenance window | Sundays 02:00-04:00 UTC |
| Status page   | Not applicable (MVP) |
