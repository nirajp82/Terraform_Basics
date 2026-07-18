# Chapter Summary: Terraform State

## 1. State Before Any Apply

Before the first `terraform apply`, no resource exists — not in the real world, not in any tracking file. `terraform plan` tries to refresh state in-memory, finds none, and plans a **create** for every resource in the configuration.

## 2. State Is Born on First Apply

The first `terraform apply` creates the resource **and** a new file, **`terraform.tfstate`**, in the configuration directory. This file is never created by `plan` alone — only `apply` writes it.

## 3. What the State File Contains

`terraform.tfstate` is a **JSON data structure** mapping configuration resources to real-world infrastructure. For each resource it records the **type**, **logical name**, **provider**, unique **ID**, and every **attribute** (e.g., `filename`, `content`).

## 4. State Is the Source of Truth

Every subsequent `plan` or `apply` refreshes state first, then compares it against the configuration:

| Comparison result | Terraform's action |
| --- | --- |
| Config matches state | No changes |
| Config argument differs from state | Depends on the resource: destroy + recreate for a force-new argument (all of `local_file`'s arguments qualify), or update in-place for resources/arguments that support it |
| Resource in config, not in state | Create |

> `local_file` (used throughout this lesson) destroys and recreates on **any** argument change, because the provider only implements create and delete — no in-place update at all. That's specific to `local_file`; many other resource types support genuine in-place updates for most arguments.

## 5. State Is Always Created

Regardless of how many resources or providers a configuration uses, Terraform **always** creates and maintains a state file after `apply`. It is not an optional feature.

## 6. State Is a Blueprint of Everything Terraform Manages

Every resource Terraform creates gets a unique ID recorded in state — including **logical** resources like `random_pet` that never touch disk or a cloud API, not just resources with a real-world footprint.

## 7. State Tracks Dependency Metadata

Beyond mapping resources to reality, state also records **resource dependencies** (implicit and explicit). This matters most when resources are **removed from configuration**: the reference expression that originally declared the dependency is gone, but state still remembers it, so Terraform can still destroy dependents before dependencies.

## 8. State Improves Performance

Refreshing state means asking every provider to re-read every tracked resource — impractical at the scale of hundreds or thousands of resources. Terraform treats state as a **cache of attribute values** it can trust without reconciling; the **`-refresh=false`** flag skips reconciliation entirely and compares configuration directly against cached state.

## 9. State Enables Team Collaboration

A local `terraform.tfstate` file works for solo use but breaks down for teams — everyone needs the latest state, and no two people can run Terraform concurrently against it, or the result is unpredictable errors. The fix is a **remote state store** (Amazon S3, HashiCorp Consul, Terraform Cloud) shared securely across the team.

---

## Knowledge Check Q&A

**Q: Why doesn't the first `terraform plan` in a brand-new configuration directory show any state details?**
**A:** Because `terraform.tfstate` doesn't exist yet. With no state to refresh, Terraform assumes nothing is provisioned and plans a create for every resource.

**Q: What command actually creates the `terraform.tfstate` file?**
**A:** `terraform apply`. Running `terraform plan` alone never writes state — it only reads and compares.

**Q: What format is the state file, and what does it store?**
**A:** It's a JSON data structure. It stores each resource's type, logical name, provider, unique ID, and full set of attributes.

**Q: If you run `terraform apply` twice with no config changes, why does the second run report no changes?**
**A:** Terraform refreshes state, finds the resource already recorded with matching attributes and ID, and takes no action since config and state agree.

**Q: What happens if a resource argument in your `.tf` file no longer matches what's recorded in state?**
**A:** Terraform plans to destroy the existing resource and create a new one (a replace), then updates the state file with the new resource's ID and attributes.

**Q: Is a state file optional for small configurations with just one or two resources?**
**A:** No. Terraform always creates and relies on a state file after `apply`, no matter how small the configuration is — it's fundamental to how Terraform tracks infrastructure.

**Q: Does a logical resource like `random_pet` get a unique ID recorded in state, even though it doesn't create anything in the real world?**
**A:** Yes. State tracks every resource Terraform manages, regardless of whether it has a real-world footprint.

**Q: If you delete a resource and its dependency from your `.tf` files, how does Terraform know which one to destroy first?**
**A:** From the dependency metadata already recorded in state when the resources were created — that metadata persists even after the configuration lines that declared it are gone.

**Q: Why doesn't Terraform refresh state against the real world before every single command on large infrastructures?**
**A:** Reconciling hundreds or thousands of resources across multiple providers can take seconds to minutes. Terraform instead treats state as a cache it can trust, and `-refresh=false` skips reconciliation entirely.

**Q: Why is a local `terraform.tfstate` file a problem for teams?**
**A:** Every member needs the latest state, and no two people can safely run Terraform at the same time against it — violating either causes unpredictable errors. Teams should use a remote state store like S3, Consul, or Terraform Cloud instead.
