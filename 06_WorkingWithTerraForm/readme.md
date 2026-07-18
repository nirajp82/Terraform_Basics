# Chapter Summary: Working with Terraform

## 1. `terraform validate`

Checks HCL syntax and internal consistency without running `plan` or `apply`. On failure, it points to the exact line and argument causing the error.

## 2. `terraform fmt`

Rewrites `.tf` files in the current directory into canonical formatting. Cosmetic only — never changes behavior. Prints the names of files it changed.

## 3. `terraform show`

Prints the current state as Terraform's state file records it — not a fresh read of live infrastructure. Supports `-json` for structured output.

## 4. `terraform providers`

Lists the providers a configuration requires. The `mirror` subcommand copies provider plugins into another local directory.

## 5. `terraform output`

Prints declared output variables — all of them, or one by name (`terraform output <name>`).

## 6. `terraform refresh`

Performs the same state-reconciliation `plan`/`apply` already do automatically, but on demand and persisted to `terraform.tfstate` — without generating a plan. Never modifies real infrastructure, only state. The automatic refresh inside `plan`/`apply` can be skipped with `-refresh=false`.

## 7. `terraform graph`

Renders a configuration's dependency graph in DOT format, typically piped through Graphviz (`terraform graph | dot -Tsvg > graph.svg`) to produce a viewable image. Can run even before `terraform init`.

## 8. Mutable Infrastructure

The same server persists across an update; only its software and configuration change, via an in-place upgrade (manual, scripted, or config management tooling).

## 9. Configuration Drift

Partial upgrade failures across a pool of servers cause them to diverge from one another over time — some upgraded, some not — making the pool harder to plan around and troubleshoot.

## 10. Immutable Infrastructure

A resource is never updated in place. A new resource is provisioned with the desired change, and the old one is deleted only once the new one is confirmed working — so a failed update leaves the old resource untouched rather than half-upgraded.

## 11. Why Terraform Defaults to Immutable

Terraform destroys a resource and creates its replacement by default, rather than patching it in place (e.g. `local_file`'s `file_permission` or `content` changes). The old resource is destroyed first, then the new one is created — an order changeable via lifecycle rules, covered next.

## 12. The `lifecycle` Block

Goes directly inside a `resource` block to override Terraform's default destroy-then-create behavior for that resource.

## 13. `create_before_destroy`

On a forced replacement, creates the new resource before destroying the old one — reversing the default order.

## 14. `prevent_destroy`

Rejects any `apply` that would destroy the resource. Does not block `terraform destroy`, which still works — it only guards against accidental deletion via configuration changes.

## 15. `ignore_changes`

Takes a list of attribute names (or the `all` keyword) and stops Terraform from correcting drift on them — an external change to a listed attribute is left alone instead of reverted on the next `apply`.

---

## Knowledge Check Q&A

**Q: How do you check configuration syntax without running `plan` or `apply`?**
**A:** `terraform validate` — it checks syntax and internal consistency, pointing to the exact error line on failure.

**Q: Does `terraform fmt` change what a configuration does?**
**A:** No, only its formatting — canonical indentation and alignment, for readability.

**Q: Does `terraform show` read live infrastructure or the state file?**
**A:** The state file (`terraform.tfstate`) — what Terraform last recorded, not a fresh read of the real object.

**Q: What does `terraform providers mirror <path>` do?**
**A:** Copies the provider plugins a configuration needs into another local directory.

**Q: How do you print a single output variable instead of all of them?**
**A:** `terraform output <name>`.

**Q: Does `terraform refresh` modify real infrastructure?**
**A:** No — only the state file. It reconciles state with the real world and writes the result, without touching actual infrastructure.

**Q: Can `terraform graph` run before `terraform init`?**
**A:** Yes — it only needs the configuration files to exist.

**Q: Why pipe `terraform graph`'s output through Graphviz?**
**A:** The raw output is DOT format, a plain-text graph description language that's hard to read directly. Graphviz's `dot` command renders it as an actual image.

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
