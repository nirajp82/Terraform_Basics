# Terraform Providers: What `terraform init` Does Internally

This document walks through the full journey of a provider plugin—from the code you write in a `.tf` file, to the download from the Terraform Registry, to the folder on your machine where the binary is stored. We use the **`local_file`** example end to end so every step is concrete.

---

## 1. Starting Point: Your Configuration File

Imagine you are in this project directory:

```text
03_GettingStarted/02_HCL_Basics_Lab/terraform-projects/HCL/
└── main.tf
```

Inside `main.tf` you have written:

```hcl
resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = "I love pet!"
}
```

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    A["main.tf written"] --> B["No provider plugin on disk"]
    B --> C["No root/pet.txt yet"]
    C --> D["plan / apply will FAIL"]
    D --> E["Must run terraform init first"]

    style A fill:#374151,stroke:#9ca3af,color:#ffffff
    style B fill:#374151,stroke:#9ca3af,color:#ffffff
    style C fill:#374151,stroke:#9ca3af,color:#ffffff
    style D fill:#713f12,stroke:#fbbf24,color:#ffffff
    style E fill:#14532d,stroke:#4ade80,color:#ffffff
```

At this point you have **only** written configuration code. Terraform does not yet know how to talk to the `local` provider.

---

## 2. How Your Code Tells Terraform Which Provider to Download

Terraform reads your resource block and extracts two critical pieces of information:

| Part in your code | Value | What Terraform learns |
| --- | --- | --- |
| Resource type | `local_file` | The word before `_` → provider name = **`local`** |
| Resource name | `pet` | Your logical label for this resource (not used during init) |

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    CODE["resource local_file pet"] --> SPLIT["Split resource type"]
    SPLIT --> PROV["Provider = local"]
    SPLIT --> RESTYPE["Resource type = local_file"]
    SPLIT --> NAME["Resource name = pet"]
    PROV --> NEED["Need hashicorp/local plugin"]

    style CODE fill:#374151,stroke:#9ca3af,color:#ffffff
    style SPLIT fill:#374151,stroke:#9ca3af,color:#ffffff
    style PROV fill:#374151,stroke:#9ca3af,color:#ffffff
    style RESTYPE fill:#374151,stroke:#9ca3af,color:#ffffff
    style NAME fill:#374151,stroke:#9ca3af,color:#ffffff
    style NEED fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
```

> **Rule:** The provider name is always the prefix before the first `_` in the resource type.
> `local_file` → **`local`** · `aws_instance` → **`aws`** · `aws_s3_bucket` → **`aws`**

---

## 3. What Happens Internally During `terraform init`

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    START(["You run terraform init"]) --> S1["Step 1: Scan all .tf files"]
    S1 --> S2["Step 2: Detect local_file needs local provider"]
    S2 --> S3["Step 3: Resolve source address hashicorp/local"]
    S3 --> S4["Step 4: Contact registry.terraform.io"]
    S4 --> S5["Step 5: Download provider binary v2.9.0"]
    S5 --> S6["Step 6: Save to .terraform/providers/"]
    S6 --> DONE(["Ready for plan and apply"])

    S4 -.->|HTTPS| REG["registry.terraform.io"]
    S6 -.->|writes| DISK["terraform-provider-local binary"]

    style START fill:#14532d,stroke:#4ade80,color:#ffffff
    style S1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S3 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S4 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S5 fill:#374151,stroke:#9ca3af,color:#ffffff
    style S6 fill:#374151,stroke:#9ca3af,color:#ffffff
    style DONE fill:#14532d,stroke:#4ade80,color:#ffffff
    style REG fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style DISK fill:#312e81,stroke:#a78bfa,color:#ffffff
```

### The journey in plain English

| Step | What happens | Touches real infrastructure? |
| --- | --- | --- |
| **1. Scan** | Terraform reads every `.tf` file in the working directory | No |
| **2. Detect** | Finds `local_file` → needs the **`local`** provider | No |
| **3. Resolve address** | Builds source address: `hashicorp/local` | No |
| **4. Contact registry** | Connects to `registry.terraform.io` over the internet | No |
| **5. Download** | Fetches the compiled provider binary (e.g., `v2.9.0`) | No |
| **6. Install locally** | Saves the binary into the hidden `.terraform/` folder | No |

> **`terraform init` never creates, changes, or deletes infrastructure.** It only prepares your working directory. You can run it as many times as you want safely.

---

## 4. Where Terraform Downloads From

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TB
    MACH["<div style='white-space:nowrap'>Lab: 03_GettingStarted/02_HCL_Basics_Lab/terraform-projects/HCL/</div>"] --> TF["main.tf"]
    TF --> CLI["Terraform CLI"]
    CLI --> REQ["<div style='white-space:nowrap'>terraform init: Request hashicorp/local</div>"]
    REQ -->|HTTPS download| REG["<div style='white-space:nowrap'>registry.terraform.io — Public Registry</div>"]
    REG --> OFF["Official: local, aws, google"]
    REG --> PART["Partner: DigitalOcean, Heroku, F5"]
    REG --> COMM["Community: contributor providers"]
    REG -->|signed binary v2.9.0| SAVE["<div style='white-space:nowrap'>Save to .terraform/providers/</div>"]

    style MACH fill:#374151,stroke:#9ca3af,color:#ffffff
    style TF fill:#374151,stroke:#9ca3af,color:#ffffff
    style CLI fill:#374151,stroke:#9ca3af,color:#ffffff
    style REQ fill:#374151,stroke:#9ca3af,color:#ffffff
    style REG fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style OFF fill:#14532d,stroke:#4ade80,color:#ffffff
    style PART fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style COMM fill:#312e81,stroke:#a78bfa,color:#ffffff
    style SAVE fill:#312e81,stroke:#a78bfa,color:#ffffff
```

### The source address — how Terraform knows what to download

The identifier `hashicorp/local` (shown in init output) is called the **source address**.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    FULL["<div style='white-space:nowrap'>registry.terraform.io / hashicorp / local</div>"]
    SHORT["hashicorp / local"]
    FULL --- EQ["="]
    EQ --- SHORT
    FULL --> H1["hostname"]
    FULL --> N1["namespace: hashicorp"]
    FULL --> T1["type: local"]
    SHORT --> N2["namespace: hashicorp"]
    SHORT --> T2["type: local"]
    SHORT --> DEF["<div style='white-space:nowrap'>hostname defaults to registry.terraform.io</div>"]

    style FULL fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style SHORT fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style EQ fill:#374151,stroke:#9ca3af,color:#ffffff
    style H1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style N1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style T1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style N2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style T2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style DEF fill:#374151,stroke:#9ca3af,color:#ffffff
```

| Segment | In `hashicorp/local` | Meaning |
| --- | --- | --- |
| **Hostname** *(optional)* | *(omitted)* | Defaults to `registry.terraform.io` |
| **Namespace** | `hashicorp` | Organization that publishes the provider |
| **Type** | `local` | Provider name |

### Can Terraform download from registries other than HashiCorp's?

**Yes.** `registry.terraform.io` is only the **default** registry — not the only one Terraform can use.

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    ADDR["Provider source address"] --> Q{"Hostname included?"}
    Q -->|No| PUB["<div style='white-space:nowrap'>registry.terraform.io — Public Registry</div>"]
    Q -->|Yes| CUSTOM["Custom registry host"]
    CUSTOM --> TFE["<div style='white-space:nowrap'>app.terraform.io — Terraform Cloud</div>"]
    CUSTOM --> SELF["<div style='white-space:nowrap'>terraform.mycompany.com — Self-hosted</div>"]
    CUSTOM --> MIRROR["Local filesystem mirror"]
    PUB --> PATH1["<div style='white-space:nowrap'>.terraform/providers/registry.terraform.io/...</div>"]
    TFE --> PATH2["<div style='white-space:nowrap'>.terraform/providers/app.terraform.io/...</div>"]
    SELF --> PATH3["<div style='white-space:nowrap'>.terraform/providers/terraform.mycompany.com/...</div>"]

    style ADDR fill:#374151,stroke:#9ca3af,color:#ffffff
    style Q fill:#374151,stroke:#9ca3af,color:#ffffff
    style PUB fill:#14532d,stroke:#4ade80,color:#ffffff
    style CUSTOM fill:#312e81,stroke:#a78bfa,color:#ffffff
    style TFE fill:#312e81,stroke:#a78bfa,color:#ffffff
    style SELF fill:#312e81,stroke:#a78bfa,color:#ffffff
    style MIRROR fill:#312e81,stroke:#a78bfa,color:#ffffff
    style PATH1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style PATH2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style PATH3 fill:#374151,stroke:#9ca3af,color:#ffffff
```

| Registry | Example hostname | Typical use |
| --- | --- | --- |
| **Public Terraform Registry** | `registry.terraform.io` *(default)* | Official, partner, and community providers — what this course uses |
| **Terraform Cloud / Enterprise private registry** | `app.terraform.io` | Company-internal providers and modules not published publicly |
| **Self-hosted private registry** | e.g. `terraform.mycompany.com` | On-prem or air-gapped environments |
| **Local filesystem mirror** | Configured in CLI settings | Offline installs or pre-cached provider binaries |

**Examples:**

```text
hashicorp/local                              → registry.terraform.io/hashicorp/local
terraform.mycompany.com/acme/internal        → private company registry (not HashiCorp)
```

> For beginners and this course, every example uses the **public HashiCorp registry** (`registry.terraform.io`). Private registries are an enterprise pattern you will encounter later in real-world teams.

---

## 5. Where Terraform Puts the Downloaded Plugin

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    B1["<div style='white-space:nowrap'>BEFORE init: .../HCL/main.tf only</div>"]
    B1 -->|"terraform init"| A1["AFTER init: project folder"]
    A1 --> A2["main.tf"]
    A1 --> A3[".terraform/"]
    A3 --> A4["providers/"]
    A4 --> A5["registry.terraform.io/"]
    A5 --> A6["hashicorp/local/"]
    A6 --> A7["2.9.0/"]
    A7 --> A8["windows_amd64/"]
    A8 --> A9["<div style='white-space:nowrap'>terraform-provider-local_v2.9.0_x5.exe</div>"]

    style B1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A1 fill:#14532d,stroke:#4ade80,color:#ffffff
    style A2 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A3 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A4 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A5 fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style A6 fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style A7 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A8 fill:#374151,stroke:#9ca3af,color:#ffffff
    style A9 fill:#312e81,stroke:#a78bfa,color:#ffffff
```

### What each path segment means

After `terraform init`, the provider binary is stored at:

```text
03_GettingStarted/02_HCL_Basics_Lab/terraform-projects/HCL/
└── .terraform/
    └── providers/
        └── registry.terraform.io/
            └── hashicorp/
                └── local/
                    └── 2.9.0/
                        └── windows_amd64/
                            └── terraform-provider-local_v2.9.0_x5.exe
```

| Path segment | What it is |
| --- | --- |
| `.terraform/` | Hidden working directory Terraform creates during init |
| `providers/` | All downloaded provider binaries live here |
| `registry.terraform.io/` | Which registry the plugin was downloaded from |
| `hashicorp/local/` | Namespace + provider type (the source address) |
| `2.9.0/` | Exact version that was installed |
| `windows_amd64/` | OS and CPU architecture for your machine (Windows 64-bit) |
| `terraform-provider-local_v2.9.0_x5.exe` | The actual executable binary Terraform calls at runtime |

- https://github.com/nirajp82/Terraform_Basics/tree/main/03_GettingStarted/02_HCL_Basics_Lab/terraform-projects/HCL
  
### Terminal output you will see

```text
Initializing provider plugins found in the configuration...
- Finding latest version of hashicorp/local...
- Installing hashicorp/local v2.9.0...
- Installed hashicorp/local v2.9.0 (signed by HashiCorp)

Initializing the backend...

Terraform has been successfully initialized!
```

| Line in output | What it tells you |
| --- | --- |
| `Finding latest version of hashicorp/local` | Terraform queried the registry for the newest compatible version |
| `Installing hashicorp/local v2.9.0` | Version **2.9.0** of the local provider is being downloaded |
| `signed by HashiCorp` | The binary is cryptographically verified — it is authentic |
| `successfully initialized` | Plugin is on disk; you can now run `plan` and `apply` |

---

## 6. Full End-to-End: From Code to File on Disk

```mermaid
%%{init: {'theme': 'dark'}}%%
sequenceDiagram
    autonumber
    actor You
    participant TF as Terraform CLI
    participant Reg as registry.terraform.io
    participant Plg as local Provider Plugin
    participant FS as Filesystem

    rect rgb(20, 50, 35)
    Note over You,FS: Phase 1 — terraform init
    You->>TF: terraform init
    TF->>TF: Read main.tf
    TF->>Reg: GET hashicorp/local
    Reg-->>TF: binary v2.9.0
    TF->>Plg: Install to .terraform/providers/
    TF-->>You: Initialized
    end

    rect rgb(20, 45, 75)
    Note over You,FS: Phase 2 — terraform plan
    You->>TF: terraform plan
    TF->>Plg: Plan local_file.pet
    Plg-->>TF: + create local_file.pet
    TF-->>You: Preview only
    end

    rect rgb(20, 55, 40)
    Note over You,FS: Phase 3 — terraform apply
    You->>TF: terraform apply
    TF->>Plg: Create local_file.pet
    Plg->>FS: Write root/pet.txt
    FS-->>Plg: File created
    Plg-->>TF: Success
    TF-->>You: Apply complete
    end
```

### Key takeaway

| Command | What it does | Touches infrastructure? |
| --- | --- | --- |
| `terraform init` | Downloads the provider plugin (the tool) | No |
| `terraform plan` | Previews what will change | No |
| `terraform apply` | Provider writes `root/pet.txt` | **Yes** |

The **provider plugin** is the bridge between your HCL code and the real world. Without it (before init), Terraform has configuration but no ability to act.

---

## 7. Three Tiers of Providers in the Registry

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    REG["registry.terraform.io"] --> OFF["Official — HashiCorp"]
    REG --> PART["Partner — vendor partners"]
    REG --> COMM["Community — contributors"]
    OFF --> E1["local, aws, azurerm, google, random"]
    PART --> E2["DigitalOcean, Heroku, F5 BIG-IP"]
    COMM --> E3["Niche platform providers"]

    style REG fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style OFF fill:#14532d,stroke:#4ade80,color:#ffffff
    style E1 fill:#14532d,stroke:#4ade80,color:#ffffff
    style PART fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style E2 fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style COMM fill:#312e81,stroke:#a78bfa,color:#ffffff
    style E3 fill:#312e81,stroke:#a78bfa,color:#ffffff
```

The **`local`** provider used in our example is an **official** HashiCorp provider.

---

## 8. Provider Versioning (Preview)

By default, `terraform init` installs the **latest available version** of a provider (e.g., `v2.9.0` on this lab).

Providers are updated regularly to add features and fix bugs. New versions can sometimes introduce **breaking changes** to your existing `.tf` code.

Later in this course you will learn how to **pin a specific provider version** so your configuration does not unexpectedly pull in a newer, incompatible release.

---

### Topic Summary: Terraform Providers

When you write `resource "local_file" "pet"`, Terraform detects that it needs the **`local`** provider. Running **`terraform init`** scans your `.tf` files, resolves the source address (`hashicorp/local`), downloads the signed provider binary from **`registry.terraform.io`** (the default public registry), and stores it in the hidden **`.terraform/providers/`** directory on your machine. Terraform can also download from **other registries** when a custom hostname is specified in the source address (e.g., a company private registry). Init is safe to re-run and never touches real infrastructure. Only after init can Terraform load the provider plugin to execute `plan` and `apply`. The source address format is `[hostname/]namespace/type`. Providers in the public registry are classified as Official, Partner, or Community based on who maintains them.

---

## Knowledge Check

Answer each question on your own first, then read the explanation below it.

---

### 1 · Before init

**You have written `main.tf` but have not run any commands yet. Can Terraform create `root/pet.txt`?**

> **No.** Without **`terraform init`**, the provider plugin is not installed. Terraform cannot execute any resource until init downloads the required provider.

---

### 2 · Where providers download from

**When you run `terraform init`, where does Terraform download the provider from?**

> The **Terraform Registry** at **`registry.terraform.io`**. For `local`, the address is **`hashicorp/local`** (same as `registry.terraform.io/hashicorp/local`).

---

### 3 · Local storage path

**After `terraform init`, where is the provider binary stored on your machine?**

> In **`.terraform/providers/`** inside your project — e.g. `.terraform/providers/registry.terraform.io/hashicorp/local/2.9.0/windows_amd64/terraform-provider-local_v2.9.0_x5.exe`.

---

### 4 · Detecting the provider

**How does Terraform know it needs the `local` provider from `resource "local_file" "pet"`?**

> It reads the resource type **`local_file`** and takes the prefix **before the underscore** — **`local`**.

---

### 5 · Init and infrastructure

**Does running `terraform init` create or modify any real infrastructure?**

> **No.** Init only downloads provider plugins and prepares the working directory. Safe to run multiple times.

---

### 6 · Source address

**What is a provider source address, and what are its parts?**

> The identifier Terraform uses to find a plugin: **`[<hostname>/]<namespace>/<type>`**.  
> Example: **`hashicorp/local`** — namespace **`hashicorp`**, type **`local`**.

---

### 7 · Registry tiers

**What are the three tiers of providers in the Terraform Registry?**

> **Official** (HashiCorp), **Partner** (vendor via HashiCorp program), and **Community** (individual maintainers).

---

### 8 · Default version

**What version of a provider does Terraform install by default during init?**

> The **latest** version that satisfies the configuration, unless you pin a version constraint in code.

---

### 9 · Non-public registries

**Will Terraform only download providers from HashiCorp's public registry?**

> **No.** `registry.terraform.io` is the **default** when no hostname is given. A custom hostname in the source address points to a **private or alternate registry** instead.

---

### 10 · Path shows registry host

**Why does `.terraform/providers/` contain `registry.terraform.io` in the path?**

> That segment records **which registry** supplied the plugin. A private registry would show its hostname there instead.

---

### 11 · Course default registry

**In this course, which registry do we use?**

> The public **Terraform Registry** at **`registry.terraform.io`**. Shorthand addresses like **`hashicorp/local`** resolve there by default.

