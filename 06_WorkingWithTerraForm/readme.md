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
