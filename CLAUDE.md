# CLAUDE.md - OpenTofu Rules

## Code Quality
- Add validation rules to variables
- ALL files must end with trailing newline
- Consolidate data sources to minimize API calls
- Consolidate defaults in `var.default` structure
- Extract complex conditional logic to computed locals
- Mark sensitive values appropriately
- No comments - code should be self-explanatory
- Pre-compute expensive operations in locals
- Run `tofu fmt` after every change
- Use modern syntax (avoid `element()`, prefer direct indexing)
- Use OpenTofu >= 1.8
- Use `type = any` for complex nested structures

## Commands
```bash
tofu fmt && tofu validate && tofu plan
git add . && git commit -m "Update OpenTofu configuration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## File Organization
- Data sources: All in `data.tf`
- Locals: Split into `locals_*.tf` files by function
- Outputs: All in `outputs.tf`
- Providers: In `providers.tf` and `terraform.tf`
- Variables: All in `variables.tf` with proper types/descriptions

## Locals Formatting
- All locals must start with the filename prefix (e.g., `locals_dns.tf` → all locals start with `dns_`)
- Add a blank line between each local definition
- Sort all locals alphabetically by name

## Sorting Rules
Sort alphabetically and recursively by:
1. Block type
2. Data/resource source type
3. Data/resource name
4. All keys within blocks recursively

### Key Ordering Within Blocks
1. `count` and `for_each` at the top with blank line after
2. Keys with simple values (single-line strings, numbers, bools, null)
3. Keys with complex values (arrays, multiline strings, objects, maps)
4. Within nested objects, apply same recursive sorting rules

### Simple vs Complex Values
- Complex: Arrays (even single-item), multiline strings, objects, maps
- Simple: Single-line strings, numbers, booleans, null values
