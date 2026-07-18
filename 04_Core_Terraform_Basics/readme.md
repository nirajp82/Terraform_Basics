# Chapter Summary: Core Terraform Basics


## 1. Providers — What `terraform init` Does Internally

A resource type's prefix identifies its **provider**: `local_file` → `local`, `aws_instance` → `aws`. Running `terraform init` scans your `.tf` files, resolves the **source address** (e.g. `hashicorp/local`), downloads the signed provider binary from **`registry.terraform.io`** (the default public registry — private/self-hosted registries are also possible via a custom hostname), and stores it in the hidden `.terraform/providers/` folder. Init never touches real infrastructure and is always safe to re-run. Providers in the public registry are tiered as **Official** (HashiCorp), **Partner**, or **Community**.

## 2. Configuration Directory and File Naming

A **configuration directory** (root module) is the folder you run Terraform commands from. Terraform loads **every `*.tf` file directly inside that folder** and merges them into one configuration — file count doesn't matter, only total resource count affects plan/apply performance and memory. Subdirectories, parent folders, and sibling folders are **never** auto-loaded; a subfolder is only used via an explicit `module` block. `main.tf`, `variables.tf`, `outputs.tf`, and `providers.tf` are **industry-standard conventions**, not engine requirements — Terraform doesn't care whether code lives in one file or many.

**Memory at scale:** parsing `.tf` files is negligible RAM regardless of file count. What actually drives memory, time, and disk during `plan`/`apply` is **how many `resource` blocks are tracked in `terraform.tfstate`**. Crucially, `data` blocks (read-only lookups, e.g. `data "okta_user"`) do **not** persist in state run over run — only `resource` blocks (e.g. `cyberark_user`) do. In an Okta → CyberArk migration, 3 million Okta users read via `data` sources cost nothing long-term; 2–3 million `cyberark_user` **resources** are what push state into GB-scale and `plan`/`apply` into long, memory-heavy runs.

## 3. Multiple Providers and Resources

One configuration can freely mix resources from different providers, e.g. `local_file` (provider `local`) and `random_pet` (provider `random`). Adding a resource type from a new provider requires running `terraform init` again — previously installed providers are reused, only the new one is downloaded. The `random` provider is **logical** (generates values like `random_pet.my_pet.id`, no physical resource of its own); referencing that `id` from another resource (e.g. in `local_file` filename/content) creates an implicit dependency and ties both resources to the same generated value.

## 4. Input Variables

Hardcoded values in resource blocks limit reuse. **Input variables** are declared with a `variable` block (conventionally in `variables.tf`) and referenced with `var.<name>` — quotes are not needed around the reference. A variable must be **declared** before it can be assigned; `.tfvars` files, CLI flags, and environment variables only supply *values*, they never declare a variable. Variables can be used anywhere a value expression is valid (arguments, string templates, tags) but **not** as the resource type or resource name label, which must be literal strings. All `.tf` files in the same directory merge automatically — no `import` statement exists in Terraform.

## 5. The Variable Block and Types

A `variable` block supports three arguments: **`default`** (fallback value), **`type`** (validates shape), and **`description`** (docs). Omitting `type` implies **`any`**. Primitive types are `string`, `number`, `bool`. Composite types: **`list`** (ordered, indexed from `0`, duplicates allowed), **`set`** (like a list but no duplicates), **`map`** (key-value pairs, accessed with `var.name["key"]`), **`object`** (named fields of mixed types, accessed with dot notation), and **`tuple`** (fixed length, specific type per position). Type mismatches fail at `terraform plan`/`validate`, before anything is deployed.

## 6. Assigning Variable Values

Beyond `default`, variables can get values from an **interactive prompt** (if nothing else supplies one), **`-var`** on the CLI, **`TF_VAR_<name>`** environment variables, or **`.tfvars`** files. `terraform.tfvars` and any `*.auto.tfvars` file load automatically; custom-named `.tfvars` files require `-var-file`. When the same variable is set in multiple places, Terraform resolves it via a fixed **precedence ladder** (lowest → highest): `default` → `TF_VAR_*` → `terraform.tfvars` → `*.auto.tfvars` (alphabetical) → `-var`/`-var-file` on the CLI, which always wins.

## 7. Resource Attributes and Reference Expressions

**Arguments** are values you pass *into* a resource; **attributes** are values a resource exposes *after* it's created (documented under **Attribute Reference** in the Registry, e.g. `random_pet.my_pet.id`). Link resources with a **reference expression**: `<resource_type>.<resource_name>.<attribute>`. Inside a string, wrap it in **`${ ... }`** interpolation (optional when the whole argument value is just the reference). Referencing another resource's attribute creates an **implicit dependency** — no `depends_on` needed.

## 8. Resource Dependencies

When one resource references another's attribute, Terraform infers an **implicit dependency** and orders operations accordingly: **create** goes dependency → dependent, **destroy** reverses that to dependent → dependency. When ordering matters but no attribute reference exists in the arguments, use an **explicit dependency** with `depends_on = [resource.name]` inside the dependent block — reserved for indirect reliance not visible from the arguments themselves.

## 9. Output Variables

**Outputs** expose configuration values — usually resource attributes — so they're visible right after `apply` and retrievable anytime with `terraform output` (or `terraform output <name>` for a single value). Declared in an `output` block (conventionally `outputs.tf`) with a required **`value`**, plus optional **`description`** and **`sensitive`**. Outputs are read from **state**, not recomputed live. Marking an output `sensitive = true` redacts it from CLI display (`<sensitive>`) but does **not** encrypt it in the state file — the real value is still retrievable with `terraform output <name>`.

---

## Knowledge Check Q&A

**Q: How does Terraform know which provider a resource type belongs to?**
**A:** The prefix before the first underscore in the resource type — `local_file` → `local`, `aws_instance` → `aws`.

**Q: Does `terraform init` ever modify real infrastructure?**
**A:** No. It only downloads provider plugins and prepares the working directory — safe to re-run at any time.

**Q: If `main.tf` and `cat.tf` are both in the same folder, does Terraform load both automatically?**
**A:** Yes — every `.tf` file directly inside the configuration directory is merged into one configuration. Subfolders require an explicit `module` block to be loaded.

**Q: Why must you run `terraform init` again after adding a `random_pet` resource to a config that only used `local_file`?**
**A:** `random_pet` needs the `random` provider, which wasn't installed yet. Init detects the new requirement and downloads only that plugin — already-installed providers are reused.

**Q: Why must an input variable be declared before it can be assigned a value in `.tfvars`?**
**A:** `.tfvars` files (and CLI flags, env vars) only supply values to variables that already exist. Without a `variable "name" { ... }` block in some `.tf` file, Terraform reports an undeclared input variable error.

**Q: What type does a variable have if you omit the `type` argument?**
**A:** `any` — Terraform accepts any value shape with no validation.

**Q: If the same variable is set via `default`, `terraform.tfvars`, and a `-var` CLI flag, which value wins?**
**A:** The CLI `-var` flag — it sits at the top of the precedence ladder and overrides every other source.

**Q: What is the difference between a resource argument and a resource attribute?**
**A:** Arguments are inputs you set in the resource block. Attributes are outputs the resource exposes after it's created (like `id`) — read-only, documented under Attribute Reference.

**Q: When does Terraform create an implicit dependency between two resources?**
**A:** Whenever one resource's arguments reference another resource's attribute (e.g. `${random_pet.my_pet.id}`) — no `depends_on` is required in that case.

**Q: When should you use `depends_on` instead of a reference expression?**
**A:** Only when a real ordering dependency exists but isn't visible from any argument — e.g. indirect side effects. Prefer reference expressions whenever the dependency can be expressed that way.

**Q: Does marking an output `sensitive = true` encrypt its value in the state file?**
**A:** No. It only hides the value from CLI display (`<sensitive>`); the real value is still stored in plaintext in state and can be retrieved deliberately with `terraform output <name>`.
