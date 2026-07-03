# Agent Instructions: Transcript → Training README

This project documents a **Terraform for Beginners** course (Udemy). Each lesson is a polished Markdown study guide derived from a raw training transcript. Your job is to turn transcripts into documents that match the style and quality of the existing lessons.

**Reference examples (read these before writing):**
- `02_Intro_IAC/03_Terraform.md` — deep conceptual walkthrough with a worked migration example
- `03_GettingStarted/02_HCL_Basics.md` — syntax breakdown, tables, workflow steps, code anatomy

---

## When the User Provides a Transcript

Follow this workflow every time.

### 1. Gather context

- Read the transcript fully.
- Identify the **module folder** (e.g., `02_Intro_IAC`, `03_GettingStarted`) and **next file number** in that folder.
- Skim 1–2 existing lesson files in the same module for tone and structure.
- Note any **images, diagrams, or demo commands** mentioned in the transcript.

### 2. Choose the output path and filename

Use numbered folders and files:

```
<ModuleFolder>/<NN>_<Topic_Name>.md
```

Examples: `03_GettingStarted/03_Variables.md`, `02_Intro_IAC/04_State.md`

- Use `NN` as the next sequential number in that folder.
- Use `PascalCase` or `Snake_Case` for the topic segment (match the folder’s existing style).
- Do **not** overwrite an existing lesson unless the user explicitly asks to update it.

### 3. Write the document

Produce a **study guide**, not a verbatim transcript. Remove filler speech, repetition, and off-topic asides. Keep all technical substance.

---

## Required Document Structure

Every lesson file must include these sections in order.

### A. Title and scope (top of file)

```markdown
# <Clear Topic Title>

One-sentence description of what this document covers and why it matters.
```

### B. Body sections (use `---` between major parts)

Organize content with numbered `##` headings when the lesson has a natural sequence (e.g., `## 1. Installing Terraform`, `## 2. Configuration Environment`).

Within sections, use:

| Element | When to use |
| --- | --- |
| `###` subheadings | Subtopics within a section |
| Bullet lists | Features, steps, benefits, drawbacks |
| **Bold** | Key terms on first use (e.g., **Provider**, **State**, **HCL**) |
| Tables | Comparisons, anatomy breakdowns, workflow matrices |
| Blockquotes (`>`) | Golden rules, important notes, warnings |
| Code fences | HCL, bash, PowerShell, diff output — always with a language tag |
| Images | `<img ... src="URL" />` when the user supplies URLs or they appear in prior lessons |

### C. Topic Summary (required, near the end)

```markdown
### Topic Summary: <Short Topic Name>

2–4 sentences that recap the entire lesson in plain language. A reader should understand the core idea without re-reading the full doc.
```

### D. Knowledge Check Q&A (required, at the end)

```markdown
### Knowledge Check Q&A

**Q: <Question>**
**A:** <Clear, complete answer>

(Include 4–8 questions covering the most important concepts from the lesson.)
```

---

## Content Quality Rules

### Transform, don’t transcribe

- Convert spoken explanations into clear, scannable prose.
- Replace vague phrases (“this thing”, “over here”) with precise terms.
- Group related ideas; don’t follow the speaker’s digressions line-by-line.

### Teach with structure

- **Define before detail** — What is X? → How does it work? → Example → Workflow.
- **Use mental models** when helpful (e.g., “Terraform decides → Provider decides → You decide”).
- **Prefer tables** for “who decides what”, comparisons, and plan/apply diff summaries.
- **Break down code line-by-line** for any HCL example shown in the transcript.

### Code examples

- Use realistic but minimal HCL (`local_file`, `aws_instance`, etc.).
- Show command sequences for workflows: `terraform init` → `plan` → `apply`.
- Use `diff` fences when illustrating plan output (`+ create ...`).
- Fix obvious typos from the transcript; don’t copy broken syntax.

### Consistency with existing lessons

- Match terminology already used in the repo: **desired state**, **current state**, **drift**, **Provider**, **Resource**, **State**, **Data Source**, **Import**.
- Where the course uses the **Okta → CyberArk migration** analogy, reuse it for identity/IaC concepts — but only when the transcript topic supports it.
- Keep the professional, course-note tone: direct, educational, no casual slang.

### Images

- Preserve GitHub `user-attachments` image URLs when they appear in the transcript or sibling lessons.
- If the transcript references a slide but no URL is given, insert a placeholder comment: `<!-- TODO: Add diagram for <description> -->` and mention it briefly to the user.

---

## Section Patterns to Reuse

### Workflow lessons (init / plan / apply)

For each phase, explain:

1. **What** the command does (one line)
2. **Mechanism** — what Terraform reads, downloads, or compares
3. **What does *not* happen** (e.g., plan does not change infrastructure)

### Syntax lessons (HCL, variables, etc.)

Include:

- Anatomy table: Part | What is it? | Who decides? | Can you change it?
- A “rule to remember” callout
- At least one full resource block with a short explanation

### Concept lessons (providers, state, IaC categories)

Include:

- Definition paragraph
- Bullet list of characteristics
- Comparison table when contrasting two approaches
- One concrete example tied to a real provider or resource type

---

## What NOT to Do

- Do not create a wall of transcript quotes.
- Do not skip the Topic Summary or Knowledge Check Q&A.
- Do not invent facts, commands, or APIs not supported by the transcript.
- Do not add unrelated modules, marketing content, or lengthy preambles.
- Do not create or edit `README.md` unless the user asks for a chapter index update.

---

## Deliverable Checklist

Before finishing, verify:

- [ ] Filename and folder follow `NN_Topic_Name.md` convention
- [ ] H1 title + one-sentence scope paragraph
- [ ] Logical `##` / `###` hierarchy with `---` between major parts
- [ ] Key terms in **bold**; tables or lists where they aid scanning
- [ ] Code blocks have correct language tags and valid syntax
- [ ] `### Topic Summary:` section present
- [ ] `### Knowledge Check Q&A` with 4–8 Q&A pairs
- [ ] No transcript filler; technical accuracy preserved
- [ ] Style matches `03_Terraform.md` and `02_HCL_Basics.md`

---

## Quick Reference: Ideal Lesson Flow

```
# Title
Scope sentence

---

## 1. First major concept
Definition, bullets, optional table/image

## 2. Second major concept
Example code + breakdown

## 3. Workflow or hands-on steps
Step-by-step with commands

---

### Topic Summary: ...
Recap paragraph

### Knowledge Check Q&A
Q/A pairs
```

When the user says *“here is the transcript”*, apply this guide and write the lesson file without asking for permission to create it — unless the target folder or filename is ambiguous, in which case propose the path first.
