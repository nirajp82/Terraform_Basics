# HashiCorp Configuration Language (HCL) Basics

This document details the structure of HashiCorp Configuration Language (HCL), the foundational syntax of Terraform, and maps out the standard workflow to provision your first resource.

---

## 1. HCL Syntax Structure

An HCL file consists of two primary elements: **Blocks** and **Arguments**.

<img width="235" height="95" alt="image" src="https://github.com/user-attachments/assets/0e6446b7-7b41-4236-8fd5-874d5fd702f0" />

* **Block:** Defined using curly braces `{}`. It represents an object or component of your infrastructure (e.g., a resource to be built).
* **Arguments:** Written inside blocks as `key = value` pairs. Arguments supply the specific configuration data required by that block.

### Anatomy of a Resource Block

Consider a basic example of managing a file on your local operating system (`local.tf`):

<img width="640" height="206" alt="image" src="https://github.com/user-attachments/assets/70dd6b42-d92e-4011-a658-b65678628885" />


```hcl
resource "local_file" "pet" {
  filename = "/root/pets.txt"
  content  = "We love pets."
}

```

Breaking down this code line-by-line:


| Part               | What is it?        | Who decides it? | Can you change it?                                                                                |
| ------------------ | ------------------ | --------------- | ------------------------------------------------------------------------------------------------- |
| `resource`         | **Block Type**     | Terraform       | ❌ No. Must be one of Terraform's block types (`resource`, `variable`, `output`, `provider`, etc.) |
| `"local_file"`     | **Resource Type**  | Provider        | ❌ No. Must be a valid resource type provided by the installed provider.                           |
| `"pet"`            | **Resource Name**  | You             | ✅ Yes. Any meaningful name (e.g., `pet`, `notes`, `my_file`).   A user-defined logical name that helps Terraform identify this specific resource within your configuration and allows you to reference it elsewhere in your Terraform code.                                  |
| `filename`         | **Argument Name**  | Provider        | ❌ No. Must be a supported argument for `local_file`.                                              |
| `"/root/pets.txt"` | **Argument Value** | You             | ✅ Yes. Any valid file path.                                                                       |
| `content`          | **Argument Name**  | Provider        | ❌ No. Must be a supported argument for `local_file`.                                              |
| `"We love pets."`  | **Argument Value** | You             | ✅ Yes. Any text you want to write to the file.                                                    |

### Easy rule to remember

* **Terraform decides** → Block types (`resource`, `variable`, `output`, etc.)
* **Provider decides** → Resource types (`local_file`, `aws_instance`) and argument names (`filename`, `content`)
* **You decide** → Resource names (`pet`) and argument values (`/root/pets.txt`, `"We love pets."`)

This **Terraform → Provider → You** rule works for almost every Terraform configuration, making it a good mental model to remember.

### How is `pet` used later?

Terraform references a resource using this format:

```text
<Resource Type>.<Resource Name>
```

In this example:

```text
local_file.pet
```

Here:

* `local_file` → tells Terraform **which type of resource** you're referring to.
* `pet` → identifies **which specific `local_file` resource** you mean.

For example, if you had two files:

```hcl
resource "local_file" "pet" {
  ...
}

resource "local_file" "notes" {
  ...
}
```

You would refer to them as:

```text
local_file.pet
local_file.notes
```

#### Create EC2
-  Creates an AWS EC2 virtual machine named webserver using the specified Amazon Machine Image (AMI) and launches it as a t2.micro instance.
-  
```hcl
resource "aws_instance" "webserver" {
  ami           = "ami-0c2f25c1f66a1ff4d"
  instance_type = "t2.micro"
}
```

- Creates an AWS S3 bucket named webserver-bucket-org-2207 and sets its access control list (ACL) to private, meaning only the bucket owner has access by default.

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "webserver-bucket-org-2207"
  acl    = "private"
}
```

---

## 2. The Core 4-Step Terraform Workflow

To translate your written code into actual infrastructure, you must follow a standard sequential execution workflow.

### Step 1: Write

Create a dedicated project directory (e.g., `/root/terraform-local-file`) and write your infrastructure code inside a file ending with the `.tf` extension (e.g., `local.tf`).

### Step 2: Initialize (`terraform init`)

Run this command within your project directory to prepare the environment.

* **Mechanism:** Terraform scans your `.tf` files, identifies the providers declared (e.g., the `local` provider), and automatically downloads the necessary binary plugin/driver into your workspace.

### Step 3: Plan (`terraform plan`)

Generates a dry-run execution blueprint showing what changes Terraform intends to perform.

* **Mechanism:** It compares your code against reality. It highlights resources to be added with a green plus (`+`) symbol.
* *Note: This step is entirely informational and does not modify real-world infrastructure.*

### Step 4: Apply (`terraform apply`)

Executes the planned changes on the target platform.

* **Mechanism:** It presents the execution plan one final time and pauses for user confirmation (`yes`). Once confirmed, Terraform executes the API actions to create, update, or delete the resources.

---

## 3. Post-Deployment Verification

After running an apply, you can inspect your environment using native OS utilities or Terraform tools:

* **OS Validation:** Using terminal commands to confirm physical creation (e.g., running `cat /root/pets.txt`).
* **`terraform show`:** This command inspects Terraform’s underlying state tracking database to print out the complete, actual runtime attributes of all deployed resources.

---

## 4. Documentation as a Source of Truth

Terraform supports hundreds of cloud and service providers (AWS, Azure, GCP, GitHub, Datadog). It is impossible to memorize every resource type or every argument.

The **Official Terraform Documentation** is your ultimate reference manual:

* **Required vs. Optional:** The documentation lists exactly which arguments are mandatory (e.g., for `local_file`, `filename` is required) and which are optional (e.g., `content`).

---

### Topic Summary: HCL Basics & Workflow

Terraform relies on HashiCorp Configuration Language (HCL) written in `.tf` files, where infrastructure components are structured into declarative blocks. A `resource` block specifies a provider type (e.g., `local_file` or `aws_instance`), a local name, and configuration arguments. Deploying this code requires following the core four-step pipeline: **Write** the code, **Init** the directory to download provider plugins, **Plan** to preview the execution diff, and **Apply** to confirm and perform the actual deployments. Deployed attributes can be reviewed using `terraform show`.

### Knowledge Check Q&A

**Q: In the block declaration `resource "aws_instance" "webserver"`, what do the second and third strings represent?**
**A:** The second string (`aws_instance`) represents the fixed resource type defined by the AWS cloud provider plugin. The third string (`webserver`) is a logical, user-defined name used to identify this specific instance within the Terraform code.

**Q: Does running `terraform plan` make changes to your infrastructure?**
**A:** No. `terraform plan` is a read-only command. It purely analyzes your code, determines the required actions, and displays an execution preview. No changes are applied until you run `terraform apply`.

**Q: What happens behind the scenes during the `terraform init` phase?**
**A:** Terraform analyzes your configuration files to find the resource providers you used. It then contacts the HashiCorp registry to download the appropriate provider plugins into your local directory so it can communicate with those specific platform APIs.

**Q: How can you find out which configuration arguments are optional or mandatory for a specific resource type?**
**A:** By consulting the official provider documentation at `registry.terraform.io`. It explicitly categorizes all acceptable arguments for every resource type as either required or optional.
