# CLAUDE.md - Development Guide

## Project Overview
**Purpose**: Infrastructure as Code for services deployment using OpenTofu  
**Status**: Active

## Commands
```bash
# Development
tofu fmt         # Format configuration
tofu validate    # Validate configuration
tofu plan        # Plan changes

# Build
tofu apply       # Apply configuration
```

## Tech Stack
- **Language**: HCL (HashiCorp Configuration Language)
- **Framework**: OpenTofu
- **Testing**: tofu validate and tofu plan

## Code Standards

### Organization
- **Config/Data**: Alphabetical and recursive (imports, dependencies, object keys)
- **Files**: Alphabetical in documentation and directories  
- **Functions**: Group by purpose, alphabetical within groups
- **Variables**: Alphabetical within scope

### Quality
- **Comments**: Minimal - only for complex business logic
- **Formatting**: Run tofu fmt before commits
- **KISS principle**: Keep it simple - prefer readable code over clever code
- **Naming**: snake_case for all resources and variables
- **Trailing newlines**: Required in all files

### HCL Conventions
- **Sorting order**: Key order within blocks: 1) count/for_each (with blank line after), 2) Simple values (strings, numbers, bools, null), 3) Complex values (arrays, objects, maps)
- **Type definitions**: Use `type = any` for complex nested structures
- **Locals prefix**: Locals in `locals_*.tf` files must start with filename prefix

## Documentation Standards

### README Guidelines
- **Badges**: Include relevant status badges (build, version, license)
- **Code examples**: Always include working examples in code blocks
- **Installation**: Provide copy-paste commands that work
- **Quick Start**: Get users running in under 5 minutes
- **Structure**: Title → Description → Quick Start → Features → Installation → Usage → Contributing

### Documentation Updates
- Avoid duplication between README, architecture, and development docs
- Link to detailed technical docs from overview docs
- Sort sections, lists, and references alphabetically when logical
- Update README.md and docs with every feature change

## Git Workflow
```bash
# After every change
tofu fmt && tofu validate && tofu plan
git add . && git commit -m "type: description"

# Always commit after verified working changes
# Keep commits small and focused
```

---

*Development guidelines for AI assistants working on this Infrastructure as Code project.*