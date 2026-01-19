# Mattermost on Hetzner Cloud (Terraform)

Deploy a production-ready Mattermost stack on **Hetzner Cloud** using **Terraform** and **Docker**, with Cloudflare in front for TLS and optional extra hardening.

## Value Analysis

| Instance | Peak Capacity | Price | Cost per 100 Users | Value Rating |
|----------|---------------|-------|-------------------|--------------|
| CX23 | 400 | €3.00 | €0.75 | ⭐⭐⭐ |
| CPX22 | 750 | €6.00 | €0.80 | ⭐⭐⭐⭐⭐ Best Budget |
| CX33 | 1000 | €5.00 | €0.50 | ⭐⭐⭐⭐⭐ Best Value |
| CCX13 | 900 | €12.00 | €1.33 | ⭐⭐⭐ Premium |
| CPX32 | 1500+ | €10.50 | €0.70 | ⭐⭐⭐⭐⭐ Best Performance |

**Key Finding**: 4 AMD EPYC cores (CPX32) = best of both worlds. Fast single-thread performance + excellent parallelization. Worth every cent for 1000+ users!