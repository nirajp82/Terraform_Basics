# Chapter Summary: Mutable and Immutable Infrastructure

## 1. Mutable Infrastructure

The same server persists across an update; only its software and configuration change, via an in-place upgrade (manual, scripted, or config management tooling).

## 2. Configuration Drift

Partial upgrade failures across a pool of servers cause them to diverge from one another over time — some upgraded, some not — making the pool harder to plan around and troubleshoot.

## 3. Immutable Infrastructure

A resource is never updated in place. A new resource is provisioned with the desired change, and the old one is deleted only once the new one is confirmed working — so a failed update leaves the old resource untouched rather than half-upgraded.

## 4. Why Terraform Defaults to Immutable

Terraform destroys a resource and creates its replacement by default, rather than patching it in place (e.g. `local_file`'s `file_permission` or `content` changes). The old resource is destroyed first, then the new one is created — an order changeable via lifecycle rules, covered next.

---

## Knowledge Check Q&A

**Q: What defines mutable infrastructure?**
**A:** The same server persists across updates; only its software and configuration change, typically via an in-place upgrade.

**Q: What causes configuration drift in a pool of servers?**
**A:** Partial upgrade failures — some servers upgrade successfully while others don't, leaving the pool running mismatched versions.

**Q: What defines immutable infrastructure?**
**A:** A resource is never updated in place; a new resource is provisioned with the desired change, and the old one is deleted only after the new one succeeds.

**Q: How does failure behavior differ between the two models?**
**A:** Mutable infrastructure can leave a server half-upgraded on failure. Immutable infrastructure leaves the old resource untouched and only discards the failed new one.

**Q: Which model does Terraform follow by default?**
**A:** Immutable — Terraform destroys the existing resource and creates its replacement rather than modifying it in place.

**Q: By default, does Terraform create the replacement before or after destroying the old resource?**
**A:** After — destroy happens first, then create. This order can be changed with lifecycle rules.
