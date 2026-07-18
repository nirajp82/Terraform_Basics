# Chapter Summary: Lifecycle Rules

## 1. The `lifecycle` Block

Goes directly inside a `resource` block to override Terraform's default destroy-then-create behavior for that resource.

## 2. `create_before_destroy`

On a forced replacement, creates the new resource before destroying the old one — reversing the default order.

## 3. `prevent_destroy`

Rejects any `apply` that would destroy the resource. Does not block `terraform destroy`, which still works — it only guards against accidental deletion via configuration changes.

## 4. `ignore_changes`

Takes a list of attribute names (or the `all` keyword) and stops Terraform from correcting drift on them — an external change to a listed attribute is left alone instead of reverted on the next `apply`.

---

## Knowledge Check Q&A

**Q: Where does a `lifecycle` block go?**
**A:** Directly inside the `resource` block whose behavior it should change.

**Q: What does `create_before_destroy = true` change?**
**A:** It creates the replacement resource before destroying the old one, instead of after.

**Q: Does `prevent_destroy = true` stop a resource from ever being destroyed?**
**A:** No — it only blocks destruction via configuration change + `apply`. `terraform destroy` still works regardless.

**Q: What kind of resource is `prevent_destroy` especially useful for?**
**A:** Resources that shouldn't be deleted by accident, like a database — losing it means losing data.

**Q: What does adding an attribute to `ignore_changes` do?**
**A:** Terraform stops trying to correct drift on that attribute, leaving external changes to it alone instead of reverting them.

**Q: What does `ignore_changes` accept?**
**A:** A list of attribute names, or the `all` keyword to ignore changes to every attribute on the resource.
