#!/bin/bash

# Documentation Generator
# Generates comprehensive documentation for all templates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "📚 Generating Documentation"
echo "================================================"

# Create docs directory
mkdir -p docs

# Generate main documentation
print_status "Generating main documentation..."

# Generate template index
cat > docs/TEMPLATES.md << 'EOF'
# Available Templates

This document lists all available templates in Templatizer.

## Template Index

EOF

# Add each template to the index
for template_dir in templates/*/; do
    if [ -d "$template_dir" ] && [ "$(basename "$template_dir")" != "*.json" ]; then
        template_name=$(basename "$template_dir")
        if [ -f "$template_dir/template.json" ]; then
            template_desc=$(jq -r '.description' "$template_dir/template.json")
            echo "- **[${template_name}](templates/${template_name}/README.md)**: ${template_desc}" >> docs/TEMPLATES.md
        fi
    fi
done

# Generate individual template documentation
print_status "Generating individual template documentation..."

for template_dir in templates/*/; do
    if [ -d "$template_dir" ] && [ "$(basename "$template_dir")" != "*.json" ]; then
        template_name=$(basename "$template_dir")
        print_status "Processing template: $template_name"
        
        # Create template README
        cat > "$template_dir/README.md" << EOF
# $(jq -r '.name' "$template_dir/template.json")

$(jq -r '.description' "$template_dir/template.json")

## Quick Start

\`\`\`bash
# Make the script executable
chmod +x create_rails_app.sh

# Create a new app (will be created in parent directory)
./create_rails_app.sh myapp

# Navigate to your new app
cd ../myapp

# Start the development server
bin/dev
\`\`\`

## Features

$(jq -r '.features[] | "- " + .' "$template_dir/template.json")

## Requirements

$(jq -r '.dependencies | to_entries[] | "- **" + .key + "**: " + .value' "$template_dir/template.json")

## Framework

- **Framework**: $(jq -r '.framework' "$template_dir/template.json")
- **Version**: $(jq -r '.framework_version' "$template_dir/template.json")

## Validation

This template includes the following validation checks:

$(jq -r '.validation_checks[] | "- " + .' "$template_dir/template.json")

## Troubleshooting

If you encounter issues:

1. **Check system requirements**: Ensure all dependencies are installed
2. **Run debug mode**: \`./scripts/debug-template.sh $template_name detailed\`
3. **Check logs**: Look for error messages in the output
4. **Verify database**: Ensure PostgreSQL is running and accessible

## Customization

After creating your app, you can customize:

- **Branding**: Update app name, colors, and logos
- **Features**: Add or remove functionality
- **Styling**: Modify Tailwind CSS classes
- **Database**: Add new models and migrations

## Support

- **Issues**: Create a GitHub issue
- **Documentation**: Check the main README.md
- **Examples**: Look at the examples directory

---

**Template Version**: $(jq -r '.version' "$template_dir/template.json")
**Author**: $(jq -r '.author' "$template_dir/template.json")
EOF
    fi
done

# Generate API documentation
print_status "Generating API documentation..."

cat > docs/API.md << 'EOF'
# Templatizer API

This document describes the Templatizer API for template developers.

## Template Configuration

Templates are configured using a `template.json` file with the following structure:

```json
{
  "name": "Template Name",
  "description": "Template description",
  "version": "1.0.0",
  "author": "Author Name",
  "framework": "rails",
  "framework_version": "8.0",
  "dependencies": {
    "ruby": ">= 3.1.0",
    "rails": ">= 8.0.0"
  },
  "features": [
    "authentication",
    "tailwind-css"
  ],
  "validation_checks": [
    "database_connection",
    "migration_success"
  ]
}
```

## Script Requirements

Template scripts must follow these requirements:

### Required Functions

- **Error handling**: Use `set -e` and proper error messages
- **Conflict detection**: Check for existing directories/databases
- **User prompts**: Ask for confirmation before overwriting
- **Parent directory**: Create apps in `../app_name`

### Required Variables

- `APP_NAME`: The application name
- `APP_NAME_LOWER`: Lowercase version of the name
- `TARGET_DIR`: Target directory (usually `../$APP_NAME_LOWER`)

### Required Functions

- `print_status()`: Info messages
- `print_success()`: Success messages
- `print_warning()`: Warning messages
- `print_error()`: Error messages

## Testing API

### Test Commands

```bash
# Test a specific template
./scripts/test-template.sh template_name

# Run all tests
./scripts/run-tests.sh

# Debug a template
./scripts/debug-template.sh template_name [level]
```

### Debug Levels

- `basic`: Basic analysis
- `detailed`: Detailed analysis with syntax checking
- `verbose`: Verbose analysis with full content review

## Validation Checks

Templates can include these validation checks:

- `database_connection`: Test database connectivity
- `migration_success`: Verify migrations run successfully
- `tailwind_compilation`: Check Tailwind CSS compilation
- `authentication_models`: Validate authentication setup
- `routes_configuration`: Check route configuration

## Error Handling

Templates should handle these common errors:

- **Directory conflicts**: Check and prompt for overwrite
- **Database conflicts**: Reset database if needed
- **Migration errors**: Handle duplicate indexes
- **Dependency issues**: Check for required tools
- **Permission errors**: Handle file permission issues
EOF

# Generate troubleshooting guide
print_status "Generating troubleshooting guide..."

cat > docs/TROUBLESHOOTING.md << 'EOF'
# Troubleshooting Guide

This guide helps you resolve common issues with Templatizer.

## Common Issues

### 1. Directory Already Exists

**Error**: `Directory ../myapp already exists!`

**Solution**: The template detects existing directories and asks for confirmation. Choose 'y' to overwrite or 'n' to cancel.

### 2. Database Connection Issues

**Error**: `PG::ConnectionBad: could not connect to server`

**Solution**: 
- Ensure PostgreSQL is running: `brew services start postgresql` (macOS) or `sudo systemctl start postgresql` (Linux)
- Check database credentials
- Verify PostgreSQL is accessible

### 3. Migration Errors

**Error**: `PG::DuplicateTable: ERROR: relation "users" already exists`

**Solution**: The template now handles this automatically by resetting the database when overwriting.

### 4. Tailwind CSS Issues

**Error**: `Specified input file does not exist`

**Solution**: The template now creates the required Tailwind CSS files automatically.

### 5. Permission Errors

**Error**: `Permission denied`

**Solution**: 
- Make scripts executable: `chmod +x create_rails_app.sh`
- Check directory permissions
- Run with appropriate user privileges

## Debugging Tools

### Template Debugger

```bash
# Basic debugging
./scripts/debug-template.sh template_name

# Detailed debugging
./scripts/debug-template.sh template_name detailed

# Verbose debugging
./scripts/debug-template.sh template_name verbose
```

### Test Runner

```bash
# Test specific template
./scripts/test-template.sh template_name

# Run all tests
./scripts/run-tests.sh
```

## System Requirements

### Required Tools

- **Ruby**: 3.1+ (check with `ruby --version`)
- **Rails**: 8.0+ (check with `rails --version`)
- **PostgreSQL**: 14+ (check with `psql --version`)
- **Node.js**: 18+ (check with `node --version`)
- **Git**: Latest (check with `git --version`)

### Installation Commands

```bash
# macOS (using Homebrew)
brew install ruby postgresql node

# Ubuntu/Debian
sudo apt-get install ruby postgresql nodejs npm

# CentOS/RHEL
sudo yum install ruby postgresql nodejs npm
```

## Getting Help

### GitHub Issues

Create an issue with:
- Template name and version
- Steps to reproduce
- Expected vs actual behavior
- System information
- Error messages and logs

### Debug Information

When reporting issues, include:

```bash
# System information
uname -a
ruby --version
rails --version
psql --version
node --version

# Template debug output
./scripts/debug-template.sh template_name verbose

# Test output
./scripts/test-template.sh template_name
```

## Contributing Fixes

If you find a solution:

1. **Test the fix**: Ensure it works for your use case
2. **Document the solution**: Add it to this guide
3. **Submit a PR**: Include the fix and documentation
4. **Update tests**: Add test cases to prevent regression

## Advanced Troubleshooting

### Database Issues

```bash
# Check PostgreSQL status
brew services list | grep postgresql

# Reset PostgreSQL
brew services restart postgresql

# Check database connections
psql -l
```

### Ruby/Rails Issues

```bash
# Check Ruby version
ruby --version

# Check Rails installation
rails --version

# Reinstall Rails if needed
gem install rails
```

### Node.js Issues

```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Update Node.js if needed
brew upgrade node
```

### Template Issues

```bash
# Check template syntax
bash -n templates/template_name/create_rails_app.sh

# Validate template configuration
jq empty templates/template_name/template.json

# Run template in debug mode
./scripts/debug-template.sh template_name verbose
```
EOF

# Generate examples documentation
print_status "Generating examples documentation..."

mkdir -p examples
cat > examples/README.md << 'EOF'
# Templatizer Examples

This directory contains examples of how to use Templatizer templates.

## Basic Usage

### Creating a Rails App

```bash
# Navigate to templatizer directory
cd templatizer

# Make script executable
chmod +x templates/rails-modern/create_rails_app.sh

# Create a new Rails app
./templates/rails-modern/create_rails_app.sh MyApp

# Navigate to your new app
cd ../MyApp

# Start the development server
bin/dev
```

### Customizing Your App

After creating your app, you can customize:

1. **App Name**: Update `config/application.rb`
2. **Branding**: Modify views and styling
3. **Features**: Add new models and controllers
4. **Styling**: Update Tailwind CSS classes

## Advanced Examples

### Multiple Apps

```bash
# Create multiple apps
./templates/rails-modern/create_rails_app.sh BlogApp
./templates/rails-modern/create_rails_app.sh EcommerceApp
./templates/rails-modern/create_rails_app.sh PortfolioApp
```

### Custom Templates

```bash
# Create your own template
mkdir templates/my-template
# ... add your template files
./scripts/test-template.sh my-template
```

## Troubleshooting Examples

### Debug a Template

```bash
# Basic debugging
./scripts/debug-template.sh rails-modern

# Detailed debugging
./scripts/debug-template.sh rails-modern detailed
```

### Test a Template

```bash
# Test specific template
./scripts/test-template.sh rails-modern

# Run all tests
./scripts/run-tests.sh
```

## Best Practices

1. **Always test templates**: Use the testing framework
2. **Handle conflicts**: Check for existing directories
3. **Provide feedback**: Use clear status messages
4. **Error handling**: Include proper error messages
5. **Documentation**: Document your templates well
EOF

print_success "Documentation generation completed!"
print_status "Generated documentation:"
echo "  - docs/TEMPLATES.md: Template index"
echo "  - docs/API.md: API documentation"
echo "  - docs/TROUBLESHOOTING.md: Troubleshooting guide"
echo "  - examples/README.md: Usage examples"
echo "  - Individual template READMEs in templates/*/README.md"
