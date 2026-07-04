# Output Variables in Terraform

This document explains **output variables** — how to expose values from your Terraform configuration (resource attributes, computed expressions) so they are visible after `apply`, usable by other configurations, or queryable on demand with `terraform output`.

---

## 1. The Problem: Values Locked Inside the State

**Input variables** (`var.*`) let you feed values **into** a configuration. **Resource attributes** (`random_pet.my_pet.id`) let one resource read values **out of** another. But neither makes a value easy for a **human** or **another configuration** to retrieve after `apply` finishes.

Once `terraform apply` completes, the generated pet name is stored in **state** — but it scrolls past in the terminal and is not easy to reuse:

```hcl
resource "random_pet" "my_pet" {
  prefix    = "Mr"
  separator = "-"
  length    = 2
}

resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = "My favorite pet is ${random_pet.my_pet.id}"
}
```

> **The gap:** After `apply`, how do you print the pet name on demand, or hand it to a script, a CI pipeline, or a separate Terraform configuration — without digging through `terraform.tfstate`?

**Output variables** close this gap. They declare which values matter enough to surface.

---

## 2. Declaring an Output

Outputs are declared with an **`output` block**, conventionally placed in a file named **`outputs.tf`**:

```hcl
output "pet-name" {
  value = random_pet.my_pet.id
}
```

| Part | Meaning |
| --- | --- |
| **`output`** | Block keyword |
| **`"pet-name"`** | Output **name** — your label, used to reference and display this output |
| **`value`** | **Required** argument — the expression whose result is exposed |

The **`value`** can be any valid expression: a resource attribute, a variable, a literal, or a combination of these inside a string.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    RP["random_pet.my_pet"]
    RP -->|"apply creates"| ATTR["attribute: id = mr-faithful-bull"]
    ATTR -->|"value = random_pet.my_pet.id"| OUT["output \"pet-name\""]
    OUT -->|"printed after apply"| CLI["terraform apply / terraform output"]

    style RP fill:#312e81,stroke:#a78bfa,color:#ffffff
    style ATTR fill:#14532d,stroke:#4ade80,color:#ffffff
    style OUT fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style CLI fill:#374151,stroke:#9ca3af,color:#ffffff
```

---

## 3. Viewing Outputs

### At the end of `terraform apply`

When a configuration contains one or more `output` blocks, Terraform prints their values **after** resources are created:

```text
random_pet.my_pet: Creating...
random_pet.my_pet: Creation complete after 0s [id=mr-faithful-bull]
local_file.pet: Creating...
local_file.pet: Creation complete after 0s [id=...]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

pet-name = "mr-faithful-bull"
```

### On demand with `terraform output`

You do not need to re-run `apply` to see outputs again. Terraform reads them straight from **state**:

```bash
terraform output
```

```text
pet-name = "mr-faithful-bull"
```

To print a **single** output value (useful in scripts):

```bash
terraform output pet-name
```

```text
"mr-faithful-bull"
```

| Command | Shows |
| --- | --- |
| `terraform apply` | All outputs, once, right after resources are created/updated |
| `terraform output` | All outputs, read from the current **state** file |
| `terraform output <name>` | Just that one output's value |

> **Outputs are read from state, not recomputed.** If you edit an `output` block's `value` expression but don't run `apply` or `refresh`, `terraform output` still reflects the last applied state.

---

## 4. Optional Arguments: `description` and `sensitive`

Beyond the required **`value`**, an `output` block supports optional metadata:

```hcl
output "pet-name" {
  value       = random_pet.my_pet.id
  description = "The randomly generated pet name used in pet.txt"
}
```

| Argument | Required? | Purpose |
| --- | --- | --- |
| **`value`** | Yes | The expression exposed as this output |
| **`description`** | No | Documents intent — shown in some tooling and generated docs |
| **`sensitive`** | No | When `true`, **redacts** the value from CLI output |

### Sensitive outputs

Mark an output **`sensitive = true`** when its value is a secret — a password, API key, or connection string:

```hcl
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
```

After `apply`, Terraform hides the value on screen:

```text
Outputs:

db_password = <sensitive>
```

> **Redaction is a display safeguard, not encryption.** The real value is still written in plaintext inside the **state file**. Protect state (remote backend, access controls) the same way you would protect any secret store.

You can still retrieve the actual value deliberately:

```bash
terraform output db_password
```

```text
"actual-secret-value"
```

---

## 5. Outputs vs Variables vs Attributes — Quick Comparison

| | **Input variable** (`var.*`) | **Resource attribute** | **Output** (`output` block) |
| --- | --- | --- | --- |
| **Direction** | Into the configuration | Out of one resource, into another | Out of the whole configuration |
| **Set by** | You (default, `.tfvars`, CLI, env) | Terraform, after resource is created | You declare it; Terraform fills the value |
| **Consumed by** | Resource arguments inside the config | Other resource arguments inside the config | Humans (`terraform output`), CI/CD, other Terraform configs |
| **Visible after apply?** | No | No (internal to state graph) | **Yes** — printed and queryable |

---

## 6. Hands-On Lab

In your configuration directory (with **`random_pet`** and **`local_file`** already defined from earlier lessons):

1. Create a new file **`outputs.tf`**.
2. Add an output that exposes the generated pet name:

   ```hcl
   output "pet-name" {
     value       = random_pet.my_pet.id
     description = "The randomly generated pet name"
   }
   ```
3. Run **`terraform apply`** — confirm **`pet-name`** is printed under **`Outputs:`** at the end.
4. Run **`terraform output`** without applying — confirm the same value is returned from state.
5. Run **`terraform output pet-name`** — confirm it prints just the value, without the `pet-name =` prefix formatting shown by `terraform output`.
6. Add **`sensitive = true`** to the block, run **`terraform apply`** again, and confirm the value is now shown as **`<sensitive>`**.
7. Run **`terraform output pet-name`** again — confirm the real value is still retrievable on demand even though it is redacted in the apply summary.

---

### Topic Summary: Output Variables

**Output variables** expose values from a Terraform configuration — most often resource attributes like `random_pet.my_pet.id` — so they are visible right after `apply` and queryable anytime with `terraform output`. Declare them in an `output` block (conventionally in `outputs.tf`) with a required `value` argument, plus optional `description` and `sensitive` arguments. Outputs are read from **state**, not recomputed on the fly, and marking one `sensitive` hides it from CLI display without encrypting it in the state file. Where input variables feed data **in** and resource attributes connect resources **to each other**, outputs surface data **out** of the whole configuration for humans, scripts, and other Terraform configurations to consume.

---

## Knowledge Check

Answer each question on your own first, then read the explanation below it.

---

### 1 · Purpose of outputs

**What problem do output variables solve that input variables and resource attributes don't?**

> Input variables feed values **into** a configuration, and resource attributes let one resource reference another's output. Neither makes a value easy to **retrieve after `apply`** for a human, script, or another configuration. **Output variables** solve this by explicitly exposing chosen values.

---

### 2 · Declaring an output

**What is the minimum required syntax for an `output` block?**

> An `output` block with a name and a **`value`** argument:
>
> ```hcl
> output "pet-name" {
>   value = random_pet.my_pet.id
> }
> ```
>
> `value` is the only required argument.

---

### 3 · Where outputs are conventionally placed

**What filename is conventionally used for output declarations?**

> **`outputs.tf`** — following the same convention as `variables.tf` for input variables and `main.tf` for resources.

---

### 4 · Viewing outputs

**How can you see an output's value without running `terraform apply` again?**

> Run **`terraform output`** to list all outputs, or **`terraform output <name>`** for a single one. Both read directly from the current **state** file — no re-apply needed.

---

### 5 · `sensitive` argument

**What does setting `sensitive = true` on an output actually do?**

> It **redacts the value from CLI display** — `terraform apply` and `terraform output` (without a name) show `<sensitive>` instead of the real value. It does **not** encrypt the value in the state file; the plaintext value is still stored there.

---

### 6 · Retrieving a sensitive output

**If an output is marked `sensitive`, can you still get its real value?**

> Yes — run **`terraform output <name>`** with the specific output name. It deliberately prints the real value even though the summary view hides it.

---

### 7 · Outputs and state

**Does changing an output block's `value` expression immediately change what `terraform output` shows?**

> **No.** Outputs are stored in and read from **state**. The new expression only takes effect after you run **`terraform apply`** (or `refresh`) so Terraform recomputes and saves the output value.

---

### 8 · Outputs vs resource attributes

**How does an output differ from a resource attribute like `random_pet.my_pet.id`?**

> A **resource attribute** is consumed **inside** the configuration — one resource block referencing another's output. An **output** exposes a value **outside** the configuration entirely, so it's visible to `terraform output`, CI/CD pipelines, and other Terraform configurations. An output's `value` is often just a resource attribute wrapped for external visibility.
