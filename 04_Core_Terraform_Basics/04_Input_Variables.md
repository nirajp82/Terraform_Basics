# Input Variables in Terraform

This document explains why **hardcoded values** limit reusable Infrastructure as Code, how to declare **input variables** in `variables.tf`, reference them with **`var.`** in `main.tf`, and update infrastructure by changing variables alone — without editing resource blocks.

---

## 1. The Problem with Hardcoded Values

So far, argument values were written directly inside resource blocks:

```hcl
resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = "I love pet!"
}

resource "random_pet" "my_pet" {
  prefix    = "dog"
  separator = "-"
  length    = 2
}
```

These are **hardcoded values** — fixed strings and numbers baked into `main.tf`.

| Hardcoding | Why it hurts IaC |
| --- | --- |
| Same code, different environments | You must edit `main.tf` for dev vs. prod |
| Reuse across teams/projects | Copy-paste and manual edits increase errors |
| Change content or settings | Resource blocks become cluttered with literals |

> **Goal of IaC:** Write configuration **once**, deploy many times with different **inputs** — not by rewriting resource definitions every time.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    BAD["Hardcoded main.tf"] --> EDIT["Edit resource blocks for every change"]
    GOOD["main.tf + variables.tf"] --> VARS["Change input variables only"]
    VARS --> REUSE["Same code, different values"]

    style BAD fill:#713f12,stroke:#fbbf24,color:#ffffff
    style EDIT fill:#713f12,stroke:#fbbf24,color:#ffffff
    style GOOD fill:#14532d,stroke:#4ade80,color:#ffffff
    style VARS fill:#374151,stroke:#9ca3af,color:#ffffff
    style REUSE fill:#14532d,stroke:#4ade80,color:#ffffff
```

---

## 2. Declaring Variables in `variables.tf`

Input variables work like variables in Bash, PowerShell, or other languages — they hold values you pass into your configuration.

**Industry practice:** declare variables in a dedicated **`variables.tf`** file (merged automatically with `main.tf` in the same configuration directory).

```hcl
variable "filename" {
  default = "root/pet.txt"
}

variable "content" {
  default = "I love pet!"
}

variable "prefix" {
  default = "dog"
}

variable "separator" {
  default = "-"
}

variable "length" {
  default = 2
}
```

### Anatomy of a `variable` block

| Part | Example | Meaning |
| --- | --- | --- |
| Block type | `variable` | Fixed Terraform keyword |
| Variable name | `"filename"` | Your chosen name — use something descriptive (often matching the argument it replaces) |
| `default` | `"root/pet.txt"` | **Optional** — value used when no other input is supplied |

> **Naming tip:** If a variable replaces the `content` argument, naming it `content` keeps the configuration easy to read.

Terraform merges `variables.tf` and `main.tf` into **one configuration** — no import or link statement is required.

---

## 3. Using Variables in `main.tf` with `var.`

Replace hardcoded argument values with **`var.<variable_name>`**:

```hcl
resource "random_pet" "my_pet" {
  prefix    = var.prefix
  separator = var.separator
  length    = var.length
}

resource "local_file" "pet" {
  filename = var.filename
  content  = var.content
}
```

### Reference syntax

```text
var.content
│   │
│   └── variable name declared in variables.tf
└── required prefix for all input variables
```

| When writing… | Quotes needed? | Example |
| --- | --- | --- |
| **Literal string** in `main.tf` | **Yes** | `content = "I love pet!"` |
| **Variable reference** | **No** | `content = var.content` |

Terraform already knows `var.content` is a string (or number) from the variable definition — wrapping it in `"${var.content}"` is unnecessary for simple references.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    VTF["variables.tf — declares defaults"]
    MAIN["main.tf — resource blocks"]
    VTF -->|"var.filename, var.content, ..."| MAIN
    MAIN --> PLAN["terraform plan / apply"]

    style VTF fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style MAIN fill:#374151,stroke:#9ca3af,color:#ffffff
    style PLAN fill:#14532d,stroke:#4ade80,color:#ffffff
```

### Configuration directory layout

```text
my-terraform-project/
├── main.tf         ← resources use var.*
├── variables.tf    ← input variables and defaults
└── ...
```

---

## 4. First Deploy: Plan and Apply

The workflow is unchanged — variables only replace literals:

```bash
terraform plan
terraform apply
```

Resources are created using **default values** from `variables.tf`. No extra flags are required when defaults are set.

| Resource | Arguments now sourced from |
| --- | --- |
| `local_file.pet` | `var.filename`, `var.content` |
| `random_pet.my_pet` | `var.prefix`, `var.separator`, `var.length` |

---

## 5. Updating Infrastructure by Changing Variables Only

A major benefit: you can change behavior **without editing `main.tf`**.

### Example update — change `variables.tf` only

**Before:**

```hcl
variable "content" {
  default = "I love pet!"
}

variable "length" {
  default = 1
}
```

**After:**

```hcl
variable "content" {
  default = "My favorite pet is Mrs. hiskers"
}

variable "length" {
  default = 2
}
```

`main.tf` stays exactly the same:

```hcl
resource "local_file" "pet" {
  filename = var.filename
  content  = var.content
}

resource "random_pet" "my_pet" {
  prefix    = var.prefix
  separator = var.separator
  length    = var.length
}
```

Run:

```bash
terraform apply
```

| Change in `variables.tf` | Effect after apply |
| --- | --- |
| `content` updated | `local_file.pet` — **updated in-place** (file text changes) |
| `length` changed from `1` to `2` | `random_pet.my_pet` — **replaced** (new random name with two words after prefix) |

```text
random_pet.my_pet: Destroying... [id=dog-coral]
random_pet.my_pet: Creation complete [id=dog-delicate-wallaby]
local_file.pet: Modifying...
local_file.pet: Modifications complete

Apply complete! Resources: 1 added, 1 changed, 1 destroyed.
```

> When a **force-new** argument like `random_pet.length` changes, Terraform **destroys and recreates** that resource. Updating `local_file.content` typically **updates** the existing file without recreating the resource address.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    EDIT["Edit variables.tf only"]
    EDIT --> APPLY["terraform apply"]
    APPLY --> LOCAL["local_file — content updated"]
    APPLY --> RANDOM["random_pet — recreated if length changed"]

    style EDIT fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style APPLY fill:#374151,stroke:#9ca3af,color:#ffffff
    style LOCAL fill:#14532d,stroke:#4ade80,color:#ffffff
    style RANDOM fill:#312e81,stroke:#a78bfa,color:#ffffff
```

---

## 6. Preview: Variables with AWS EC2

Later in the course you will provision real cloud resources. The same variable pattern applies — only the resource type changes.

```hcl
# variables.tf
variable "ami_id" {
  default = "ami-0c2f25c1f66a1ff4d"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_name" {
  default = "webserver"
}
```

```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
```

| Concept | Local lab | AWS (later) |
| --- | --- | --- |
| Declare inputs | `variables.tf` | `variables.tf` |
| Reference in resources | `var.content` | `var.instance_type` |
| Change without editing resources | Update defaults in `variables.tf` | Same |

Do not worry if `aws_instance` arguments are unfamiliar — a dedicated AWS lecture covers them later. The **variable mechanics are identical**.

---

## 7. Other Ways to Set Variable Values (Preview)

This lecture uses **`default`** inside `variable` blocks. Later sections cover:

| Method | When used |
| --- | --- |
| **`default` in `variables.tf`** | This lecture — simplest for learning |
| **`.tfvars` files** | Environment-specific value files |
| **CLI flags** | `-var="content=Hello"` at apply time |
| **Environment variables** | `TF_VAR_content=Hello` in CI/CD |

---

## 8. Hands-On Lab

In your configuration directory:

1. Create `variables.tf` with variables for `filename`, `content`, `prefix`, `separator`, and `length`.
2. Update `main.tf` to use `var.*` instead of hardcoded values.
3. Run `terraform plan` and `terraform apply` — confirm resources are created.
4. Change only `content` and `length` in `variables.tf`.
5. Run `terraform apply` again — confirm file content updates and pet name regenerates.
6. Confirm `main.tf` was **never modified** after step 2.

---

### Topic Summary: Input Variables

Hardcoded values in resource blocks limit reuse. **Input variables** declared in **`variables.tf`** with optional **`default`** values let you parameterize configuration. Reference them in `main.tf` as **`var.<name>`** without extra quotes. Terraform merges all `.tf` files in the directory, so `variables.tf` and `main.tf` work together automatically. To change infrastructure behavior, update **`variables.tf`** and run **`terraform apply`** — resource blocks in `main.tf` stay stable. Other ways to supply values (`.tfvars`, CLI, env vars) are covered later.

### Knowledge Check Q&A

**Q: Why is hardcoding argument values in `main.tf` a bad practice for IaC?**

**A:** It limits **reusability** — the same code cannot be easily redeployed with different settings. You must edit resource blocks instead of supplying new inputs, which defeats the purpose of parameterized Infrastructure as Code.

**Q: Which file is commonly used to declare input variables?**

**A:** **`variables.tf`** — an industry convention in the same configuration directory as `main.tf`. Terraform automatically merges it with other `.tf` files.

**Q: How do you reference an input variable named `content` in a resource block?**

**A:** Use **`var.content`**. The `var.` prefix tells Terraform to read the input variable value.

**Q: Do you need double quotes around `var.content` when assigning it to an argument?**

**A:** **No.** For a direct variable reference, write `content = var.content`. Quotes are for literal strings, not variable references.

**Q: What does the `default` argument inside a `variable` block do?**

**A:** It sets the value Terraform uses when **no other input** is provided (no CLI flag, `.tfvars`, or environment variable). It is optional but convenient for learning and sensible fallbacks.

**Q: If you change a value in `variables.tf`, must you also edit `main.tf`?**

**A:** **No.** That is the point of variables — update `variables.tf` (or other input sources later), run `terraform apply`, and Terraform updates resources based on the new values while `main.tf` resource structure stays the same.

**Q: What happens if you change `random_pet.length` from `1` to `2` in `variables.tf` and run apply?**

**A:** Terraform detects a change to a **force-new** argument. It **destroys and recreates** `random_pet.my_pet` with a new random name containing two words after the prefix.

**Q: What block type and keyword do you use to declare an input variable?**

**A:** A **`variable`** block: `variable "name" { default = "value" }`.
