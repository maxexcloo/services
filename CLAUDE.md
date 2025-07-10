# CLAUDE.md - OpenTofu Project Rules

## File Organization
- **Data sources**: All in `data.tf`
- **Locals**: Split into `locals_*.tf` files by function
- **Variables**: All in `variables.tf` with proper types/descriptions
- **Outputs**: All in `outputs.tf`
- **Providers**: In `providers.tf` and `terraform.tf`

## Sorting Rules
**ALWAYS sort alphabetically by:**
1. Block type
2. Data/resource source type
3. Data/resource name

**Use explicit `depends_on` for dependencies that conflict with alphabetical order.**

## Code Quality
- Remove useless comments
- Use `type = any` for complex nested structures
- Pre-compute expensive operations in locals
- Consolidate data sources to minimize API calls
- Mark sensitive values appropriately

## Validation & Commit
**Before any changes:**
```bash
tofu validate && tofu plan
```

**After changes, auto-commit:**
```bash
git add . && git commit -m "Update OpenTofu configuration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

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
