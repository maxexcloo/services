# CLAUDE.md - OpenTofu Project Rules

## Code Quality
- **ALL files must end with trailing newline**
- **Run `tofu fmt` after every change**
- Consolidate data sources to minimize API calls
- Mark sensitive values appropriately
- Pre-compute expensive operations in locals
- Remove useless comments
- Use `type = any` for complex nested structures

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

## Sorting Rules
**ALWAYS sort alphabetically by:**
1. Block type
2. Data/resource source type
3. Data/resource name

**Use explicit `depends_on` for dependencies that conflict with alphabetical order.**

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
