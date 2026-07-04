# Assigning Values to Input Variables

This document covers every way to **supply values** to Terraform input variables — defaults, interactive prompts, CLI flags, environment variables, and **`.tfvars`** files — plus **variable definition precedence** when the same variable is set in more than one place.

---

## 1. Recap: Defaults Are Only One Option

In earlier lessons, variables were declared in **`variables.tf`** with a **`default`**:

```hcl
variable "filename" {
  type    = string
  default = "root/pet.txt"
}
```

That is **one** way to pass a value. The **`default`** argument is **optional** — when it is present and nothing else supplies a value, Terraform uses it automatically.

| Method | Where | Auto-loaded? |
| --- | --- | --- |
| **`default`** | `variables.tf` | Always part of the declaration |
| **Interactive prompt** | Terminal during `apply` / `plan` | When variable has **no** value from any source |
| **`-var`** | Command line | No — you pass it explicitly |
| **`TF_VAR_<name>`** | Shell environment | Yes — if exported before the command |
| **`terraform.tfvars`** | Project file | Yes — if file exists |
| **`*.auto.tfvars`** | Project file | Yes — all matching files |
| **Custom `.tfvars` + `-var-file`** | Any named file | No — requires `-var-file` |

You can use **any combination** of these. When the same variable is set in multiple places, Terraform picks one value using **precedence** (see §6).

> **Prerequisite:** Every method below only **assigns a value** to a variable that is **already declared** with a `variable "name" { ... }` block in a `.tf` file. If you use `var.filename` without a declaration — even with `.tfvars` present — Terraform errors. See **`04_Input_Variables.md` §2** (*Declare before assign*).

---

## 2. No Default → Interactive Prompt

If a variable has **no `default`** and **no value** from CLI, environment, or `.tfvars`, Terraform asks you at the terminal when you run **`terraform plan`** or **`terraform apply`**.

```hcl
# variables.tf — no default
variable "filename" {
  type = string
}

variable "content" {
  type = string
}
```

```hcl
# main.tf
resource "local_file" "pet" {
  filename = var.filename
  content  = var.content
}
```

```bash
terraform apply
```

```text
var.filename
  Enter a value: root/pet.txt

var.content
  Enter a value: I love pet!
```

| When interactive mode runs | When it does not |
| --- | --- |
| Variable has **no default** and **no external value** | A value is already supplied via `.tfvars`, `-var`, `TF_VAR_`, etc. |
| Useful for quick local tests | Awkward for CI/CD — pipelines need non-interactive inputs |

> **Rule:** Production and automation should **never rely on prompts**. Use `.tfvars`, environment variables, or `-var` instead.

---

## 3. Command-Line Flags: `-var`

Pass values directly on the Terraform command with **`-var`** using **`name=value`** syntax:

```bash
terraform apply -var="filename=root/pets.txt" -var="content=Hello from CLI"
```

| Detail | Example |
| --- | --- |
| One variable | `-var="filename=root/pets.txt"` |
| Multiple variables | Repeat **`-var`** for each name |
| Strings with spaces | Quote the whole assignment: `-var="content=I love pet!"` |
| Works with | `terraform plan`, `terraform apply`, `terraform destroy`, etc. |

```bash
terraform plan  -var="filename=root/pets.txt"
terraform apply -var="filename=root/pets.txt" -var="length=2"
```

**`-var`** is ideal for **one-off overrides** — testing a path, forcing a value in a pipeline step, or overriding a single setting without editing files.

---

## 4. Environment Variables: `TF_VAR_<name>`

Export an environment variable prefixed with **`TF_VAR_`** followed by the **exact variable name**:

```bash
# Linux / macOS / Git Bash
export TF_VAR_filename="/root/pets.txt"
export TF_VAR_length=2

terraform apply
```

```powershell
# Windows PowerShell
$env:TF_VAR_filename = "root/pets.txt"
$env:TF_VAR_length    = "2"

terraform apply
```

| Environment variable | Sets variable | Value |
| --- | --- | --- |
| `TF_VAR_filename` | `filename` | `"/root/pets.txt"` |
| `TF_VAR_length` | `length` | `2` |

> The prefix is always **`TF_VAR_`**. The part after the prefix must match the variable name in **`variables.tf`** — e.g. `TF_VAR_filename` → `variable "filename"`.

Environment variables are common in **CI/CD** (GitHub Actions, Jenkins, Azure DevOps) where secrets and per-run settings are injected without committing values to git.

---

## 5. Variable Definition Files (`.tfvars`)

When you manage **many variables**, put assignments in a **variable definition file** instead of repeating **`-var`** on every command.

### File naming rules

| Filename pattern | Auto-loaded? |
| --- | --- |
| **`terraform.tfvars`** | **Yes** |
| **`terraform.tfvars.json`** | **Yes** |
| **`<anything>.auto.tfvars`** | **Yes** — all such files, **alphabetical order** |
| **`<anything>.auto.tfvars.json`** | **Yes** — same rule |
| **Any other name** ending in `.tfvars` or `.tfvars.json` (e.g. `prod.tfvars`, `variable.tfvars`) | **No** — use **`-var-file`** |

### Syntax: assignments only

A `.tfvars` file uses **HCL assignment syntax** — **`name = value`** lines only. There is **no** `variable` keyword.

```hcl
# terraform.tfvars
filename = "root/pets.txt"
content  = "I love pet!"
length   = 2
```

```hcl
# variable.auto.tfvars  (auto-loaded because of .auto.tfvars suffix)
filename = "root/mypet.txt"
```

```hcl
# prod.tfvars  (NOT auto-loaded — custom name)
filename = "root/prod-pet.txt"
content  = "Production pet file"
```

Load a custom-named file explicitly:

```bash
terraform apply -var-file="prod.tfvars"
terraform plan  -var-file="variable.tfvars"
```

Multiple **`-var-file`** flags can be passed; later flags override earlier ones for the same variable.

### Auto-loaded vs manual `.tfvars`

This diagram shows **how files get loaded** — not override order. When the same variable appears in multiple sources, see **§6** for precedence.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    FILES["Variable definition files (.tfvars)"]
    FILES --> AUTO["Auto-loaded — no flag needed"]
    FILES --> MANUAL["Manual — pass -var-file"]

    AUTO --> A1["terraform.tfvars"]
    AUTO --> A2["*.auto.tfvars<br>all matching files, A→Z order"]

    MANUAL --> M1["Custom name e.g. prod.tfvars"]
    M1 --> CMD["terraform apply -var-file=prod.tfvars"]

    style FILES fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style AUTO fill:#14532d,stroke:#4ade80,color:#ffffff
    style MANUAL fill:#374151,stroke:#9ca3af,color:#ffffff
    style A1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style M1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style CMD fill:#312e81,stroke:#a78bfa,color:#ffffff
```

> **Important:** Never declare `variable "filename" { ... }` blocks inside `.tfvars` files. Declarations belong in **`variables.tf`**; `.tfvars` files only **assign** values.

---

## 6. Variable Definition Precedence

When the **same variable** receives values from **multiple sources**, Terraform does **not** pick at random. It loads sources in a fixed order. **Each later step replaces the value from the step before** if that step sets the variable.

### How to read the ladder

| Concept | Meaning |
| --- | --- |
| **Load order** | Terraform applies sources **top to bottom** in the diagram below |
| **Override** | If a step sets `filename`, it **replaces** whatever value the previous step left |
| **Winner** | The **last step that sets the variable** is the value used at **plan/apply** |
| **`default`** | Used only when **no higher step** supplies a value |

### Full precedence ladder (lowest → highest)

| Step | Source | Example `filename` | If next step also sets `filename` |
| --- | --- | --- | --- |
| 0 *(fallback)* | **`default` in `variables.tf`** | `root/default.txt` | Replaced by any step below |
| 1 | **`TF_VAR_<name>` environment variable** | `/root/cats.txt` | Replaced by steps 2–4 |
| 2 | **`terraform.tfvars`** | `/root/pets.txt` | Replaced by steps 3–4 |
| 3 | **`*.auto.tfvars`** *(A→Z; later files beat earlier in this group)* | `/root/mypet.txt` | Replaced by step 4 |
| 4 *(highest)* | **`-var` / `-var-file` on CLI** *(last flag wins if both set same variable)* | `/root/best-pet.txt` | **Final value — nothing overrides CLI** |

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    TITLE["Same variable set in many places — read top to bottom"]
    S0["Step 0 — default<br>root/default.txt<br>LOWEST priority"]
    S1["Step 1 — TF_VAR_filename<br>/root/cats.txt<br>overrides Step 0"]
    S2["Step 2 — terraform.tfvars<br>/root/pets.txt<br>overrides Step 1"]
    S3["Step 3 — variable.auto.tfvars<br>/root/mypet.txt<br>overrides Step 2"]
    S4["Step 4 — CLI -var / -var-file<br>/root/best-pet.txt<br>overrides Step 3 — HIGHEST"]
    WIN["Terraform uses this value at plan/apply<br>filename = /root/best-pet.txt"]

    TITLE --> S0
    S0 -->|"override"| S1
    S1 -->|"override"| S2
    S2 -->|"override"| S3
    S3 -->|"override"| S4
    S4 --> WIN

    style TITLE fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style S0 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S3 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S4 fill:#312e81,stroke:#a78bfa,color:#ffffff
    style WIN fill:#14532d,stroke:#4ade80,color:#ffffff
```

> **Skip steps that are missing.** If you have no `TF_VAR_` set, Terraform starts from `default` (if any), then applies `terraform.tfvars`, then `.auto.tfvars`, then CLI. Only **active** sources participate — but **order stays the same**.

### Worked example: which value wins?

**Configuration:**

```hcl
# main.tf
resource "local_file" "pet" {
  filename = var.filename
  content  = "I love pet!"
}
```

```hcl
# variables.tf — no default
variable "filename" {
  type = string
}
```

**Four different values for the same variable:**

| Source | How it is set | Value |
| --- | --- | --- |
| Environment | `export TF_VAR_filename="/root/cats.txt"` | `/root/cats.txt` |
| `terraform.tfvars` | `filename = "/root/pets.txt"` | `/root/pets.txt` |
| `variable.auto.tfvars` | `filename = "/root/mypet.txt"` | `/root/mypet.txt` |
| CLI | `terraform apply -var="filename=/root/best-pet.txt"` | `/root/best-pet.txt` |

**Winner:** **`/root/best-pet.txt`** — **Step 4 (CLI)** overrides every lower step.

**Walkthrough for this example:**

| After this source loads | Current `filename` value | Why |
| --- | --- | --- |
| Start (no default) | *(unset)* | No `default` in `variables.tf` |
| `TF_VAR_filename=/root/cats.txt` | `/root/cats.txt` | Step 1 sets it |
| `terraform.tfvars` adds `/root/pets.txt` | `/root/pets.txt` | Step 2 **overrides** Step 1 |
| `variable.auto.tfvars` adds `/root/mypet.txt` | `/root/mypet.txt` | Step 3 **overrides** Step 2 |
| `-var="filename=/root/best-pet.txt"` | **`/root/best-pet.txt`** | Step 4 **overrides** Step 3 — **final value** |

### Quick precedence cheat sheet

| Question | Answer |
| --- | --- |
| CLI vs `terraform.tfvars`? | **CLI wins** — Step 4 overrides Step 2 |
| `terraform.tfvars` vs `TF_VAR_`? | **`terraform.tfvars` wins** — Step 2 overrides Step 1 |
| `variable.auto.tfvars` vs `terraform.tfvars`? | **`.auto.tfvars` wins** — Step 3 overrides Step 2 |
| `-var` vs `-var-file` on same command? | **Last flag on the command line wins** — both are Step 4 |
| Nothing external, but has `default`? | **`default`** (Step 0) is used |
| Nothing at all? | **Interactive prompt** (or error in non-interactive mode) |

---

## 7. Hands-On Lab

In your configuration directory (same project as the Input Variables lesson — ensure every `var.*` reference is **declared** in `variables.tf` per **`04_Input_Variables.md` §2**):

1. Remove **`default`** from `variable "filename"` in `variables.tf`.
2. Run **`terraform apply`** — enter values at the prompts; confirm the file is created.
3. Set **`TF_VAR_filename`** in your shell and run **`terraform plan`** — confirm the plan uses the env value (no prompt).
4. Create **`terraform.tfvars`** with `filename = "root/from-tfvars.txt"` — run **`plan`** and confirm it overrides the env var.
5. Create **`variable.auto.tfvars`** with a different `filename` — confirm it overrides `terraform.tfvars`.
6. Run **`terraform apply -var="filename=root/from-cli.txt"`** — confirm the CLI value wins.
7. Create **`prod.tfvars`** (custom name) and run **`terraform plan -var-file=prod.tfvars`** — confirm values load only when the flag is passed.
8. Run **`terraform validate`** after each change to catch syntax errors in `.tfvars` files early.

---

### Topic Summary: Assigning Variable Values

Input variables can receive values from **`default`**, **interactive prompts**, **`-var`**, **`TF_VAR_<name>` environment variables**, and **`.tfvars`** files — but only after the variable is **declared** in a `.tf` file (see **`04_Input_Variables.md`**). Files named **`terraform.tfvars`** or ending in **`.auto.tfvars`** are **auto-loaded**; other `.tfvars` names require **`-var-file`**. When multiple sources set the same variable, Terraform applies **precedence**: environment variables load first, then **`terraform.tfvars`**, then **`*.auto.tfvars`** (alphabetical), and **`-var` / `-var-file`** on the CLI **win last**.

---

## Knowledge Check

Answer each question on your own first, then read the explanation below it.

---

### 1 · Interactive prompts

**What happens when you run `terraform apply` and a variable has no `default` and no value from `.tfvars`, `-var`, or `TF_VAR_`?**

> Terraform prompts you **interactively** in the terminal — one prompt per unset variable. This works for local learning but is awkward for CI/CD, where you should use `.tfvars`, env vars, or `-var` instead.

---

### 2 · CLI `-var`

**How do you pass a variable named `filename` on the command line?**

> Use **`-var="filename=root/pets.txt"`**. Repeat **`-var`** for each additional variable on the same command.

---

### 3 · Environment variables

**How do you set the variable `length` using an environment variable?**

> Export **`TF_VAR_length`** before running Terraform:
>
> - Bash: `export TF_VAR_length=2`  
> - PowerShell: `$env:TF_VAR_length = "2"`

---

### 4 · Auto-loaded files

**Which `.tfvars` files load automatically without a flag?**

> **`terraform.tfvars`**, **`terraform.tfvars.json`**, and any file ending in **`.auto.tfvars`** or **`.auto.tfvars.json`**.

---

### 5 · Custom `.tfvars` names

**How do you use a file named `prod.tfvars` or `variable.tfvars`?**

> Pass it explicitly with **`-var-file`**: `terraform apply -var-file="prod.tfvars"`. Custom names are **not** auto-loaded.

---

### 6 · Precedence winner

**In the worked example — env var, `terraform.tfvars`, `variable.auto.tfvars`, and `-var` all set `filename` — which value wins?**

> **`/root/best-pet.txt`** from the **`-var`** flag. CLI flags are **Step 4 (highest)** in the precedence ladder and override every lower source.

---

### 7 · Env vs `terraform.tfvars`

**Does `terraform.tfvars` override `TF_VAR_filename`?**

> **Yes.** `terraform.tfvars` loads **after** environment variables, so its value replaces the env var unless a higher-priority source (`.auto.tfvars` or CLI) overrides it again.

---

### 8 · `.tfvars` syntax

**What syntax belongs in a `.tfvars` file?**

> **Assignments only** — `name = value` lines in HCL. No `variable` blocks. Declarations belong in a `.tf` file — see **`04_Input_Variables.md` §2**.

