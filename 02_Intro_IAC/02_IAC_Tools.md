# Introduction to Infrastructure as Code (IaC)

Infrastructure as Code (IaC) is the practice of codifying the entire infrastructure provisioning and management lifecycle. Instead of manually clicking through a cloud vendor's management console, you write and execute code to define, provision, configure, update, and destroy infrastructure resources (such as databases, networks, storage, and application configurations).

While custom shell scripts can automate tasks, they require advanced programming logic, are difficult to maintain, and lack reusability. Dedicated IaC tools solve this by using simple, human-readable, and declarative high-level languages.

---

## Classification of IaC Tools

The IaC ecosystem can be broadly categorized into three distinct types, each designed to solve a specific infrastructure challenge:

1. **Configuration Management**
2. **Server Templating**
3. **Infrastructure Provisioning**

### 1. Configuration Management Tools

* **Examples:** Ansible, Puppet, Chef, SaltStack
* **Primary Use Case:** Installing and managing software on *existing* infrastructure resources (servers, databases, network devices).
* **Key Features:**
* **Standardized Structure:** Unlike ad-hoc shell scripts, these tools maintain a consistent code structure that is easily version-controlled and shared.
* **Multi-Node Execution:** Designed to execute code across multiple remote resources simultaneously.
* **Idempotency:** A critical feature where running the same code multiple times yields the exact same state. It only applies necessary changes to bring the environment to the defined state, leaving already compliant configurations untouched.



### 2. Server Templating Tools

* **Examples:** Docker, Packer, Vagrant
* **Primary Use Case:** Creating custom, pre-configured images of virtual machines or containers.
* **Key Features:**
* **Pre-baked Dependencies:** Images contain all required software and dependencies out of the box, minimizing post-deployment installation steps.
* **Common Artifacts:** Examples include Amazon Machine Images (AMIs), DockerHub container images, or VM images from platforms like osboxes.org.
* **Immutable Infrastructure:** Promotes an architecture where deployed instances are never modified in place. If an update is required, the base template/image is modified, a new image is built, and the old instance is completely replaced by a new one.



### 3. Infrastructure Provisioning Tools

* **Examples:** Terraform, AWS CloudFormation
* **Primary Use Case:** Deploying and managing the foundational infrastructure components themselves (virtual machines, VPCs, subnets, security groups, storage).
* **Key Features:**
* **Declarative Approach:** Users define the desired end state of the infrastructure, and the tool determines how to achieve it.
* **Cloud Scope:** Can manage cloud-native services across various layers.
* **Platform Support:** While tools like AWS CloudFormation are cloud-specific (vendor-locked to AWS), tools like Terraform are vendor-agnostic and leverage provider plugins to support almost all major cloud platforms.



---

## Quick Reference Comparison

| Category | Primary Focus | Core Philosophy | Example Tools |
| --- | --- | --- | --- |
| **Infrastructure Provisioning** | Creating hardware/cloud resources | Declarative bootstrapping | Terraform, CloudFormation |
| **Configuration Management** | Managing software on existing systems | Mutable & Idempotent updates | Ansible, Puppet, Chef, SaltStack |
| **Server Templating** | Creating golden images/containers | Immutable replacement | Docker, Packer, Vagrant |
