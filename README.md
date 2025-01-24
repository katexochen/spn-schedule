## archive.org's "save page now" on schedule

Workflow runs daily, at 00:00 UTC.

### config entry format

```yaml
- url: https://example.com # required
  capture_outlinks: false # Capture all outlinks of 'url', too. default: true
  if_not_archived_within: 3d 5h 20m # Only save if last capture is older. default: 7d
```
