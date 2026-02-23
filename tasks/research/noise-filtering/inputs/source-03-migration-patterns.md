# Enterprise Cloud Migration Patterns

Common migration strategies observed across 200+ enterprise migrations:

## The 6 R's Applied
- Rehost (lift-and-shift): 35% of workloads, fastest but least optimized
- Replatform: 25% of workloads, moderate effort with container adoption
- Refactor: 15% of workloads, highest ROI but 3-4x longer timeline
- Retire: 10% of legacy systems identified as redundant
- Retain: 10% kept on-premises due to latency or regulatory requirements
- Repurchase: 5% replaced with SaaS alternatives

## Financial Services Specific
- PCI-DSS compliance requires dedicated tenancy for cardholder data
- SOX audit trails must be maintained through migration
- Cross-border data transfer restrictions affect multi-region deployments
- Disaster recovery RTO requirements typically tighter (< 1 hour)
