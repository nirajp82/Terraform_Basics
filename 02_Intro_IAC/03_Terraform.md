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


### 2. HashiCorp Configuration Language (HCL)

Terraform uses its own simple, human-readable language called **HCL** to define infrastructure as blocks of code.

* **File Extension:** All configuration files end in `.tf`.
* **Version Control:** HCL code can be easily stored, maintained, and distributed via version control systems (like Git).

### 3. Declarative Approach

HCL is a **declarative** language. This means you write code to define the **desired state** (what you want the infrastructure to look like). Terraform compares this desired state against the **current state** (what actually exists right now) and automatically determines the exact steps needed to bridge the gap. You do not have to write procedural code detailing *how* to build it.

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
* **For your migration:** An Okta user, a CyberArk security group, or an SSO application are all just "resources" to Terraform.


* **State:** Terraform maintains a blueprint of the resources as they exist in the real world, usually stored in a `.tfstate` file. It relies on this state file to determine what actions to take during an update.
* **For your migration:** This file maps a user or app in your code to its actual API ID inside CyberArk, ensuring Terraform never creates a duplicate by mistake.


* **Data Sources:** Allows Terraform to fetch read-only attributes from existing infrastructure components. This data can then be used to dynamically configure other resources in your code.
* **For your migration:** If CyberArk already has a default global security policy that you didn't create, you use a Data Source to "read" its ID so you can attach your new applications to it.


* **Import:** Terraform can adopt existing resources that were created manually or by other tools, bringing them under Terraform's state management going forward.
* **For your migration:** If you have 500 applications that were built manually in Okta over the last five years, you use `import` to pull them into your Terraform code without having to delete and recreate them.
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
**A:** Data sources are used to read or fetch attributes from infrastructure that already exists (even if it isn't managed by Terraform) so that you can reference those attributes when building new resources.
