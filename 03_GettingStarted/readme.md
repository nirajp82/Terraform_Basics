# Chapter Summary: Getting Started with Terraform


## 1. Installing Terraform

Terraform is distributed by HashiCorp as a **single, compiled binary** — no complex install process required.

* **Download:** Get the executable for your OS from `www.terraform.io`, or install via a package manager (`brew tap hashicorp/tap && brew install hashicorp/tap/terraform` on macOS; `winget install -e --id Hashicorp.Terraform` or `choco install terraform` on Windows).
* **Verify:** Run `terraform version` to confirm it's on your system `PATH`.
* **Configuration language:** All Terraform code lives in files ending in `.tf`, written in **HCL (HashiCorp Configuration Language)**. Any text editor works; VS Code with the Terraform extension is common.

### What Is a Resource?

A **resource** is the fundamental unit Terraform manages — from a local text file to an AWS EC2 instance, an S3 bucket, or an Azure database. To learn Terraform's lifecycle mechanics without cloud cost or complexity, early labs use simple local/utility resource types:

* **`local_file`** — creates and manages a file on the local filesystem.
* **`random_pet`** — generates a random identifier (a "pet name").

Once these fundamentals click, the exact same lifecycle applies to real cloud resources later in the course.

---

## 2. HCL Basics and the Core Workflow

An HCL file is built from **blocks** (`{ }`) and **arguments** (`key = value` pairs inside them).

### Anatomy of a Resource Block

```hcl
resource "local_file" "pet" {
  filename = "/root/pets.txt"
  content  = "We love pets."
}
```

| Part | What is it? | Who decides? |
| --- | --- | --- |
| `resource` | Block type | Terraform |
| `"local_file"` | Resource type | Provider |
| `"pet"` | Resource name | You |
| `filename`, `content` | Argument names | Provider |
| Their values | Argument values | You |

**Mental model:** Terraform decides block types → the Provider decides resource types and argument names → You decide resource names and argument values.

Reference a resource elsewhere in code as `<Resource Type>.<Resource Name>` — e.g. `local_file.pet`.

### The Core 4-Step Workflow

1. **Write** — author `.tf` files in a project directory.
2. **Init** (`terraform init`) — scans your code, detects required providers, downloads their plugins.
3. **Plan** (`terraform plan`) — a read-only dry run showing what would be added/changed/destroyed. **Does not touch real infrastructure.**
4. **Apply** (`terraform apply`) — executes the plan after confirmation, making the real API calls.

After deploying, `terraform show` prints the full runtime state of everything Terraform manages. The **official Terraform Registry documentation** is the definitive source for which arguments are required vs. optional for any resource type.

### What Does `plan` Actually Compare?

`terraform plan` is safe to run as often as you like — it's read-only. It computes its diff from three sources, all tied to the same project folder (the directory where `terraform init` was run):

| Source | Where it lives | Represents |
| --- | --- | --- |
| Your code | `*.tf` files in the project folder | Desired state |
| State file | `terraform.tfstate` in the same project folder | Last known state |
| Real infrastructure | Not a file — queried live via the Provider API | Actual state right now |

`terraform apply`, by contrast, should only be run when you're ready to make the change for real — it re-runs the same plan logic, shows the same diff, and pauses for a `yes` confirmation before touching anything.

### Idempotency: Running the Workflow Twice

Terraform is **idempotent** — re-running `init`/`plan`/`apply` against code that hasn't changed should do nothing the second time:

| Command | 1st run (resource doesn't exist) | 2nd run (no code change) |
| --- | --- | --- |
| `terraform init` | Downloads the provider plugin | No-op — plugin already present |
| `terraform plan` | Shows `1 to add` | Shows `No changes` |
| `terraform apply` | Creates the resource, prompts for `yes` | Nothing to do — exits immediately |

---

## Knowledge Check Q&A

**Q: What are the general steps to install Terraform on any operating system?**
**A:** Download the single binary executable for your OS from the official website (or a package manager) and ensure it's on your system's `PATH` so it runs from any terminal directory.

**Q: What file extension does Terraform look for when executing infrastructure code?**
**A:** Terraform looks for files with the `.tf` extension, written in HCL.

**Q: Why does the course start with `local_file` and `random_pet` instead of cloud resources like AWS EC2?**
**A:** Local/utility resources isolate the learning process — you master HCL syntax, state tracking, and resource lifecycles without cloud authentication, network latency, or unexpected bills.

**Q: In `resource "aws_instance" "webserver"`, what do the second and third strings represent?**
**A:** The second string (`aws_instance`) is the fixed resource type defined by the provider. The third string (`webserver`) is a user-defined logical name used to reference this specific resource elsewhere in the code.

**Q: Does running `terraform plan` make changes to your infrastructure?**
**A:** No. `plan` is read-only — it previews the actions Terraform would take. Nothing changes until `terraform apply` runs.

**Q: What happens behind the scenes during `terraform init`?**
**A:** Terraform scans your configuration files for the providers you reference, then downloads the matching plugin binaries from the Terraform Registry into your project directory.

**Q: How can you find out which configuration arguments are required or optional for a resource type?**
**A:** Check that resource's page on `registry.terraform.io` — it lists every argument and marks each as required or optional.

**Q: When `terraform plan` computes its diff, exactly which files does it compare, and from where?**
**A:** It compares the `*.tf` files and the `terraform.tfstate` file, both in the same project folder (the directory where `terraform init` was run), against the real infrastructure it queries live via the Provider API. The provider side isn't a file — Terraform asks the actual platform (e.g., the filesystem or a cloud API) what currently exists.

**Q: If you run `terraform plan` and `terraform apply` twice in a row with no code changes, what happens the second time?**
**A:** Nothing. `terraform init` is a no-op since the provider plugin is already downloaded, `terraform plan` reports "No changes," and `terraform apply` exits immediately without prompting — this is Terraform's idempotency in action.
