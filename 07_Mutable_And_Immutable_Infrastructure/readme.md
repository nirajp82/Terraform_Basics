# Chapter Summary: Mutable and Immutable Infrastructure

## 1. Mutable Infrastructure

The same server persists across an update; only its software and configuration change, via an in-place upgrade (manual, scripted, or config management tooling).

## 2. Configuration Drift

Partial upgrade failures across a pool of servers cause them to diverge from one another over time — some upgraded, some not — making the pool harder to plan around and troubleshoot.

## 3. Immutable Infrastructure

A resource is never updated in place. A new resource is provisioned with the desired change, and the old one is deleted only once the new one is confirmed working — so a failed update leaves the old resource untouched rather than half-upgraded.

## 4. Why Terraform Defaults to Immutable

Terraform destroys a resource and creates its replacement by default, rather than patching it in place (e.g. `local_file`'s `file_permission` or `content` changes). The old resource is destroyed first, then the new one is created — an order changeable via lifecycle rules, covered next.

## 5. The `lifecycle` Block

Goes directly inside a `resource` block to override Terraform's default destroy-then-create behavior for that resource.

## 6. `create_before_destroy`

On a forced replacement, creates the new resource before destroying the old one — reversing the default order.

## 7. `prevent_destroy`

Rejects any `apply` that would destroy the resource. Does not block `terraform destroy`, which still works — it only guards against accidental deletion via configuration changes.

## 8. `ignore_changes`

Takes a list of attribute names (or the `all` keyword) and stops Terraform from correcting drift on them — an external change to a listed attribute is left alone instead of reverted on the next `apply`.

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

**Q: Where does a `lifecycle` block go?**
**A:** Directly inside the `resource` block whose behavior it should change.

**Q: What does `create_before_destroy = true` change?**
**A:** It creates the replacement resource before destroying the old one, instead of after.

**Q: Does `prevent_destroy = true` stop a resource from ever being destroyed?**
**A:** No — it only blocks destruction via configuration change + `apply`. `terraform destroy` still works regardless.

**Q: What kind of resource is `prevent_destroy` especially useful for?**
**A:** Resources that shouldn't be deleted by accident, like a database — losing it means losing data.

**Q: What does adding an attribute to `ignore_changes` do?**
**A:** Terraform stops trying to correct drift on that attribute, leaving external changes to it alone instead of reverting them.

**Q: What does `ignore_changes` accept?**
**A:** A list of attribute names, or the `all` keyword to ignore changes to every attribute on the resource.
