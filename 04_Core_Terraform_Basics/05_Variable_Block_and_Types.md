# The Variable Block: Arguments and Types

This document takes a close look at the **`variable`** block in Terraform — its three main arguments (`default`, `type`, `description`), primitive types (`string`, `number`, `bool`), and composite types (`list`, `map`, `set`, `object`, `tuple`), including how to access values and what happens when types do not match.

---

## 1. The Three Arguments of a `variable` Block

Every input variable is declared with a **`variable`** block. It supports three arguments:

| Argument | Required? | Purpose |
| --- | --- | --- |
| **`default`** | Optional | Value used when nothing else supplies the variable |
| **`type`** | Optional | Restricts what kind of value is allowed |
| **`description`** | Optional (recommended) | Human-readable explanation of what the variable is for |

```hcl
variable "content" {
  type        = string
  description = "Text written into the local file"
  default     = "I love pet!"
}
```

> **Best practice:** Always add a **`description`** so teammates (and future you) know what the variable controls. Add **`type`** when you want Terraform to **reject invalid values** before apply.

If **`type` is omitted**, Terraform defaults to **`any`** — any value shape is accepted with no type checking.

---

## 2. Primitive Types: `string`, `number`, `bool`

### `string`

A single text value — letters, numbers, symbols, spaces.

```hcl
variable "prefix" {
  type    = string
  default = "dog"
}
```

Usage: `var.prefix` → `"dog"`

### `number`

A single numeric value — integer or decimal, positive or negative.

```hcl
variable "length" {
  type    = number
  default = 2
}
```

Usage: `var.length` → `2`

### `bool`

Either **`true`** or **`false`**.

```hcl
variable "favorite_pet" {
  type    = bool
  default = true
}
```

Usage: `var.favorite_pet` → `true`

| Type | Accepts | Example default |
| --- | --- | --- |
| `string` | One text value | `"Hello"`, `"ami-abc123"` |
| `number` | One number | `2`, `-1`, `3.14` |
| `bool` | `true` or `false` | `true` |
| `any` *(implicit if type omitted)* | Anything | No validation |

---

## 3. Lists — Numbered Collections

A **`list`** holds an **ordered** sequence of values. Each item is called an **element** and is accessed by **index** in square brackets.

**Index always starts at `0`.**

```hcl
variable "prefix" {
  type = list(string)
  default = ["Mr", "Mrs", "Sir"]
}
```

| Index | Element |
| --- | --- |
| `0` | `"Mr"` |
| `1` | `"Mrs"` |
| `2` | `"Sir"` |

### Accessing list elements

```hcl
resource "local_file" "example" {
  filename = "root/greeting.txt"
  content  = var.prefix[0]   # Mr
}
```

| Expression | Value |
| --- | --- |
| `var.prefix[0]` | `"Mr"` |
| `var.prefix[1]` | `"Mrs"` |
| `var.prefix[2]` | `"Sir"` |

```hcl
# List of numbers
variable "ports" {
  type    = list(number)
  default = [80, 443, 8080]
}

# Usage
var.ports[0]   # 80
```

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart LR
    LIST["var.prefix"]
    LIST --> I0["[0] = Mr"]
    LIST --> I1["[1] = Mrs"]
    LIST --> I2["[2] = Sir"]

    style LIST fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style I0 fill:#374151,stroke:#9ca3af,color:#ffffff
    style I1 fill:#374151,stroke:#9ca3af,color:#ffffff
    style I2 fill:#374151,stroke:#9ca3af,color:#ffffff
```

---

## 4. Maps — Key-Value Pairs

A **`map`** stores values identified by **keys** — like a dictionary or hash table.

```hcl
variable "file_content" {
  type = map(string)
  default = {
    statement1 = "I love pet!"
    statement2 = "My favorite pet is Mrs. hiskers"
  }
}
```

### Accessing map values by key

```hcl
resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = var.file_content["statement2"]
}
```

| Expression | Value |
| --- | --- |
| `var.file_content["statement1"]` | `"I love pet!"` |
| `var.file_content["statement2"]` | `"My favorite pet is Mrs. hiskers"` |

```hcl
# Map of numbers
variable "instance_counts" {
  type = map(number)
  default = {
    dev  = 1
    prod = 5
  }
}

# Usage
var.instance_counts["prod"]   # 5
```

---

## 5. Type Constraints and Validation Errors

The **`type`** argument enforces shape. If **`default`** (or values from `.tfvars`) do not match, Terraform **fails before apply**.

### Wrong element type in a list

```hcl
variable "bad_list" {
  type = list(number)
  default = ["80", "443", "8080"]   # strings — NOT numbers
}
```

```text
Error: Invalid default value for variable

Default value is not compatible with the variable type constraint:
a number is required, but have string.
```

### Wrong value type in a map

```hcl
# Valid — map(string)
variable "tags_string" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
  }
}

# Valid — map(number)
variable "counts_number" {
  type = map(number)
  default = {
    web = 2
    db  = 1
  }
}
```

| Constraint | `default` must be |
| --- | --- |
| `list(string)` | `[ "a", "b" ]` |
| `list(number)` | `[ 1, 2, 3 ]` |
| `map(string)` | `{ key = "value" }` |
| `map(number)` | `{ key = 42 }` |

> Terraform validates types during **`terraform plan`** and **`terraform validate`** — you catch mismatches before anything is deployed.

---

## 6. Sets — Lists Without Duplicates

A **`set`** is like a list but **duplicate elements are not allowed**.

```hcl
# Valid set(string)
variable "valid_set" {
  type    = set(string)
  default = ["dev", "staging", "prod"]
}

# Valid set(number)
variable "port_set" {
  type    = set(number)
  default = [80, 443, 8080]
}
```

```hcl
# INVALID — duplicate "dev"
variable "invalid_set" {
  type    = set(string)
  default = ["dev", "staging", "dev"]
}
```

Terraform rejects duplicate values in a set default.

| | **List** | **Set** |
| --- | --- | --- |
| Order | **Ordered** — index `[0]`, `[1]` | Unordered collection |
| Duplicates | **Allowed** | **Not allowed** |
| Syntax | `[ "a", "b" ]` | Same bracket syntax |
| Use when | Order matters | Unique values only |

---

## 7. Objects — Combining Multiple Types

An **`object`** defines a **structured record** with named fields, each with its own type. You can combine strings, numbers, lists, and booleans in one variable.

Example: a cat named **Bella** with multiple attributes:

```hcl
variable "bella" {
  type = object({
    name         = string
    color        = string
    age          = number
    food         = list(string)
    favorite_pet = bool
  })

  default = {
    name         = "bella"
    color        = "brown"
    age          = 7
    food         = ["fish", "chicken", "turkey"]
    favorite_pet = true
  }
}
```

### Accessing object fields

```hcl
var.bella.name          # "bella"
var.bella.color         # "brown"
var.bella.age           # 7
var.bella.food[0]       # "fish"
var.bella.favorite_pet  # true
```

```mermaid
%%{init: {'theme': 'dark', 'flowchart': {'htmlLabels': true}}}%%
flowchart TD
    OBJ["var.bella"]
    OBJ --> N["name — string"]
    OBJ --> C["color — string"]
    OBJ --> A["age — number"]
    OBJ --> F["food — list of strings"]
    OBJ --> FP["favorite_pet — bool"]

    style OBJ fill:#1e3a5f,stroke:#60a5fa,color:#ffffff
    style N fill:#374151,stroke:#9ca3af,color:#ffffff
    style C fill:#374151,stroke:#9ca3af,color:#ffffff
    style A fill:#374151,stroke:#9ca3af,color:#ffffff
    style F fill:#312e81,stroke:#a78bfa,color:#ffffff
    style FP fill:#14532d,stroke:#4ade80,color:#ffffff
```

---

## 8. Tuples — Fixed Length, Mixed Types

A **`tuple`** looks like a list but is **stricter**:

| | **List** | **Tuple** |
| --- | --- | --- |
| Element types | **Same type** for all (`list(string)`) | **Different type per position** |
| Length | Can grow/shrink | **Fixed** — exact count enforced |

```hcl
variable "pet_tuple" {
  type = tuple([string, number, bool])

  default = ["cat", 7, true]
  #          ^       ^   ^
  #          string  num bool  — exactly 3 elements
}
```

| Index | Expected type | Example value |
| --- | --- | --- |
| `0` | `string` | `"cat"` |
| `1` | `number` | `7` |
| `2` | `bool` | `true` |

Usage:

```hcl
var.pet_tuple[0]   # "cat"
var.pet_tuple[1]   # 7
var.pet_tuple[2]   # true
```

### What causes errors

**Wrong type at a position:**

```hcl
default = ["cat", "seven", true]   # ERROR — index 1 must be number, not string
```

**Too many elements:**

```hcl
default = ["cat", 7, true, "dog"]   # ERROR — tuple expects exactly 3 elements
```

```text
Error: Invalid default value for variable

Incorrect attribute value type: length must be 3, but have 4.
```

---

## 9. Quick Reference: All Types

Every row below uses **one real variable name** from this lesson. The name in **`variable "..."`** is what you choose; **`var.<same_name>`** is how you read it in resources. Keys like **`dev`** or **`statement2`** are labels **inside** a map — not separate variables.

| Type | Variable name | Declare in `variables.tf` | Use in `main.tf` | Resolves to |
| --- | --- | --- | --- | --- |
| `string` | `content` | `variable "content" { type = string default = "I love pet!" }` | `content = var.content` | `"I love pet!"` |
| `number` | `length` | `variable "length" { type = number default = 2 }` | `length = var.length` *(random provider)* | `2` |
| `bool` | `favorite_pet` | `variable "favorite_pet" { type = bool default = true }` | `count = var.favorite_pet ? 1 : 0` | `true` |
| `list(string)` | `prefix` | `variable "prefix" { type = list(string) default = ["Mr", "Mrs", "Sir"] }` | `content = var.prefix[0]` | `"Mr"` |
| `list(number)` | `ports` | `variable "ports" { type = list(number) default = [80, 443, 8080] }` | `port = var.ports[1]` | `443` |
| `map(string)` | `file_content` | `variable "file_content" { type = map(string) default = { statement1 = "I love pet!" statement2 = "My favorite pet is Mrs. hiskers" } }` | `content = var.file_content["statement2"]` | `"My favorite pet is Mrs. hiskers"` |
| `map(number)` | `instance_counts` | `variable "instance_counts" { type = map(number) default = { dev = 1 prod = 5 } }` | `count = var.instance_counts["prod"]` | `5` |
| `set(string)` | `environments` | `variable "environments" { type = set(string) default = ["dev", "staging", "prod"] }` | `for_each = var.environments` *(no `[0]` — sets are unordered)* | unique strings only |
| `object({...})` | `bella` | `variable "bella" { type = object({ name = string age = number food = list(string) }) default = { name = "bella" age = 7 food = ["fish", "chicken"] } }` | `content = var.bella.food[0]` | `"fish"` |
| `tuple([...])` | `pet_tuple` | `variable "pet_tuple" { type = tuple([string, number, bool]) default = ["cat", 7, true] }` | `content = var.pet_tuple[1]` | `7` |
| `any` | `content` | `variable "content" { default = "I love pet!" }` *(no `type`)* | `content = var.content` | any shape accepted |

### Worked example: declaration → resource

The names in the **Declare** and **Use** columns always match. For a `map(number)`, the variable is **`instance_counts`**, keys are **`dev`** and **`prod`**, and you read one key with **`var.instance_counts["prod"]`** — not a different name like `counts`.

```hcl
# variables.tf
variable "file_content" {
  type = map(string)
  default = {
    statement1 = "I love pet!"
    statement2 = "My favorite pet is Mrs. hiskers"
  }
}

variable "instance_counts" {
  type = map(number)
  default = {
    dev  = 1   # key "dev"  → value 1
    prod = 5   # key "prod" → value 5
  }
}

variable "ports" {
  type    = list(number)
  default = [80, 443, 8080]
}
```

```hcl
# main.tf
resource "local_file" "pet" {
  filename = "root/pet.txt"
  content  = var.file_content["statement2"]
  #         variable name ─────┘              └── map key (not a variable)
}

# var.instance_counts["prod"] reads key "prod" from map instance_counts → 5
# var.ports[1] reads index 1 from list ports → 443 (index 0 would be 80)
```

| Expression | What it means | Value |
| --- | --- | --- |
| `var.file_content` | The whole map | `{ statement1 = "...", statement2 = "..." }` |
| `var.file_content["statement2"]` | Value for key **`statement2`** | `"My favorite pet is Mrs. hiskers"` |
| `var.instance_counts` | The whole map | `{ dev = 1, prod = 5 }` |
| `var.instance_counts["dev"]` | Value for key **`dev`** | `1` |
| `var.instance_counts["prod"]` | Value for key **`prod`** | `5` |
| `var.ports[0]` | First list element (index starts at 0) | `80` |
| `var.ports[1]` | Second list element | `443` |

---

## 10. Hands-On Lab

In your configuration directory:

1. Add `description` and `type` to existing variables from the Input Variables lesson.
2. Create a `list(string)` variable `prefix` — use `var.prefix[0]` in a resource.
3. Create a `map(string)` variable `file_content` — use `var.file_content["statement2"]` for `local_file` content.
4. Intentionally mismatch types (e.g., `list(number)` with string defaults) — run `terraform validate` and read the error.
5. Create a `set(string)` with a duplicate value — confirm Terraform rejects it.
6. Create an `object` variable `bella` — reference `var.bella.name` and `var.bella.food[0]`.
7. Create a `tuple([string, number, bool])` — try adding a fourth element and confirm the error.

---

### Topic Summary: Variable Block and Types

A **`variable`** block supports **`default`**, **`type`**, and **`description`**. Primitive types are **`string`**, **`number`**, and **`bool`**. Omitting `type` defaults to **`any`**. **Lists** are ordered collections accessed by index starting at **`0`**. **Maps** are key-value pairs accessed with **`var.name["key"]`**. **Sets** behave like lists but forbid duplicates. **Objects** combine named fields of different types. **Tuples** enforce a **fixed length** and **specific type per position**. Type constraints cause **`terraform plan`** / **`validate`** to fail when defaults or inputs do not match.

### Knowledge Check Q&A

**Q: What are the three arguments of a Terraform `variable` block?**

**A:** **`default`** (fallback value), **`type`** (optional type constraint), and **`description`** (optional documentation — recommended best practice).

**Q: What is the default type if you omit the `type` argument?**

**A:** **`any`** — Terraform accepts any value shape without type validation.

**Q: How do you access the second element of a list variable named `prefix`?**

**A:** **`var.prefix[1]`** — list indexes start at **0**, so index `1` is the second element.

**Q: How do you read the value for key `statement2` from a map variable `file_content`?**

**A:** **`var.file_content["statement2"]`** — use the key in square brackets after the variable name.

**Q: What happens if you declare `type = list(number)` but provide string defaults like `["80", "443"]`?**

**A:** Terraform returns a **type error** — e.g., *"a number is required, but have string"* — during **`terraform plan`** or **`validate`**.

**Q: What is the difference between a list and a set?**

**A:** Both hold collections, but a **set cannot contain duplicate values**. Lists are **ordered** and indexed; sets are used when **uniqueness** matters.

**Q: What is the difference between a list and a tuple?**

**A:** A **list** requires all elements to share one type (`list(string)`). A **tuple** defines a **fixed number of elements** with **different types per position** — e.g., `tuple([string, number, bool])` must have exactly three values of those exact types.

**Q: How do you access the `age` field of an object variable named `bella`?**

**A:** **`var.bella.age`** — use dot notation for object field names.

**Q: Why would adding a fourth element to a `tuple([string, number, bool])` default fail?**

**A:** A tuple enforces an **exact element count**. Three types were declared, so exactly **three** values must be provided — a fourth value violates the constraint.
