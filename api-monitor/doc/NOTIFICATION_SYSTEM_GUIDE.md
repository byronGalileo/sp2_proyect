# Notification System Guide

## Overview

The notification system sends **SMS alerts** when monitored services fail or restart. It supports two SMS providers: **AWS SNS** and **Twilio**.

---

## How It Works

1. **Monitor detects** a service issue (down, restarting, failed)
2. **System checks** notification config for that service
3. **Sends SMS** to configured contacts using selected provider (AWS or Twilio)
4. **Respects cooldown** - won't spam (default: 5 minutes between notifications)
5. **Logs history** - all notifications stored in MongoDB

---

## SMS Providers

### AWS SNS
- **Cost**: ~$0.00645 per SMS (Guatemala)
- **Setup**: AWS account, Access Keys
- **Best for**: High volume, integrated AWS infrastructure

### Twilio
- **Cost**: ~$0.0075 per SMS (varies by region)
- **Setup**: Twilio account, buy phone number
- **Best for**: Reliability, detailed delivery status

**You can choose different providers for different services!**

---

## Notification Events

The system sends alerts for these events:

| Event | When Triggered | Message Example |
|-------|---------------|-----------------|
| **service_down** | Service is down and cannot be restarted | `ALERT: Service 'mysql.service' on localhost is DOWN.` |
| **service_restart_attempt** | Monitor starts trying to restart | `INFO: Attempting to restart service 'mysql.service' on localhost. Attempt: 1` |
| **service_restart_failed** | Restart failed after attempts | `CRITICAL: Failed to restart service 'mysql.service' on localhost. Error: ...` |
| **service_recovered** | Service restarted successfully | `SUCCESS: Service 'mysql.service' on localhost has been recovered successfully.` |

---

## Quick Start

### 1. Configure Providers

**Edit `.env` file:**

```bash
# AWS SNS
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1

# Twilio
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+15551234567
```

### 2. Create Notification Config

```bash
curl -X POST "http://localhost:8000/notifications/configs" \
  -H "Content-Type: application/json" \
  -d '{
    "service_name": "mysql.service",
    "host": "localhost",
    "sms_provider": "twilio",
    "cooldown_minutes": 5,
    "enabled": true,
    "contacts": [
      {
        "name": "Admin",
        "phone": "+50212345678",
        "enabled": true,
        "channels": ["sms"],
        "notify_on": [
          "service_down",
          "service_restart_attempt",
          "service_restart_failed",
          "service_recovered"
        ]
      }
    ]
  }'
```

### 3. Test It

```bash
# Test Twilio
curl -X POST "http://localhost:8000/notifications/test/sms" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+50212345678",
    "message": "Test from Twilio",
    "provider": "twilio"
  }'

# Test AWS SNS
curl -X POST "http://localhost:8000/notifications/test/sms" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+50212345678",
    "message": "Test from AWS",
    "provider": "aws_sns"
  }'
```

---

## Managing Notification Configs

### View All Configs
```bash
curl http://localhost:8000/notifications/configs
```

### Get Specific Config
```bash
curl "http://localhost:8000/notifications/configs/mysql.service?host=localhost"
```

### Add Contact
```bash
curl -X POST "http://localhost:8000/notifications/configs/mysql.service/contacts?host=localhost" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "On-Call Engineer",
    "phone": "+50298765432",
    "enabled": true,
    "channels": ["sms"],
    "notify_on": ["service_restart_failed"]
  }'
```

### Remove Contact
```bash
curl -X DELETE "http://localhost:8000/notifications/configs/mysql.service/contacts/On-Call%20Engineer?host=localhost"
```

### Update Contact
```bash
curl -X PUT "http://localhost:8000/notifications/configs/mysql.service/contacts/Admin?host=localhost" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin",
    "phone": "+50212349999",
    "enabled": true,
    "channels": ["sms"],
    "notify_on": ["service_restart_failed", "service_down"]
  }'
```

### Change SMS Provider
```bash
# Switch from AWS to Twilio
curl -X PATCH "http://localhost:8000/notifications/configs/mysql.service/settings?host=localhost&sms_provider=twilio"

# Change cooldown to 10 minutes
curl -X PATCH "http://localhost:8000/notifications/configs/mysql.service/settings?host=localhost&cooldown_minutes=10"
```

### Enable/Disable Notifications
```bash
# Disable
curl -X PUT "http://localhost:8000/notifications/configs/mysql.service/status?host=localhost&enabled=false"

# Enable
curl -X PUT "http://localhost:8000/notifications/configs/mysql.service/status?host=localhost&enabled=true"
```

### Delete Config
```bash
curl -X DELETE "http://localhost:8000/notifications/configs/mysql.service?host=localhost"
```

---

## API Endpoints Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| **GET** | `/notifications/status` | Check SMS provider status |
| **POST** | `/notifications/test/sms` | Send test SMS |
| **GET** | `/notifications/configs` | List all notification configs |
| **GET** | `/notifications/configs/{service}?host=...` | Get specific config |
| **POST** | `/notifications/configs` | Create/replace config |
| **PATCH** | `/notifications/configs/{service}/settings?host=...` | Update provider/cooldown |
| **PUT** | `/notifications/configs/{service}/status?host=...` | Enable/disable |
| **POST** | `/notifications/configs/{service}/contacts?host=...` | Add contact |
| **PUT** | `/notifications/configs/{service}/contacts/{name}?host=...` | Update contact |
| **DELETE** | `/notifications/configs/{service}/contacts/{name}?host=...` | Remove contact |
| **DELETE** | `/notifications/configs/{service}?host=...` | Delete config |
| **POST** | `/notifications/send` | Manually trigger notification |
| **GET** | `/notifications/history` | View notification history |
| **GET** | `/notifications/stats` | Notification statistics |

---

## Configuration Options

### Contact Configuration

```json
{
  "name": "Admin Name",
  "phone": "+50212345678",
  "email": "admin@example.com",
  "enabled": true,
  "channels": ["sms"],
  "notify_on": [
    "service_down",
    "service_restart_attempt",
    "service_restart_failed",
    "service_recovered"
  ]
}
```

**Fields:**
- `name` - Contact identifier (must be unique per service)
- `phone` - Phone in E.164 format (+country_code + number)
- `email` - Future use for email notifications
- `enabled` - Enable/disable this contact
- `channels` - `["sms"]` (email/push coming soon)
- `notify_on` - Which events trigger notifications

### Service Configuration

```json
{
  "service_name": "mysql.service",
  "host": "localhost",
  "sms_provider": "twilio",
  "cooldown_minutes": 5,
  "enabled": true,
  "contacts": [...]
}
```

**Fields:**
- `service_name` - Systemd service name
- `host` - Host identifier
- `sms_provider` - `"aws_sns"` or `"twilio"`
- `cooldown_minutes` - Min time between notifications (1-60)
- `enabled` - Enable/disable notifications for service
- `contacts` - Array of contact objects

---

## Phone Number Format

**Always use E.164 format:**
- ✅ **Correct**: `+50212345678` (Guatemala)
- ✅ **Correct**: `+15551234567` (USA)
- ❌ **Wrong**: `12345678` (missing country code)
- ❌ **Wrong**: `502-1234-5678` (has dashes)

**Guatemala country code**: `+502`

---

## Notification History

### View Recent Notifications
```bash
curl "http://localhost:8000/notifications/history?hours=24&limit=100"
```

### Filter by Service
```bash
curl "http://localhost:8000/notifications/history?service_name=mysql.service&host=localhost"
```

### Filter by Event Type
```bash
curl "http://localhost:8000/notifications/history?event_type=service_restart_failed"
```

### Filter by Status
```bash
curl "http://localhost:8000/notifications/history?status=sent"
```

---

## Statistics

```bash
curl "http://localhost:8000/notifications/stats?hours=24"
```

**Response:**
```json
{
  "total": 15,
  "by_status": {
    "sent": 14,
    "failed": 1
  },
  "by_channel": {
    "sms": 15
  },
  "period_hours": 24
}
```

---

## Example Workflow

### Scenario: Monitor MySQL with Twilio

**1. Create config with Twilio:**
```bash
curl -X POST "http://localhost:8000/notifications/configs" \
  -H "Content-Type: application/json" \
  -d '{
    "service_name": "mysql.service",
    "host": "production-server",
    "sms_provider": "twilio",
    "cooldown_minutes": 5,
    "contacts": [{
      "name": "DBA Team",
      "phone": "+50212345678",
      "enabled": true,
      "channels": ["sms"],
      "notify_on": ["service_down", "service_restart_failed"]
    }]
  }'
```

**2. Test notification:**
```bash
curl -X POST "http://localhost:8000/notifications/test/sms" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+50212345678",
    "message": "MySQL monitoring active",
    "provider": "twilio"
  }'
```

**3. Add second contact for critical alerts only:**
```bash
curl -X POST "http://localhost:8000/notifications/configs/mysql.service/contacts?host=production-server" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CTO",
    "phone": "+50298765432",
    "enabled": true,
    "channels": ["sms"],
    "notify_on": ["service_restart_failed"]
  }'
```

**4. What happens when MySQL fails:**
- Monitor detects MySQL is down
- Sends: `"ALERT: Service 'mysql.service' on production-server is DOWN"`
- Both DBA Team and CTO receive SMS
- Monitor tries to restart
- Sends: `"INFO: Attempting to restart service 'mysql.service'..."`
- Only DBA Team receives this (CTO only gets failures)
- If restart fails:
  - Sends: `"CRITICAL: Failed to restart service 'mysql.service'..."`
  - Both receive alert
- Won't send another alert for 5 minutes (cooldown)

---

## Troubleshooting

### No SMS Received

**Check provider status:**
```bash
curl http://localhost:8000/notifications/status
```

**Check notification history:**
```bash
curl "http://localhost:8000/notifications/history?service_name=mysql.service&status=failed"
```

**Common issues:**
- ❌ Wrong phone format (must be E.164: +country_code)
- ❌ Provider credentials not configured in `.env`
- ❌ Service has no notification config
- ❌ Contact disabled (`enabled: false`)
- ❌ Event type not in contact's `notify_on` list
- ❌ Cooldown period active

### Test Provider Directly

**AWS SNS:**
```bash
curl -X POST "http://localhost:8000/notifications/test/sms" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+50212345678", "message": "AWS test", "provider": "aws_sns"}'
```

**Twilio:**
```bash
curl -X POST "http://localhost:8000/notifications/test/sms" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+50212345678", "message": "Twilio test", "provider": "twilio"}'
```

### Check MongoDB Collections

```javascript
// In MongoDB shell
use service_monitoring

// View configs
db.notification_configs.find().pretty()

// View history
db.notification_history.find().sort({timestamp: -1}).limit(10).pretty()
```

---

## Cost Estimation

### Example: 10 services, 2 restarts/day

**AWS SNS:**
- 10 services × 2 restarts × 2 notifications = 40 SMS/day
- 40 × 30 days = 1,200 SMS/month
- 1,200 × $0.00645 = **$7.74/month**

**Twilio:**
- Same calculation
- 1,200 × $0.0075 = **$9.00/month**

**Tip**: Use AWS SNS for low-priority services, Twilio for critical ones

---

## Best Practices

1. **Use cooldown wisely**: 5-10 minutes prevents spam during rapid restarts
2. **Different contacts for different events**: CTO only gets failures, DevOps gets all
3. **Test before production**: Always test with `/test/sms` endpoint
4. **Monitor costs**: Check `/notifications/stats` regularly
5. **Provider selection**:
   - AWS SNS: Slightly cheaper, good integration
   - Twilio: Better delivery rates, detailed status
6. **Phone number format**: Always E.164 (+country_code)
7. **Contact organization**: Use descriptive names ("DBA-Team", "On-Call-Engineer")

---

## Future Enhancements

Coming soon:
- ✉️ Email notifications
- 📱 Push notifications (Firebase)
- 📊 Delivery rate analytics
- 🔄 Retry logic for failed SMS
- 📅 Scheduled notification windows

---

## Support

**View API docs**: http://localhost:8000/docs

**Check logs**: MongoDB collections `notification_configs` and `notification_history`

**Provider documentation**:
- AWS SNS: https://docs.aws.amazon.com/sns/
- Twilio: https://www.twilio.com/docs/sms
