# Performance Testing Results

> **Disclaimer**: These are synthetic load test results using [Locust](https://locust.io). Tests simulate concurrent users posting messages and uploading files. Real-world performance varies significantly based on actual usage patterns, installed plugins, file sizes, database queries, and concurrent active users vs. registered users. Your mileage may vary.

## Executive Summary

**🏆 ULTIMATE FINDING**: **CPX32 (4 AMD EPYC cores) is the ABSOLUTE CHAMPION!** Handles 1500 concurrent users with 35ms median response time and 99.58% success rate. 

**Key Insight**: More cores beat faster cores when workload parallelizes (PostgreSQL benefits massively from 4 vCPU). AMD EPYC processors consistently outperform Intel at the same core count.

## Testing Methodology

### Test Setup

- **Tool**: Locust 2.43.1 (Python-based load testing)
- **Test Location**: Separate Hetzner Cloud instance (realistic network conditions)
- **Test Pattern**: 
  - Each user posts **1 message every ~5 seconds**
  - Each user uploads **1 file every ~2 minutes** (~100 bytes)
  - Users ramped up gradually (**25 users/second**)
  - Each test runs **10 minutes** at target load

### Server Configuration

- **Stack**: Mattermost + PostgreSQL + NGINX (all Docker containers)
- **Network**: Cloudflare reverse proxy with bot IP whitelisting
- **Authentication**: Bot API tokens
- **Database**: PostgreSQL (default configuration, no tuning)
- **Cache**: Default Mattermost cache settings

### Metrics Definition

- **Concurrent Users**: Active users simultaneously connected and making requests
  - Typical real-world ratio: 5-20% of total registered users are concurrent
  - Example: 100 concurrent ≈ 500-2,000 registered users

- **Throughput**: Total requests per second (messages + file uploads combined)

- **Response Times** (milliseconds):
  - **Median (50th percentile)**: Typical user experience
  - **95th percentile**: Performance for 95% of requests
  - **99th percentile**: Worst-case performance for 99% of requests

- **Failure Rate**: Percentage of requests that failed (timeouts, errors)

- **CPU Usage**: Percentage of available CPU cores utilized
  - Single core = 100% maximum
  - Multi-core: 100% per core (e.g., 200% = 2 cores maxed)

---

## Comprehensive Test Results

### All Instances @ 400 Concurrent Users

| Instance | CPU Type | Cores | Median | 95%ile | 99%ile | Failures | CPU Usage | Load Avg |
|----------|----------|-------|--------|--------|--------|----------|-----------|----------|
| CX23 | Intel | 2 | 46ms | 150ms | 300ms | 0% | ~130% | 3.2 |
| CPX22 | AMD EPYC | 2 | **34ms** | **110ms** | **180ms** | **0%** | ~100% | 0.9 |
| CCX13 | AMD EPYC (ded) | 2 | 36ms | 125ms | 210ms | 0% | ~60% | 2.1 |
| CX33 | Intel | 4 | 38ms | 140ms | 220ms | 0% | ~70% | 2.5 |
| CPX32 | AMD EPYC | 4 | 35ms | 105ms | 175ms | 0% | ~65% | 2.3 |

**Winner @ 400 users**: **CPX22** - Best performance per euro at this scale.

---

### All Instances @ 750 Concurrent Users

| Instance | CPU Type | Cores | Median | 95%ile | 99%ile | Failures | CPU Usage | Load Avg |
|----------|----------|-------|--------|--------|--------|----------|-----------|----------|
| CX23 | Intel | 2 | 1000ms | 3400ms | 4700ms | 0% | ~160% | 8.3 |
| CPX22 | AMD EPYC | 2 | **35ms** | **160ms** | **240ms** | **0%** | ~150% | 4.7 |
| CCX13 | AMD EPYC (ded) | 2 | 33ms | 200ms | 320ms | 0% | ~60% | 4.1 |
| CX33 | Intel | 4 | 38ms | 160ms | 240ms | 0.07% | ~63% | 4.0 |
| CPX32 | AMD EPYC | 4 | 35ms | 155ms | 235ms | 0% | ~58% | 3.8 |

**Winner @ 750 users**: **CPX22** - Fastest at lowest cost. CPX32 matches performance but costs 75% more.

---

### All Instances @ 1000 Concurrent Users

| Instance | CPU Type | Cores | Median | 95%ile | 99%ile | Failures | CPU Usage | Load Avg |
|----------|----------|-------|--------|--------|--------|----------|-----------|----------|
| CX23 | Intel | 2 | N/A | N/A | N/A | N/A | Beyond capacity | N/A |
| CPX22 | AMD EPYC | 2 | 51ms | 1600ms | 2700ms | 1.9% | ~190% | 12.3 |
| CCX13 | AMD EPYC (ded) | 2 | 51ms | 1600ms | 2700ms | 1.9% | ~77% | 6.5 |
| CX33 | Intel | 4 | **46ms** | **210ms** | **520ms** | **0.07%** | ~73% | 8.8 |
| CPX32 | AMD EPYC | 4 | 34ms | 185ms | 410ms | 0% | ~70% | 8.2 |

**Winner @ 1000 users**: **CPX32** - Dramatically better than 2-core options. CX33 also excellent.

---

### All Instances @ 1250 Concurrent Users - **THE SHOWDOWN**

| Instance | CPU Type | Cores | Median | 95%ile | 99%ile | Failures | CPU Idle | Load Avg |
|----------|----------|-------|--------|--------|--------|----------|----------|----------|
| CPX22 | AMD EPYC | 2 | 470ms | 2200ms | 3100ms | 4.5% | 23% | 14.7 |
| CCX13 | AMD EPYC (ded) | 2 | 930ms | 3100ms | 7100ms | 6.7% | 0% | 14.0 |
| CX33 | Intel | 4 | 1000ms | 3100ms | 4200ms | 6.0% | 59% | 20.3 |
| **CPX32** | **AMD EPYC** | **4** | **35ms** | **190ms** | **440ms** | **0.07%** | **24%** | **8.0** |

**CHAMPION @ 1250 users**: **CPX32 crushes all competitors**
- **93-96% faster median response**
- **91-94% better 95th percentile**
- **86-90% better 99th percentile**  
- **98-99% fewer failures**
- **Still has 24% CPU idle** (room for more load)

---

### All Instances @ 1500 Concurrent Users - **THE ULTIMATE TEST**

| Instance | CPU Type | Cores | Median | 95%ile | 99%ile | Failures | CPU Idle | Load Avg | Total Requests |
|----------|----------|-------|--------|--------|--------|----------|----------|----------|----------------|
| CPX22 | AMD EPYC | 2 | 660ms | 2500ms | 4500ms | 5.6% | 18% | 16.8 | 47,290 |
| CCX13 | AMD EPYC (ded) | 2 | Beyond capacity | N/A | N/A | >10% | N/A | N/A | N/A |
| CX33 | Intel | 4 | Beyond capacity | N/A | N/A | >8% | N/A | N/A | N/A |
| **CPX32** | **AMD EPYC** | **4** | **35ms** | **340ms** | **980ms** | **0.42%** | **33%** | **7.9** | **56,370** |

**CPX32 @ 1500 users**:
- **Processed 56,370 requests** with **99.58% success rate**
- **35ms median** (identical to 750 users!)
- **340ms 95th percentile** (99% of requests sub-1 second)
- **980ms 99th percentile** (still acceptable)
- **33% CPU idle** - likely handles 1750-2000 users comfortably

---

## Performance Matrix - All Concurrent Levels

### CX23 (2 vCPU Intel Shared, €3/month)

| Concurrent Users | Median | 95%ile | 99%ile | Failures | CPU | Status |
|-----------------|--------|--------|--------|----------|-----|--------|
| 50 | 39ms | 60ms | 80ms | 0% | 15% | ✅ Excellent |
| 200 | 47ms | 100ms | 150ms | 0% | 85% | ✅ Good |
| 400 | 46ms | 150ms | 300ms | 0% | 130% | ⚠️ Acceptable |
| 500 | 46ms | 200ms | 2000ms | 0% | 140% | ⚠️ Borderline |
| 750 | 1000ms | 3400ms | 4700ms | 0% | 160% | ❌ Poor |

**Recommendation**: Comfortable up to **400 users**. Beyond that, response times degrade rapidly.

---

### CPX22 (2 vCPU AMD EPYC Shared, €6/month)

| Concurrent Users | Median | 95%ile | 99%ile | Failures | CPU | Status |
|-----------------|--------|--------|--------|----------|-----|--------|
| 400 | 34ms | 110ms | 180ms | 0% | 100% | ✅ Excellent |
| 750 | 35ms | 160ms | 240ms | 0% | 150% | ✅ Excellent |
| 1000 | 51ms | 1600ms | 2700ms | 1.9% | 190% | ⚠️ Degrading |
| 1250 | 470ms | 2200ms | 3100ms | 4.5% | 180% | ❌ Breaking |
| 1500 | 660ms | 2500ms | 4500ms | 5.6% | 190% | ❌ Failed |

**Recommendation**: Comfortable up to **750 users**. Best value at this capacity.

---

### CCX13 (2 vCPU AMD EPYC Dedicated, €12/month)

| Concurrent Users | Median | 95%ile | 99%ile | Failures | CPU | Status |
|-----------------|--------|--------|--------|----------|-----|--------|
| 750 | 33ms | 200ms | 320ms | 0% | 60% | ✅ Perfect |
| 1000 | 51ms | 1600ms | 2700ms | 1.9% | 77% | ⚠️ Degrading |
| 1250 | 930ms | 3100ms | 7100ms | 6.7% | 200% | ❌ Failed |

**Recommendation**: Comfortable up to **900 users**. Dedicated cores don't provide huge gains - mainly for predictable performance.

---

### CX33 (4 vCPU Intel Shared, €5/month)

| Concurrent Users | Median | 95%ile | 99%ile | Failures | CPU | Status |
|-----------------|--------|--------|--------|----------|-----|--------|
| 750 | 38ms | 160ms | 240ms | 0.07% | 63% | ✅ Excellent |
| 1000 | 46ms | 210ms | 520ms | 0.07% | 73% | ✅ Excellent |
| 1250 | 1000ms | 3100ms | 4200ms | 6.0% | 290% | ❌ Failed |

**Recommendation**: Comfortable up to **1000 users**. Great parallelization benefits from 4 cores.

---

### CPX32 (4 vCPU AMD EPYC Shared, €10.50/month) - 🏆 CHAMPION

| Concurrent Users | Median | 95%ile | 99%ile | Failures | CPU | Status |
|-----------------|--------|--------|--------|----------|-----|--------|
| 1000 | 34ms | 185ms | 410ms | 0% | 70% | ✅ Excellent |
| 1250 | 35ms | 190ms | 440ms | 0.07% | 76% | ✅ Outstanding |
| 1500 | 35ms | 340ms | 980ms | 0.42% | 67% | ✅ Incredible |

**Recommendation**: Comfortable up to **1500+ users**. Likely handles 1750-2000 comfortably based on remaining CPU idle.

---

## Price/Performance Comparison

### Cost per 100 Concurrent Users

| Instance | Cores | Safe Capacity | Monthly Price | Cost per 100 Users | Value |
|----------|-------|---------------|---------------|--------------------|-------|
| CX23 | 2 | 400 | €3.00 | €0.75 | ⭐⭐⭐ |
| CPX22 | 2 | 750 | €6.00 | €0.80 | ⭐⭐⭐⭐⭐ Best Budget |
| CCX13 | 2 | 900 | €12.00 | €1.33 | ⭐⭐⭐ Premium |
| CX33 | 4 | 1000 | €5.00 | €0.50 | ⭐⭐⭐⭐⭐ Best Value |
| CPX32 | 4 | 1500+ | €10.50 | €0.70 | ⭐⭐⭐⭐⭐ Best Performance |

---

## Instance Selection Guide

### Choose CX23 if:
- ✅ Budget is critical (<€5/month)
- ✅ Small team (<1000 registered users)
- ✅ 200-300 concurrent active users max
- ✅ Development/testing environment

### Choose CPX22 if:
- ✅ Best value for 750 concurrent users
- ✅ Budget-conscious (
€6/month)
- ✅ Growing team (1000-7500 registered users)
- ✅ Excellent single-thread performance
- ⚠️ Starts degrading >1000 users

### Choose CCX13 if:
- ✅ Dedicated cores required (no noisy neighbors)
- ✅ Predictable performance guaranteed
- ✅ Large team (9000-18000 registered users)
- ✅ Can afford 100% CPU premium vs CPX22
- ⚠️ Not significantly better capacity than CPX22

### Choose CX33 if:
- ✅ Best value for 1000 concurrent users (€0.50 per 100)
- ✅ Excellent parallelization benefits
- ✅ Large team (10000-20000 registered users)
- ✅ Intel hardware preferred
- ⚠️ Slower single-thread than AMD EPYC
- ⚠️ Breaks down >1250 users

### Choose CPX32 if:
- ✅ 1000+ concurrent users
- ✅ Very large team (20000+ registered users)
- ✅ Enterprise requirements
- ✅ Need guaranteed excellent performance
- ✅ Both speed AND parallelization matter
- ✅ 99%+ availability required
- 🏆 **THE ABSOLUTE CHAMPION** for 1500+ users

---

## Key Performance Insights

### 1. **More Cores Win at High Load**
At 1000+ concurrent users, 4 cores dramatically outperform 2 cores. PostgreSQL query parallelization is the key benefit.

**Evidence**:
- CPX22 (2 cores) @ 1250 users: 470ms median, 4.5% failures
- CPX32 (4 cores) @ 1250 users: 35ms median, 0.07% failures
- **93% faster!**

### 2. **AMD EPYC Beats Intel Per-Core**
At the same core count, AMD EPYC (CPX series) outperforms Intel (CX series).

**Evidence**:
- CPX22 vs CX23 @ 400 users: 34ms vs 46ms (35% faster)
- CPX32 vs CX33 @ 1250 users: 35ms vs 1000ms (96% faster)
- AMD's single-thread performance matters!

### 3. **Dedicated Cores Don't Justify 100% Premium**
CCX13 (2 cores dedicated) vs CPX22 (2 cores shared): CCX13 costs 100% more but offers only 20% more capacity.

**Verdict**: Only choose dedicated cores if predictable performance is mission-critical.

### 4. **CPU Headroom Predicts Capacity**
When CPU reaches 70-80% at a given load, degradation is imminent. CPX32 at 1500 users shows 67% CPU (33% idle) - indicating room for 1750-2000 users.

### 5. **Scaling Breaks at Double-Core Limitations**
- 2-core instances break down hard >1000 users
- 4-core instances handle 1500+ smoothly
- Suggests **4 cores is minimum for 1000+ users**

---

## Running Your Own Tests

### Locust Configuration

```bash
# Install Locust
pip install locust

# Basic load test (250 users, 10 minute duration)
locust -f locustfile.py \
  --headless \
  --users 250 \
  --spawn-rate 25 \
  --host "https://your-mattermost.domain" \
  --run-time 10m \
  --html report.html
```

### Creating a Test Locustfile

See the [Locust Documentation](https://docs.locust.io/) for detailed examples. Key points:
- Use bot tokens for authentication
- Simulate realistic wait times (5-10 seconds between messages)
- Mix POST requests (messages) with file uploads
- Ramp users gradually (25-30 per second)

---

## Real-World Considerations

### Registered Users vs Concurrent Users

These tests measure **concurrent active users**, not total registered users:
- **Small deployment**: 1000 registered = 50-200 concurrent (5-20% ratio)
- **Medium deployment**: 5000 registered = 250-1000 concurrent
- **Large deployment**: 20000 registered = 1000-4000 concurrent

### Factors Not Tested

- **Plugins**: Heavy plugins (video calls, AI integrations) will increase resource usage
- **File uploads**: Larger files consume more bandwidth/CPU
- **Search queries**: Elasticsearch would significantly change performance
- **Audit logging**: Extensive logging increases PostgreSQL load
- **Custom integrations**: Webhooks and bots add unpredictable overhead

### Optimization Opportunities

1. **PostgreSQL tuning** - Connection pooling, query optimization
2. **Redis cache** - Reduces database queries significantly
3. **S3 storage** - Offload file I/O from local disk
4. **Elasticsearch** - Dedicated search instead of PostgreSQL
5. **Horizontal scaling** - Multiple Mattermost instances + load balancer

---

## Testing Notes

- **Test Date**: January 19-20, 2026
- **Mattermost Version**: 11.3.0
- **Locust Version**: 2.43.1
- **PostgreSQL**: Default configuration (no tuning)
- **Network**: Cloudflare proxy in front (stable latency)
- **Test Duration**: 10 minutes each test
- **Ramping**: 25 users/second
- **No caching**: Test represents worst-case PostgreSQL load

---

## Related Documentation

- [Mattermost Scaling Guide](https://docs.mattermost.com/scale/scale-to-high-availability.html)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [Locust Load Testing](https://docs.locust.io/)
- [Hetzner Cloud Instance Types](https://www.hetzner.cloud/)

---

**Conclusion**: CPX32 (4 AMD EPYC cores @ €10.50/month) is the ultimate choice for production deployments expecting 1000+ concurrent users. Combines AMD's superior single-thread performance with parallelization benefits of 4 cores. At €0.70 per 100 users, it's excellent value for enterprise scale.