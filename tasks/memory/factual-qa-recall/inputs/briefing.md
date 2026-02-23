# Project Phoenix — Executive Briefing

## Overview
Project Phoenix is a cloud migration initiative led by **Dr. Elena Vasquez** (Chief Architect) with a total approved budget of **$4,230,000**. The project was greenlit on **January 12, 2025** by the steering committee and has a hard deadline of **September 30, 2025**.

## Team Structure
The project is organized into 4 workstreams:
- **Infrastructure Team**: 14 engineers, led by **James Okafor**, budget allocation of **$847,000** for Q3
- **Application Team**: 22 engineers, led by **Priya Sharma**, responsible for migrating **137 microservices**
- **Data Team**: 9 engineers, led by **Carlos Mendez**, managing **2.4 petabytes** of data migration
- **Security Team**: 6 engineers, led by **Anna Kowalski**, performing **3 compliance audits** per quarter

Total headcount across all teams: **51 engineers** plus **4 team leads** and **1 project manager (Robert Liu)**.

## Technology Stack
- **Primary cloud provider**: AWS (us-east-1 and eu-west-2 regions)
- **Container orchestration**: Kubernetes v1.29 with **84 pods** minimum baseline
- **Database**: PostgreSQL 16 for transactional, Apache Cassandra for time-series
- **Message queue**: Apache Kafka with **12 partitions** per topic
- **CI/CD**: GitLab CI with pipeline ID **PHX-CI-9927**
- **Monitoring**: Grafana Cloud, dashboard collection **GC-PHX-440**

## Vendor Contracts
- **CloudMatrix Inc.** provides managed Kubernetes support — contract value **$186,000/year**, renewal date **June 15, 2025**
- **DataVault Solutions** handles backup infrastructure — **$94,500/year**, SLA guarantees **99.95% availability**
- **SecureNet Partners** performs quarterly penetration testing — **$67,000 per engagement**

## Key Milestones
- Phase 1 (Infrastructure Setup): Complete by **March 28, 2025**
- Phase 2 (Application Migration): Complete by **June 30, 2025**
- Phase 3 (Data Migration): Complete by **August 15, 2025**
- Phase 4 (Validation & Cutover): Complete by **September 30, 2025**

## Performance Targets
- API response time P95: **180ms**
- System uptime SLA: **99.99%**
- Maximum failover time: **45 seconds**
- Daily transaction volume capacity: **8.2 million transactions**

## Budget Breakdown by Quarter
- Q1 2025: **$1,120,000** (infrastructure provisioning)
- Q2 2025: **$1,450,000** (peak migration activity)
- Q3 2025: **$1,160,000** (data migration + validation)
- Q4 2025: **$500,000** (contingency and stabilization)

## Risk Register
- Risk #1: Kafka partition rebalancing during migration — mitigation: **blue-green deployment**
- Risk #2: Legacy Oracle dependencies in **23 services** — mitigation: compatibility shim layer
- Risk #3: GDPR compliance for EU data — mitigation: data residency enforcement in **eu-west-2 only**
