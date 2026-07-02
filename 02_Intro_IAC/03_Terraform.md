# Introduction to Terraform: High-Level Overview

This document provides a foundational overview of Terraform, focusing on its core features, architecture, and operational phases as an Infrastructure as Code (IaC) tool.

---

## What is Terraform?

Terraform is a widely used, open-source Infrastructure as Code (IaC) tool developed by **HashiCorp**, designed primarily for **infrastructure provisioning**.

* **Installation:** Distributed as a single compiled binary, making setup extremely fast.
* **Speed:** Enables the building, managing, and destroying of infrastructure in minutes.
* **Platform Agnostic:** Capable of deploying infrastructure across a vast array of platforms, including public clouds (AWS, GCP, Azure) and on-premise private clouds (VMware vSphere).

---

## How Terraform Works

### 1. Providers

Providers are plugins that help Terraform connect to different platforms and services. Providers allow Terraform to create, update, and manage resources by using the platform's APIs.

Here's a simpler and shorter version:

Some common providers are:

* **Cloud Platforms:** AWS, Azure, Google Cloud Platform (GCP)
* **Networking:** BigIP, Cloudflare, Palo Alto Networks, Infoblox, DNS
* **Monitoring:** Datadog, Grafana, Wavefront, Sumo Logic
* **Databases:** MongoDB, MySQL, PostgreSQL, InfluxDB
* **Version Control:** GitHub, GitLab, Bitbucket

<img width="1140" height="522" alt="image" src="https://github.com/user-attachments/assets/5ae972d6-c4c0-4935-98bb-e16ad56056a4" />


### 2. HashiCorp Configuration Language (HCL)

Terraform uses its own simple, human-readable language called **HCL** to define infrastructure as blocks of code.

* **File Extension:** All configuration files end in `.tf`.

<img width="490" height="471" alt="image" src="https://github.com/user-attachments/assets/fb9f2588-c364-4512-9beb-dfc0049aaadb" />

* **Version Control:** HCL code can be easily stored, maintained, and distributed via version control systems (like Git).

### 3. Declarative Approach

HCL is a **declarative** language. This means you write code to define the **desired state** (what you want the infrastructure to look like). Terraform compares this desired state against the **current state** (what actually exists right now) and automatically determines the exact steps needed to bridge the gap. You do not have to write procedural code detailing *how* to build it.

<img width="1103" height="479" alt="image" src="https://github.com/user-attachments/assets/af23e4ac-579d-45fd-a183-d36c86279cf8" />

---

## The Terraform Workflow: Three Core Phases

Terraform executes its declarative logic through a standard three-phase lifecycle to safely move, configure, and manage identity objects:

* **Init (`terraform init`):** Initializes the working directory containing your configuration files (`.tf`). During an identity migration, this command detects your source or target IdP configurations and downloads the specific Provider plugins (such as the Okta or CyberArk providers) required to communicate with those respective identity APIs.
* **Plan (`terraform plan`):** Evaluates the current state of your target IdP versus the desired state defined in your code. For a migration, it drafts an execution plan outlining exactly which user accounts will be provisioned, which security groups or roles will be created, and which access policies will be updated.
* **Apply (`terraform apply`):** Executes the generated plan. Terraform makes high-speed, secure API calls to your target IdP to physically build the users, assign them to their respective roles, and configure their application access to perfectly match your migration code.

> **Note on Drift:** Identity environments are dynamic. If an administrator manually changes a user's role assignment or updates an application policy directly inside the IdP admin dashboard (causing "configuration drift"), running a subsequent `terraform apply` will automatically detect that unauthorized change. Terraform will then fire the necessary API commands to fix the environment, ensuring the target IdP immediately matches your master migration code.

---

## Core Terraform Concepts

* **Resources:** The fundamental unit in Terraform. Every object managed by Terraform (e.g., a compute instance, a database, a virtual network, a physical server) is considered a "resource". Terraform handles the entire lifecycle of a resource from provisioning to configuration to decommissioning.
  * **For ex. in IDP migration:**: An Okta user, a CyberArk security group, or an SSO application are all just "resources" to Terraform.


* **State:** Terraform maintains a blueprint of the resources as they exist in the real world, usually stored in a `.tfstate` file. It relies on this state file to determine what actions to take during an update.
  * **For ex. in IDP migration:**:  This file maps a user or app in your code to its actual API ID inside CyberArk, ensuring Terraform never creates a duplicate by mistake.


* **Data Sources:** Allows Terraform to fetch read-only attributes from existing infrastructure components. This data can then be used to dynamically configure other resources in your code.
  * **For ex. in IDP migration:**:  If CyberArk already has a default global security policy that you didn't create, you use a Data Source to "read" its ID so you can attach your new applications to it.


* **Import:** Terraform can adopt existing resources that were created manually or by other tools, bringing them under Terraform's state management going forward.
  * **For ex. in IDP migration:**: If you have 500 applications that were built manually in Okta over the last five years, you use `import` to pull them into your Terraform code without having to delete and recreate them.
---

# Example of Terraform Migration Guide: Okta → CyberArk

This guide explains the core workflow of migrating users, groups, and applications from an existing Identity Provider (Okta) to a new Identity Provider (CyberArk) using Terraform.

## 0. The Golden Rule of Migrations

> **Terraform does not "manage Okta data" in this migration.**

* **Okta:** The source system (used only to read/export raw data).
* **CyberArk:** The target system (actively managed by Terraform).

Therefore, Terraform resources are named based on the *target* system provider. We use `cyberark_user` and `cyberark_group`. We **do not** use `okta_user` to create things, because Terraform is actively controlling CyberArk, not Okta.

## 1. Before Terraform Starts (Getting the Okta Data)

Okta already contains your live data (Users: John, Sarah, Mike, Lisa | Group: Finance). To get this data out of Okta and ready for CyberArk, you generally use one of two methods:

**Method A: The Custom Script Approach (File Generation)**
You write a custom script (using C#, Node.js, or an Okta SDK) that connects to the Okta API, downloads the user list, and automatically writes the physical `.tf` text files containing the `cyberark_user` resource blocks.

**Method B: The Okta Provider Approach (Terraform Data Sources)**
You configure Terraform with *both* the Okta Provider and the CyberArk Provider. You use the Okta Provider purely as a **Read-Only Data Source** to fetch the users dynamically, and instantly pass that data into the CyberArk provider to create them.

```hcl
# 1. READ from Okta (Using Okta Provider)
data "okta_user" "source_john" {
  email = "john@company.com"
}

# 2. WRITE to CyberArk (Using CyberArk Provider)
resource "cyberark_user" "target_john" {
  username   = data.okta_user.source_john.login
  first_name = data.okta_user.source_john.first_name
}

```

## 2. Terraform Configuration (Desired State)

This code tells Terraform what to build in CyberArk.

**How many files do you need?** You (or your script) create these `.tf` files. You can choose to write everything into one single file (e.g., `main.tf`), or you can organize it into 5, 10, or 100 different files (e.g., `users.tf`, `groups.tf`, `apps.tf`). Terraform doesn't care—it automatically reads all `.tf` files in the folder and merges them together in its memory as one single configuration.

**Example: `users.tf**`

```hcl
resource "cyberark_user" "john" { username = "John" }
resource "cyberark_user" "sarah" { username = "Sarah" }
resource "cyberark_user" "mike" { username = "Mike" }
resource "cyberark_user" "lisa" { username = "Lisa" }
resource "cyberark_group" "finance" { name = "Finance" }

```

### What is a Resource?

A resource is an object Terraform creates and manages in the target system.

| Terraform Resource | Real CyberArk Object |
| --- | --- |
| `cyberark_user.john` | User John |
| `cyberark_user.sarah` | User Sarah |
| `cyberark_group.finance` | Finance Group |

## 3. Init (`terraform init`)

When you run `terraform init`, Terraform reads your `.tf` files, downloads the required Provider plugins (like the CyberArk provider), and prepares API communication. At this stage, no users are read, and no changes are made.

**What is a Provider?**
A provider is the plugin that connects Terraform to a specific system's API. The CyberArk Provider knows how to securely `GET` and `POST` users and groups to the CyberArk API.

## 4. Plan (`terraform plan`)

Terraform compares what you *want* against what *actually exists*.

* **Step 1: Reads the Desired State from your `.tf` code.** Terraform reads the `cyberark_` blocks you wrote to understand what you want CyberArk to look like. *(Note: It is NOT connecting to Okta here; it is only reading your local code).*
* **Step 2: Reads the Actual State from CyberArk.** Terraform calls the CyberArk API (`GET /users`, `GET /groups`) to see what already exists in the target system.
* **Step 3: Compares the two.**

| Resource | In Your Code? | Already in CyberArk? | Action |
| --- | --- | --- | --- |
| John | Yes | Yes | No change |
| Sarah | Yes | Yes | No change |
| Mike | Yes | No | **Create** |
| Lisa | Yes | No | **Create** |
| Finance | Yes | No | **Create** |

**Plan Output:**

```diff
+ create cyberark_user.mike
+ create cyberark_user.lisa
+ create cyberark_group.finance

```

*(Note: Nothing is actually created yet.)*

## 5. Apply (`terraform apply`)

Terraform instructs the CyberArk provider to execute the changes. The provider calls the CyberArk API (`POST /users`, `POST /groups`). CyberArk now perfectly matches your Terraform configuration.

## 6. State (Very Important)

Terraform stores a state file locally (or remotely) called `terraform.tfstate`. It maps your written code to the real CyberArk database IDs.

* `cyberark_user.john` → CyberArk ID: 101
* `cyberark_group.finance` → CyberArk ID: 501

Terraform uses this state to remember what already exists, avoid creating duplicates, and track changes later.

## 7. Data Source (Read Only)

**Why use this?** Sometimes CyberArk has built-in objects or required settings that *never existed in Okta*, but you still need to use them for your migration.

For example, CyberArk might have a default "Global Authentication Policy" that was created automatically when you bought the software. You do not want Terraform to create a duplicate policy, but you *do* need to attach your migrating Okta users to it. Instead of creating it, Terraform uses a Data Source to simply look up its ID.

```hcl
data "cyberark_policy" "default_auth" {
  name = "Global Authentication Policy"
}

```

| Type | Meaning |
| --- | --- |
| **Resource** | Terraform creates and actively manages it. |
| **Data Source** | Terraform only looks it up (read-only) to use its data elsewhere. |


## 8. Import (Crucial for Migrations)

If John and the Finance group already exist in CyberArk because someone created them manually years ago, Terraform does NOT know about them yet. You must import them:

```bash
terraform import cyberark_user.john 101
terraform import cyberark_group.finance 501

```

Terraform's state updates to reflect that it now owns these objects. It manages them going forward without needing to delete and recreate them.


## 9. Drift (The Manual Changes Problem)

If a rogue admin manually deletes Mike directly in the CyberArk dashboard, Terraform still expects Mike to exist in its state.

On the next `terraform plan`, Terraform detects the missing user. Running `terraform apply` will automatically recreate Mike, instantly fixing the unauthorized manual change (drift).


## Final Mental Model Summary

1. **Okta:** Source data only (read via script or Okta Data Sources).
2. **Configuration:** `.tf` files defining the desired state for CyberArk (can be one file or many).
3. **Init:** Downloads the target API provider.
4. **Plan:** Compares your local code to the live target API (CyberArk).
5. **Apply:** Creates missing objects in the target system.
6. **State:** Remembers everything to prevent duplicates.
7. **Data Source:** Reads existing target objects safely so you can reference them.
8. **Import:** Brings existing manual objects under Terraform's control.
9. **Drift:** Automatically fixes manual, out-of-band changes.

---
## Enterprise Offerings

While Terraform open-source is highly capable, HashiCorp offers **Terraform Cloud** and **Terraform Enterprise**. These provide advanced features for organizations, such as centralized state management, simplified team collaboration, enhanced security controls, and a centralized UI for managing deployments.

---

### Topic Summary: Intro to Terraform

Terraform is HashiCorp's open-source, vendor-agnostic infrastructure provisioning tool. It uses a declarative language (HCL) where you define the *desired state* of your infrastructure in `.tf` files. Through the use of API plugins called **Providers**, Terraform can manage everything from cloud VMs (AWS, Azure) to databases and network rules. The standard operational workflow consists of three steps: **Init** (setup), **Plan** (preview changes), and **Apply** (execute changes). Terraform tracks the real-world configuration via a **State** file, ensuring it always knows how to update resources or fix configuration drift.

### Knowledge Check Q&A

**Q: How is Terraform able to communicate with so many different cloud providers and services?**
**A:** Terraform uses plugins called **Providers**. Providers translate Terraform's HCL code into API calls specific to that third-party platform (like AWS or DataDog).

**Q: What does it mean that Terraform's HCL is a "declarative" language?**
**A:** It means you only need to define the end-goal or "desired state" of the infrastructure (e.g., "I want 3 web servers"). You do not need to write the step-by-step instructions on how to create them; Terraform figures out the execution path for you.

**Q: What happens if an administrator manually deletes a database that Terraform was managing, and then you run `terraform apply`?**
**A:** Terraform will check its **State** file, see that the database is supposed to exist (desired state) but is missing in the real world (current state), and it will automatically recreate the database to fix the configuration drift.

**Q: What are Data Sources used for in Terraform?**
**A:** Data sources are used to read or fetch attributes from infrastructure that already exists (even if it isn't managed by Terraform) so that you can reference those attributes when building new resources. For example, you can use a Data Source to look up the ID of a default "Global Authentication Policy" in CyberArk, so you can assign your migrating users to it without Terraform trying to manage or overwrite the policy itself.

**Q: In an Okta to CyberArk migration, why do we use `cyberark_user` for our resource blocks instead of `okta_user`?**
**A:** Because Terraform is actively managing the *target* destination (CyberArk). In this workflow, Okta is just the source of the data, so you use the CyberArk Provider to actually build the desired state.

**Q: How does Terraform know not to create duplicate users if you run `terraform apply` twice?**
**A:** Terraform tracks everything it creates in a hidden file called `terraform.tfstate`. It maps your written code to the real-world CyberArk API IDs. If the state file shows the user was already created, Terraform safely skips it on the next run.

**Q: If a user or group was created manually in CyberArk years ago, how do you bring it under Terraform's control without deleting it?**
**A:** You use the `terraform import` command. This tells Terraform to find the existing object in CyberArk and attach its ID to your `.tf` code, bringing it under Terraform's management going forward.

**Q: What command should you run to safely verify what Terraform is going to do before it actually makes any changes to CyberArk?**
**A:** `terraform plan`. It acts as a "dry-run" or preview, comparing your code to the live environment and printing out exactly what will be created, modified, or destroyed.



