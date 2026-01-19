# Performance Testing Results

> **Disclaimer**: These are synthetic load test results using [Locust](https://locust.io). Tests simulate concurrent users posting messages and uploading files. Real-world performance varies significantly based on actual usage patterns, installed plugins, file sizes, database queries, and concurrent active users vs. registered users. Your mileage may vary.

## Testing Methodology

### Test Setup

- **Tool**: Locust load testing framework (Python-based)
- **Test Location**: Separate Hetzner Cloud instance (to simulate real network conditions)
- **Test Pattern**: 
  - Each simulated user sends **1 message every ~5 seconds**
  - Each simulated user uploads **1 file (~100 bytes text file) every ~2 minutes**
  - Users ramped up gradually (5-30 users/second depending on test scale)
  - Tests run from 10 minutes to 1 hour depending on load level

### Server Configuration

- **Deployment**: Standard Docker setup from this repository
- **Stack**: Mattermost + PostgreSQL + NGINX (all containerized)
- **Network**: Cloudflare proxy in front (with IP whitelisting for test traffic)
- **Authentication**: Bot token used for API requests
- **No customizations**: Default configuration, no performance tuning applied

### Metrics Explained

- **Concurrent Users**: Number of users actively sending messages simultaneously
  - This is NOT total registered users
  - Real-world ratio: typically 5-20% of registered users are concurrently active
  - Example: 200 concurrent active users ≈ 1,000-4,000 total registered users

- **Throughput**: Total requests per second (messages + file uploads)

- **Response Times**:
  - **Median (50th percentile)**: Typical user experience
  - **95th percentile**: 95% of requests faster than this
  - **99th percentile**: Worst-case for 99% of requests
  - Response time = time from request sent to response received

- **CPU Percentage**: Can exceed 100% on multi-core systems
  - 200% = 2 vCPU cores fully utilized
  - Shows as load average in system metrics

## Test Results

### Hetzner CX23 (2 vCPU, 4GB RAM, ~€6/month)

**Server Specs**: AMD EPYC, 2 dedicated vCPU cores, 4GB RAM, 40GB SSD

| Concurrent Users | Throughput (req/s) | Median Response | 95th Percentile | 99th Percentile | Max Response | Failure Rate | CPU Usage | Notes |
|-----------------|-------------------|-----------------|-----------------|-----------------|--------------|--------------|-----------|-------|
| 50 | 10 | 39ms | 60ms | 80ms | 98ms | 0% | ~15% | ✅ **Excellent** - Plenty of headroom |
| 200 | 40 | 47ms | 100ms | 150ms | 200ms | 0% | ~85% | ✅ **Good** - Responsive, CPU getting busy |
| 400 | 80 | 46ms | 150ms | 300ms | 372ms | 0% | ~130% | ⚠️ **Acceptable** - CPU maxed, occasional spikes |
| 500 | 100 | 46ms | 200ms | 2000ms | 1677ms | 0% | ~140% | ⚠️ **Borderline** - Noticeable worst-case delays |
| 750 | 115 | **1000ms** | 3400ms | 4700ms | 9174ms | 0% | ~160% | ❌ **Poor UX** - 1 second lag, users notice |

#### CX23 Analysis

**Recommended Capacity**:
- **Comfortable**: 200-300 concurrent active users for excellent performance (sub-50ms)
- **Maximum**: 400-500 concurrent users with acceptable degradation
- **Do not exceed**: 600+ users (response times exceed 1 second)

**Real-World Translation**:
- Small team: 50-100 registered users → CX23 is perfect
- Medium team: 500-1,500 registered users → CX23 works well
- Large team: 2,000-5,000 registered users → Consider CPX31 or higher

**Bottleneck**: CPU becomes saturated at 400+ users. Memory usage remained comfortable (<1GB) throughout all tests.

**Key Observations**:
- Response times stayed remarkably consistent even under heavy load
- Zero failures across all test levels (impressive Mattermost resilience)
- Median response times only degraded significantly above 600 users
- 99th percentile spikes indicate PostgreSQL query queueing under load

---

### Hetzner CPX22 (3 vCPU, 4GB RAM, ~€9/month)

**Server Specs**: AMD EPYC, 3 dedicated vCPU cores, 4GB RAM, 80GB SSD

| Concurrent Users | Throughput (req/s) | Median Response | 95th Percentile | 99th Percentile | Failure Rate | CPU Usage | Notes |
|-----------------|-------------------|-----------------|-----------------|-----------------|--------------|-----------|-------|
| _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | ⏳ **Testing in progress** |

#### CPX22 Analysis

_Results will be added after testing completes. Expected improvement: 50% more capacity due to additional vCPU core._

---

### Future Testing Plans

- **CPX22**: Currently testing (3 vCPU)
- **CPX31**: Planned (4 vCPU, 8GB RAM) - for larger deployments
- **Load patterns**: Test different usage scenarios (heavy file sharing, search queries)
- **Long-duration**: 24-hour stability tests under sustained load

---

## Performance Optimization Tips

### Without Upgrading Hardware

1. **Enable PostgreSQL connection pooling** - Reduces database overhead
2. **Disable unused plugins** - Saves CPU cycles
3. **Tune PostgreSQL** - Adjust `shared_buffers` and `work_mem`
4. **Use object storage for files** - Offload file serving to S3-compatible storage
5. **Enable Elasticsearch** (if needed) - Offload search from PostgreSQL

### When to Upgrade

- **CPU consistently >80%**: Upgrade to more vCPUs (CPX or CCX series)
- **Memory >3.5GB**: Upgrade RAM (CPX31: 8GB, CPX41: 16GB)
- **Disk I/O bottleneck**: Switch to storage-optimized instance or add volumes
- **Response times >100ms median**: Consider horizontal scaling (load balancer + multiple app servers)

---

## Running Your Own Tests

### Quick Test Setup

Use this cloud-init script to spin up a load tester on Hetzner:

```yaml
#cloud-config
packages:
  - python3
  - python3-pip
  - python3-venv

write_files:
  - path: /root/locustfile.py
    content: |
      import os
      import random
      import string
      from locust import HttpUser, task, between
      from io import BytesIO

      # Configuration
      MATTERMOST_URL = "https://your-server.com"
      BOT_TOKEN = "your-bot-token"
      CHANNEL_ID = "your-channel-id"

      class MattermostUser(HttpUser):
          wait_time = between(4, 6)
          
          def on_start(self):
              self.client.headers.update({
                  "Authorization": f"Bearer {BOT_TOKEN}",
                  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
              })
              self.file_counter = 0
          
          @task(24)
          def post_message(self):
              message_text = f"Test message: {self.random_text(10)}"
              payload = {"channel_id": CHANNEL_ID, "message": message_text}
              self.client.post("/api/v4/posts", json=payload)
          
          @task(1)
          def upload_file(self):
              self.file_counter += 1
              file_content = f"Test file {self.file_counter}\n{self.random_text(100)}"
              file_data = BytesIO(file_content.encode())
              files = {'files': (f'test_{self.file_counter}.txt', file_data, 'text/plain')}
              
              response = self.client.post(f"/api/v4/files?channel_id={CHANNEL_ID}", files=files)
              if response.status_code == 201:
                  file_id = response.json()['file_infos'][0]['id']
                  self.client.post("/api/v4/posts", json={
                      "channel_id": CHANNEL_ID,
                      "message": f"File upload test {self.file_counter}",
                      "file_ids": [file_id]
                  })
          
          @staticmethod
          def random_text(length):
              return ''.join(random.choices(string.ascii_letters + string.digits + ' ', k=length))

  - path: /root/start_test.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      sleep 10
      python3 -m venv /root/locust-venv
      source /root/locust-venv/bin/activate
      pip install --upgrade pip
      pip install locust
      
      cd /root
      locust -f locustfile.py \
        --headless \
        --users 200 \
        --spawn-rate 10 \
        --host "https://your-server.com" \
        --run-time 30m \
        --html /root/locust_report.html \
        --csv /root/locust_stats

runcmd:
  - /root/start_test.sh > /root/locust.log 2>&1 &
```

### Prerequisites for Testing

1. **Create a bot account** in Mattermost (System Console → Integrations → Bot Accounts)
2. **Get bot token** and channel ID
3. **Whitelist test server IP** in Cloudflare (to avoid bot protection blocking)
4. **Update cloud-init**: Replace `MATTERMOST_URL`, `BOT_TOKEN`, and `CHANNEL_ID`
5. **Spin up Hetzner instance** with the cloud-init script
6. **Monitor**: SSH in and run `tail -f /root/locust.log`

### Test Commands

```bash
# SSH into test instance
ssh root@test-server-ip

# Check test progress
tail -f /root/locust.log

# Download results after test completes
scp root@test-server-ip:/root/locust_report.html ./

# Stop test early
pkill -f locust

# Run custom test
source /root/locust-venv/bin/activate
locust -f /root/locustfile.py --headless --users 500 --spawn-rate 20 \
  --host "https://your-server.com" --run-time 10m --html /root/report.html
```

---

## Comparison with Other Hosting Options

### Why Hetzner Cloud?

| Provider | Instance | vCPU | RAM | Price/month | CX23 Equivalent |
|----------|----------|------|-----|-------------|------------------|
| Hetzner | CX23 | 2 | 4GB | ~€6 | Baseline |
| AWS | t3.medium | 2 | 4GB | ~$30 | 5x more expensive |
| DigitalOcean | Basic 4GB | 2 | 4GB | $24 | 4x more expensive |
| Azure | B2s | 2 | 4GB | ~$30 | 5x more expensive |

**Verdict**: Hetzner offers exceptional price/performance for European workloads. For US-based teams, AWS/DO may offer better latency.

---

## Contributions

If you run performance tests on different instance types or configurations, please submit a PR with your results! Include:
- Instance specs
- Test methodology
- Raw Locust output or HTML report
- Any custom configuration changes

---

## Related Documentation

- [Mattermost Scaling Guide](https://docs.mattermost.com/scale/scale-to-high-availability.html)
- [PostgreSQL Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [Locust Documentation](https://docs.locust.io/)

---

**Last Updated**: January 19, 2026  
**Mattermost Version**: 11.3.0  
**Test Framework**: Locust 2.43.1
