# Terraform State

This document explains **Terraform state** — the `terraform.tfstate` file Terraform creates behind the scenes, *why* Terraform needs it at all, and how it drives every `terraform plan` and `terraform apply` you run. The hands-on walkthrough uses the same `local_file`/`random_pet` resources as the rest of this course (Section 2a maps the same mechanics onto AWS EC2 + RDS PostgreSQL for intuition).

---

## 1. Recap: Where We Left Off

By now you know how to write configuration files with HCL, declare and use **variables**, use **reference expressions**, and link resources together with **dependencies**. All of that happens inside a configuration directory — for example, `terraform-local-file` — containing:

- **`main.tf`** — the resource block(s)
- **`variables.tf`** — the variable declarations used by `main.tf`

At this point, before running anything, the `local_file` resource described in `main.tf` does not exist anywhere — not in the directory, not in the "real world."

```hcl
resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = "I love pets!"
}
```

---

## 2. Why Terraform Needs a State File

Before walking through the demo, it helps to understand the problem state actually solves.

Imagine, for a moment, that your configuration declared an **AWS EC2 instance** instead of a local file. You run `terraform apply` once, it boots the instance, and a week later you run `terraform plan` again with no changes to your `.tf` files. How does Terraform know that instance is already running, instead of launching a duplicate? AWS doesn't tag it "created by my `aws_instance.web` block" — that label only exists in your configuration, not on the instance itself. Terraform has to keep its own record somewhere. That record is **state**, and this lesson explains it with a small, runnable example (`local_file`) before mapping the same idea onto EC2-style infrastructure in Section 2a.

Terraform's job, every time you run `plan` or `apply`, is to answer one question: **"What do I need to change to make reality match my configuration?"** To answer that, Terraform needs three pieces of information — and only has two of them for free:

| Source | Answers | File / extension | Written by |
| --- | --- | --- | --- |
| **Configuration** | What do you *want*? (desired state) | `main.tf`, `variables.tf` — **`.tf`** files | You |
| **Real-world infrastructure** | What actually exists *right now*? | e.g. the real file at `root/pet.txt` — no Terraform file at all, it's just the object itself | The provider (disk, cloud API, etc.) |
| **State** | What did Terraform *itself* create, with which ID and attributes? | `terraform.tfstate` — the **`.tfstate`** file | Terraform |

Configuration alone can't tell Terraform whether a resource already exists — every `plan` would look like a fresh `create`. And the real world alone isn't reliable either: most resource types have no built-in, guaranteed-unique way to match "the thing sitting in the cloud" back to "the resource block in my `.tf` file." A `local_file` resource, for instance, doesn't expose anything that says "I was created by Terraform's `local_file.pet` block."

So Terraform keeps its **own persistent record** — the state file — as the map between *"this resource block in my configuration"* and *"this specific object Terraform created."*

Here's the part that's easy to miss: **configuration is never compared to the real world directly.** Every `plan` and `apply` follows the same two-step sequence, in this exact order:

1. **Refresh** — Terraform asks the provider to **Read** the real-world object (the actual `root/pet.txt` file) for every resource already recorded in `terraform.tfstate`, and updates its **in-memory copy of that `.tfstate` data** to match what it just read. Real-world data only ever enters the picture *through* this step, flowing *into* the `.tfstate` copy.
2. **Compare** — Terraform compares your **`.tf` configuration** against that freshly-refreshed **`.tfstate` data** — not against `root/pet.txt` itself — to decide what to create, update, replace, or leave alone.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    REAL["root/pet.txt<br>(the real file — no Terraform extension,<br>just the actual object)"]
    REAL -->|"Step 1: refresh<br>provider Reads the real file"| STATE["terraform.tfstate<br>(.tfstate — in-memory copy,<br>now matches root/pet.txt)"]
    CONFIG["main.tf<br>(.tf — what you want)"]
    STATE -->|"Step 2: compare"| DECISION["plan / apply decision:<br>create / update / replace / no-op"]
    CONFIG -->|"Step 2: compare"| DECISION

    style REAL fill:#374151,stroke:#9ca3af,color:#ffffff
    style STATE fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style CONFIG fill:#374151,stroke:#9ca3af,color:#ffffff
    style DECISION fill:#312e81,stroke:#a78bfa,color:#ffffff
```

> **Rule to remember:** Terraform never compares `main.tf` straight against `root/pet.txt`. Real-world data only reaches Terraform by being **refreshed into `terraform.tfstate`** first (step 1); your **`.tf`** configuration is then compared only against that refreshed **`.tfstate`** data (step 2). That's what "state sits between configuration and the real world" means — it's a strict two-step pipeline, not a three-way free-for-all.

---

## 2a. Same Model, Real Infrastructure — EC2 + RDS PostgreSQL

> This section is **illustrative only** — it maps the mechanics above onto realistic cloud resources so the model isn't tied to a toy example. The rest of this lesson (and its hands-on lab) continues with `local_file`/`random_pet`, matching the actual course, because it's runnable without an AWS account.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"
}

resource "aws_db_instance" "app_db" {
  identifier        = "app-db"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "app_user"
  password          = var.db_password
}
```

The exact same three sources, and the exact same refresh-then-compare pipeline, apply — only the artifacts change:

| Role | This lesson's demo | EC2 + RDS equivalent |
| --- | --- | --- |
| **`.tf` configuration** | `main.tf` declaring `local_file.pet` | `main.tf` declaring `aws_instance.web` and `aws_db_instance.app_db` |
| **Real-world object** | The actual `root/pet.txt` file on disk | The actual EC2 instance and RDS database running in your AWS account |
| **`.tfstate` record** | `terraform.tfstate` with `local_file.pet`'s `id` (a content hash) | `terraform.tfstate` with `aws_instance.web`'s `id` (e.g. `i-0abcd1234efgh5678`) and `aws_db_instance.app_db`'s `id` |

**Drift, made concrete:** suppose someone terminates `aws_instance.web` by hand in the AWS Console — a change made completely outside Terraform. The next `terraform plan` still follows the same two steps: **(1) refresh** — Terraform asks AWS to Read that instance ID and gets back "not found," so the in-memory `.tfstate` copy is updated to show it's gone; **(2) compare** — `main.tf` still declares `aws_instance.web` should exist, but the refreshed state now shows it doesn't. The plan reports the instance must be **created** — not "no changes" — exactly the same logic that caught the `content` mismatch for `local_file.pet` in Section 7, just triggered by someone acting outside Terraform instead of a config edit.

**Force-new isn't universal, either:** unlike `local_file` (where *every* argument is force-new, per `07_Resource_Attributes_and_References.md`), `aws_instance` supports genuine in-place updates for some arguments — e.g., changing `instance_type` can often be applied without replacement — while others, like `ami`, force replacement because the AMI is baked in at launch. The state file is what lets Terraform know, argument by argument, which kind of change it's looking at.

---

## 2b. How Refresh Actually Checks "Is It Still There?"

It's fair to ask: concretely, *how* does Terraform check whether an EC2 instance created six months ago still exists? It doesn't guess, and it doesn't search by name or tags. It looks up **one specific ID** — the same `id` that got recorded in state the moment the resource was created.

**Step by step:**

1. **At creation**, the AWS API call Terraform's provider makes to launch the instance (`RunInstances`, under the hood) returns a response that includes AWS's own generated **instance ID** — e.g. `i-0abcd1234efgh5678`. Terraform writes that exact ID into `terraform.tfstate` as the resource's `id` attribute. From this point on, that ID *is* the resource's identity as far as Terraform is concerned.
2. **On every later `refresh`**, Terraform reads that stored ID back out of state and calls the provider's **Read** operation for it — for EC2 this is a `DescribeInstances` API call filtered to that exact instance ID, not a scan of "all instances that look like `aws_instance.web`."
3. **Two possible answers come back:**
   - **Found** — AWS returns the instance's current attributes (state, IP, tags, etc.). Terraform copies those into its in-memory state, and the resource is confirmed to still exist.
   - **Not found** (AWS returns an error like `InvalidInstanceID.NotFound`) — Terraform concludes the instance no longer exists. It removes that resource from the refreshed state.
4. **Then the compare step runs as always:** `main.tf` still says `aws_instance.web` should exist; refreshed state now says it doesn't (case 3b) or confirms it does with current attributes (case 3a). A "not found" result is exactly what turns into the **create** plan described in Section 2a's drift example.

**Two details that are easy to get backwards:**

- **Refresh is one call, not one call per argument.** The Read/Describe API call returns the resource's **entire current attribute set** in a single response — `ami`, `instance_type`, IP addresses, tags, everything at once. Terraform isn't asking "does `instance_type` still say `t3.micro`?" as a separate question per argument; it gets the whole object back and updates every attribute in its in-memory copy at once.
- **Refresh always runs first, unconditionally — it is never triggered *because* a diff was found.** Terraform has no way to know there's a difference until *after* it refreshes. The order is always: refresh (unconditional) → *then* compare (which is what discovers whether there's a diff at all). "If there's a diff, refresh" has the causality backwards.

> **The ID is the whole trick.** Terraform never re-derives "which real object is mine" from scratch — it stores the provider-assigned ID once, at creation, and from then on every check is a direct lookup by that ID. `random_pet`, `local_file`, `aws_instance`, `aws_db_instance` — every resource type follows this same pattern, only the specific "describe by ID" API call changes per provider.

---

## 3. `terraform plan` Before Any State Exists

Running `terraform plan` for the first time starts by trying to **refresh state in-memory**. "Refreshing" means Terraform asks the provider to re-**Read** every resource currently recorded in state, so its in-memory copy reflects reality before it compares anything to your configuration.

Since this is the very first run, **there is no state recorded at all** — nothing to refresh. Terraform prints nothing related to a state refresh, because there's nothing to look up. From that absence, Terraform concludes that **no resources are currently provisioned**, and builds an execution plan of **create**:

```diff
  # local_file.pet will be created
  + resource "local_file" "pet" {
      + content              = "I love pets!"
      + filename             = "root/pet.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

> **No state recorded yet means no resources exist yet — in Terraform's eyes.** Terraform never assumes; it only knows about infrastructure that appears in its state.

**What `plan` does *not* do:** it never writes `terraform.tfstate` and never touches real infrastructure. It only reads (refreshes), compares, and reports.

---

## 4. `terraform apply` Creates the Resource — and the State File

Running `terraform apply` follows the same first step: try to refresh in-memory state, find none, and proceed with the **create** plan. Once you confirm, Terraform creates the `local_file` resource and assigns it a **unique ID**:

```text
local_file.pet: Creating...
local_file.pet: Creation complete after 0s [id=3fecf3d1e9a5a1226e6ac539ef1103f22e67e04b]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

The file is created on disk with the expected content. But something else also appears in the configuration directory: a new file called **`terraform.tfstate`**.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    INIT["terraform init<br>downloads provider plugins"] --> PLAN["terraform plan<br>refreshes in-memory state — none found"]
    PLAN --> APPLY["terraform apply<br>creates local_file.pet"]
    APPLY --> STATE["terraform.tfstate created"]

    style INIT fill:#374151,stroke:#9ca3af,color:#ffffff
    style PLAN fill:#374151,stroke:#9ca3af,color:#ffffff
    style APPLY fill:#312e81,stroke:#a78bfa,color:#ffffff
    style STATE fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
```

> **`terraform.tfstate` is not created until `terraform apply` runs at least once.** `terraform plan` alone never writes a state file — it only reads and compares.

---

## 5. Running `apply` Again — the Three-Way Compare in Action

Run `terraform apply` a second time, with no configuration changes:

```text
local_file.pet: Refreshing state... [id=3fecf3d1e9a5a1226e6ac539ef1103f22e67e04b]

No changes. Infrastructure is up-to-date.
```

Walk through what just happened, using the same three sources from Section 2:

| Source | What it says |
| --- | --- |
| **Configuration** | `content = "I love pets!"`, `filename = "root/pet.txt"` |
| **State** | Resource `local_file.pet` exists, `id = 3fecf3d1e...`, same `content`/`filename` |
| **Real world** (after refresh) | The actual file on disk still has that same content |

All three agree — so Terraform recognizes that the resource named `pet`, with the **same ID** already seen, exists exactly as configured, and takes **no further action**.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    APPLY2["terraform apply — run again"] --> CHECK{"State (refreshed against real world)<br>matches configuration?"}
    CHECK -->|"Yes"| NOOP["No changes — nothing to do"]

    style APPLY2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style CHECK fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style NOOP fill:#14532d,stroke:#4ade80,color:#ffffff
```

---

## 6. Inside `terraform.tfstate`

The **state file** is a **JSON data structure** that maps real-world infrastructure resources to the resource definitions in your configuration files. It holds the complete record of everything Terraform has created.

For the single `local_file.pet` resource, the state file records:

```json
{
  "version": 4,
  "terraform_version": "1.x.x",
  "resources": [
    {
      "mode": "managed",
      "type": "local_file",
      "name": "pet",
      "provider": "provider[\"registry.terraform.io/hashicorp/local\"]",
      "instances": [
        {
          "attributes": {
            "filename": "root/pet.txt",
            "content": "I love pets!",
            "id": "3fecf3d1e9a5a1226e6ac539ef1103f22e67e04b"
          }
        }
      ]
    }
  ]
}
```

| Part | What is it? |
| --- | --- |
| **`mode`** | `"managed"` means Terraform owns the full lifecycle of this resource (as opposed to a read-only data source) |
| **`type`** | The resource type, e.g. `local_file` |
| **`name`** | The resource's logical name from the config, e.g. `pet` |
| **`provider`** | Which provider manages this resource |
| **`instances[].attributes`** | Every resource attribute — arguments you set plus computed values like `id` |

> Terraform uses this file as the **single source of truth** for `terraform plan` and `terraform apply` — not just a log of what happened, but the record Terraform trusts over everything else, including the real-world infrastructure itself.

---

## 7. Changing the Configuration — Config vs. State vs. Reality

Now update `main.tf` so the `content` argument changes:

```hcl
resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = "We love pets!"
}
```

Rerun `terraform plan` or `terraform apply`. Terraform again refreshes state, then compares all three sources:

| Source | `content` value |
| --- | --- |
| **Configuration** (what you want) | `"We love pets!"` |
| **State** (what Terraform last recorded) | `"I love pets!"` |
| **Real world** (refreshed — the actual file on disk) | `"I love pets!"` |

Configuration disagrees with state (and reality). That mismatch is exactly what Terraform is designed to detect — the repo-wide term for this is **drift**: a difference between what's declared and what's actually recorded/deployed.

```diff
  # local_file.pet must be replaced
-/+ resource "local_file" "pet" {
      ~ content              = "I love pets!" -> "We love pets!" # forces replacement
      ~ id                   = "3fecf3d1e9a5a1226e6ac539ef1103f22e67e04b" -> (known after apply)
        filename             = "root/pet.txt"
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

Terraform decides the resource must be **destroyed and recreated** (recall from `07_Resource_Attributes_and_References.md` that `local_file`'s arguments are all force-new — there is no in-place update path). Running `apply` updates both the real file and the state file:

```text
local_file.pet: Destroying... [id=3fecf3d1e9a5a1226e6ac539ef1103f22e67e04b]
local_file.pet: Destruction complete after 0s
local_file.pet: Creating...
local_file.pet: Creation complete after 0s [id=8a2f0e9d4b7c6a1f3e5d9c8b7a6f5e4d3c2b1a09]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

The older resource ID is gone from `terraform.tfstate`; a new entry records the replaced resource's new ID and updated `content`.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    CONFIG["Config: content = \"We love pets!\""]
    STATEBOX["State: content = \"I love pets!\""]
    CONFIG --> DIFF{"Compare config vs. state"}
    STATEBOX --> DIFF
    DIFF -->|"Mismatch (drift)"| REPLACE["Destroy old resource<br>Create new resource"]
    REPLACE --> NEWSTATE["State updated with new ID + content"]

    style CONFIG fill:#374151,stroke:#9ca3af,color:#ffffff
    style STATEBOX fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style DIFF fill:#713f12,stroke:#fbbf24,color:#ffffff
    style REPLACE fill:#312e81,stroke:#a78bfa,color:#ffffff
    style NEWSTATE fill:#14532d,stroke:#4ade80,color:#ffffff
```

At this point, configuration and state are **in sync** again. Since there is no longer any difference between them, a subsequent `plan` reports no changes.

---

## 8. State Is Always Created — It Is Non-Optional

This example uses a single resource, so the state file tracks a single entry. In a real-world scenario, a configuration may contain **numerous resources across several different providers**. Regardless of how large or small the infrastructure is:

- Terraform **always** creates a state file once you apply.
- Terraform **always** uses it to track the state of your infrastructure in the real world.
- Maintaining a state file is **not optional** — it is fundamental to how Terraform operates.

State is more than bookkeeping for a single-resource demo like this one — later lessons build on this same file to explain why state matters at scale (team collaboration, locking, performance) and what can go wrong if it's mishandled.

---

### Topic Summary: Terraform State

**Terraform state** is a JSON file (`terraform.tfstate`) that Terraform creates the first time you run `terraform apply`, mapping each resource in your configuration to its real-world counterpart, ID, and attributes. Terraform needs it because neither your configuration nor the real world alone can tell it what it previously created — state is the missing map between the two. Before any `apply`, there is no state and Terraform assumes nothing is provisioned; every subsequent `plan` or `apply` **refreshes** state (re-reading real-world resources through the provider) and compares all three sources — configuration, state, and reality — to decide what to create, leave alone, or replace. When a resource's arguments **drift** between configuration and state, Terraform destroys the old resource and creates a new one, updating the state file to match. State is not a convenience feature — Terraform creates and relies on it for every configuration, regardless of size.

---

## Knowledge Check

Answer each question on your own first, then read the explanation below it.

---

### 1 · Why state exists at all

**Why can't Terraform just compare your configuration directly against the real-world infrastructure, without keeping a state file?**

> Because neither side can answer the full question on its own. Configuration only says what you *want*; it doesn't say what Terraform already created. And most resource types have no reliable, built-in way to prove "this real-world object was created by this specific resource block." Terraform's own **state file** is the record that bridges the two, tracking IDs and attributes it can trust.

---

### 2 · Why the first `plan` shows no state details

**Why does the very first `terraform plan` in a new configuration directory show nothing related to a state refresh?**

> Because **no state file exists yet** — `terraform.tfstate` is only created after the first `terraform apply`. With no state to refresh, Terraform assumes no resources are currently provisioned and plans a **create**.

---

### 3 · When the state file is created

**When does `terraform.tfstate` first appear in the configuration directory?**

> After the **first successful `terraform apply`**. Running `terraform plan` alone never creates it — `plan` only reads and compares, it does not write state.

---

### 4 · What "refreshing state" actually does

**What does Terraform mean when it says it's "refreshing state" before a plan or apply?**

> It means Terraform asks each provider to **re-read** every resource already recorded in state, updating its in-memory copy to match current reality. This happens *before* Terraform compares state against your configuration — so the comparison uses up-to-date information, not stale data from the last apply.

---

### 5 · What the state file actually is

**What kind of file is `terraform.tfstate`, and what does it contain?**

> It is a **JSON data structure** that maps real-world infrastructure to the resources defined in your configuration. It stores each resource's mode, type, logical name, provider, unique ID, and every resource attribute.

---

### 6 · Why a second `apply` does nothing

**If you run `terraform apply` twice in a row with no configuration changes, why does the second run make no changes?**

> Terraform refreshes state and finds the resource **already recorded** with a matching ID and matching attributes, and the refreshed real-world data agrees. Since configuration, state, and reality all agree, there is nothing to create, update, or destroy.

---

### 7 · Source of truth

**What does Terraform treat as its source of truth when running `plan` or `apply`?**

> The **state file**. Terraform compares your configuration against what is recorded in state (refreshed against the real world) — not just against the real infrastructure directly.

---

### 8 · What happens on a configuration change

**If you change a resource argument in the configuration (e.g., `content`) so it no longer matches what's recorded in state, what does Terraform do?**

> It detects the mismatch — **drift** — between configuration and state, and creates a plan to **destroy the existing resource and create a new one** (a "replace"), then updates the state file to reflect the new resource's ID and attributes.

---

### 9 · Is state optional?

**Is maintaining a state file optional for small configurations with only one or two resources?**

> **No.** Terraform always creates and relies on a state file after `apply`, regardless of how many resources or providers are involved. It is a fundamental, non-optional part of how Terraform works.

---

### 10 · Drift from outside Terraform

**If someone manually terminates an `aws_instance` in the AWS Console, what does the next `terraform plan` show — "no changes" or a plan to create it?**

> A plan to **create** it. The refresh step asks AWS to Read that instance ID, finds it's gone, and updates the in-memory state to reflect that. Comparing the refreshed state (now "doesn't exist") against `main.tf` (still declares it should exist) produces a create — the same refresh-then-compare logic that catches any other drift.

---

### 11 · How refresh actually finds "the" resource

**Concretely, how does Terraform know whether a specific EC2 instance created six months ago is still there — does it search by name or tags?**

> Neither. Terraform looks up the exact **`id`** that was recorded in state back when the instance was created (e.g. `i-0abcd1234efgh5678`), and calls the provider's **Read** operation for that specific ID (a `DescribeInstances` call filtered to it, for EC2). If the API returns the instance, it still exists; if it returns "not found," Terraform treats it as gone. The stored ID — not a name or tag search — is what makes the lookup possible.

---

## FAQ

Common points of confusion, answered directly.

---

**Does the create call really return *just* the ID, or more than that?**

> More than that. The provider's create API call (e.g. `RunInstances`) returns the resource's **entire initial attribute set** — the unique `id` plus every other attribute (arguments you set and computed values AWS fills in). Terraform stores all of it in `terraform.tfstate`, not only the `id`. The `id` is what matters for *finding* the resource again later; the rest of the stored attributes are what later comparisons are checked against.

---

**During refresh, does Terraform check each argument one at a time?**

> No — it's a **single Read call per resource**, using the stored `id`. That one API response (e.g. one `DescribeInstances` call) returns every current attribute of the real object at once. Terraform doesn't make a separate round-trip per argument; it overwrites its whole in-memory copy of that resource's attributes from that one response.

---

**Does Terraform only refresh when it suspects something changed?**

> No — refresh is **unconditional**. It runs at the start of every `plan` and `apply`, before any comparison happens, regardless of whether anything actually changed. Terraform can't know whether there's a difference *until after* refreshing — so "compare, then refresh if there's a diff" has the order backwards. The correct order is always **refresh, then compare**.

---

**So what's the full, correct sequence, end to end?**

> 1. **Create** (once) — the provider's create call returns a unique `id` plus the resource's full initial attributes; Terraform stores all of it in `terraform.tfstate`.
> 2. **Refresh** (every later `plan`/`apply`, unconditionally) — Terraform takes the stored `id` and makes **one** Read call to the provider, which returns the object's current attributes in a single response (or "not found").
> 3. **Compare** (always runs after refresh) — Terraform checks the refreshed state's attribute values against what `main.tf` declares, argument by argument, to decide: no changes, update in place, replace, or create.

---
