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
