# Introduction to Infrastructure as Code (IaC)

Infrastructure as Code (IaC) is the practice of codifying the entire infrastructure provisioning and management lifecycle. Instead of manually clicking through a cloud vendor's management console, you write and execute code to define, provision, configure, update, and destroy infrastructure resources (such as databases, networks, storage, and application configurations).

While custom shell scripts can automate tasks, they require advanced programming logic, are difficult to maintain, and lack reusability. Dedicated IaC tools solve this by using simple, human-readable, and declarative high-level languages.

---

## Classification of IaC Tools

The IaC ecosystem can be broadly categorized into three distinct types, each designed to solve a specific infrastructure challenge:

1. **Configuration Management**
2. **Server Templating**
3. **Infrastructure Provisioning**
   
   <img width="882" height="560" alt="image" src="https://github.com/user-attachments/assets/e4ae7557-6f16-4066-a25f-000e91f3a0e8" />


### 1. Configuration Management Tools

* **Examples:** Ansible, Puppet, Chef, SaltStack
* **Primary Use Case:** Installing and managing software on *existing* infrastructure resources (servers, databases, network devices).
* **Key Features:**
* **Standardized Structure:** Unlike ad-hoc shell scripts, these tools maintain a consistent code structure that is easily version-controlled and shared.
* **Multi-Node Execution:** Designed to execute code across multiple remote resources simultaneously.
* **Idempotency:** A critical feature where running the same code multiple times yields the exact same state. It only applies necessary changes to bring the environment to the defined state, leaving already compliant configurations untouched.

<img width="494" height="259" alt="image" src="https://github.com/user-attachments/assets/2dce9aed-5a0c-496d-8676-8eeec3aa352c" />


### 2. Server Templating Tools

* **Examples:** Docker, Packer, Vagrant
* **Primary Use Case:** Creating custom, pre-configured images of virtual machines or containers.
* **Key Features:**
* **Pre-baked Dependencies:** Images contain all required software and dependencies out of the box, minimizing post-deployment installation steps.
* **Common Artifacts:** Examples include Amazon Machine Images (AMIs), DockerHub container images, or VM images from platforms like osboxes.org.
* **Immutable Infrastructure:** Promotes an architecture where deployed instances are never modified in place. If an update is required, the base template/image is modified, a new image is built, and the old instance is completely replaced by a new one.

<img width="819" height="513" alt="image" src="https://github.com/user-attachments/assets/78f89506-9b15-4978-9712-732abce39de1" />


### 3. Infrastructure Provisioning Tools

* **Examples:** Terraform, AWS CloudFormation
* **Primary Use Case:** Deploying and managing the foundational infrastructure components themselves (virtual machines, VPCs, subnets, security groups, storage).
* **Key Features:**
* **Declarative Approach:** Users define the desired end state of the infrastructure, and the tool determines how to achieve it.
* **Cloud Scope:** Can manage cloud-native services across various layers.
* **Platform Support:** While tools like AWS CloudFormation are cloud-specific (vendor-locked to AWS), tools like Terraform are vendor-agnostic and leverage provider plugins to support almost all major cloud platforms.

<img width="413" height="205" alt="image" src="https://github.com/user-attachments/assets/116daf8c-510f-43aa-b2d5-6d70a2a72eb2" />

---

## Quick Reference Comparison

| Category | Primary Focus | Core Philosophy | Example Tools |
| --- | --- | --- | --- |
| **Infrastructure Provisioning** | Creating hardware/cloud resources | Declarative bootstrapping | Terraform, CloudFormation |
| **Configuration Management** | Managing software on existing systems | Mutable & Idempotent updates | Ansible, Puppet, Chef, SaltStack |
| **Server Templating** | Creating golden images/containers | Immutable replacement | Docker, Packer, Vagrant |


---

### Topic Summary: Intro to IaC

Infrastructure as Code (IaC) replaces manual, error-prone cloud console clicking with readable, reusable code to manage infrastructure. The IaC landscape is divided into three main categories:

1. **Configuration Management** (e.g., Ansible) for maintaining and updating software on existing servers idempotently.
2. **Server Templating** (e.g., Packer, Docker) for creating immutable, pre-baked images that replace existing instances rather than updating them.
3. **Infrastructure Provisioning** (e.g., Terraform) for declaratively deploying the foundational cloud resources (VPCs, VMs, etc.) from scratch.

### Knowledge Check Q&A

**Q: Why is idempotency important in Configuration Management tools like Ansible?**
**A:** Idempotency ensures that no matter how many times you run the code, the system will only make the necessary changes to reach the desired state. If the server is already configured correctly, it will leave it exactly as is, preventing unintended modifications.

**Q: How does Server Templating promote "immutable infrastructure"?**
**A:** Instead of logging into a running server to install an update or patch, server templating requires you to update the base image itself. You then deploy a brand-new instance from that new image and destroy the old one, ensuring the running server is never modified in place.

**Q: What is the primary difference between Terraform and AWS CloudFormation?**
**A:** While both are infrastructure provisioning tools, CloudFormation is proprietary and locked to the AWS ecosystem. Terraform is vendor-agnostic and uses provider plugins to provision resources across almost any major cloud provider (AWS, Azure, GCP, etc.).

