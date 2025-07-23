# CLAUDE.md - OpenTofu Project Rules

## Code Quality
- **ALL files must end with trailing newline**
- **Run `tofu fmt` after every change**
- **Use OpenTofu >= 1.8** for latest features and stability
- Add validation rules to variables for better error handling
- Consolidate data sources to minimize API calls
- Extract complex conditional logic to computed locals
- Mark sensitive values appropriately
- Pre-compute expensive operations in locals
- Remove useless comments
- Use `type = any` for complex nested structures
- Use modern syntax (avoid `element()`, prefer direct indexing)

## Directory Structure
```
Services/
├── data.tf                  # All data sources
├── locals_*.tf              # All locals
├── variables.tf             # Variable definitions
├── outputs.tf               # Output definitions
├── *.tf                     # Resource files
└── terraform.tfvars         # Instance values
```

## File Organization
- **Data sources**: All in `data.tf`
- **Locals**: Split into `locals_*.tf` files by function
- **Outputs**: All in `outputs.tf`
- **Providers**: In `providers.tf` and `terraform.tf`
- **Variables**: All in `variables.tf` with proper types/descriptions

## Locals Formatting
**In `locals_*.tf` files:**
- Add a blank line between each local definition
- Single-line locals above multi-line locals when practical
- Sort all locals alphabetically by name

## Sorting Rules
**ALWAYS sort alphabetically by:**
1. Block type
2. Data/resource source type
3. Data/resource name

## Validate & Commit
**After every change:**
```bash
tofu fmt && tofu validate && tofu plan
```

**Then auto-commit:**
```bash
git add . && git commit -m "Update OpenTofu configuration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```
