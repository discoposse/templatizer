# Contributing to Templatizer

Thank you for your interest in contributing to Templatizer! This guide will help you get started with contributing templates, fixing bugs, and improving the project.

## 🚀 Quick Start

1. **Fork the repository**
2. **Clone your fork**: `git clone https://github.com/your-username/templatizer.git`
3. **Create a branch**: `git checkout -b feature/your-template-name`
4. **Make your changes**
5. **Test your changes**: `./scripts/run-tests.sh`
6. **Submit a pull request**

## 📋 Template Development Guide

### Creating a New Template

1. **Create template directory**:
   ```bash
   mkdir templates/your-template-name
   ```

2. **Create template configuration** (`templates/your-template-name/template.json`):
   ```json
   {
     "name": "Your Template Name",
     "description": "A brief description of what your template creates",
     "version": "1.0.0",
     "author": "Your Name",
     "framework": "rails",
     "framework_version": "8.0",
     "dependencies": {
       "ruby": ">= 3.1.0",
       "rails": ">= 8.0.0",
       "postgresql": ">= 14.0"
     },
     "features": [
       "authentication",
       "tailwind-css",
       "your-feature"
     ],
     "validation_checks": [
       "database_connection",
       "migration_success",
       "your_validation"
     ]
   }
   ```

3. **Create the template script** (`templates/your-template-name/create_rails_app.sh`):
   - Use the existing Rails template as a reference
   - Follow the established patterns
   - Include proper error handling
   - Add conflict detection and user prompts

### Template Script Requirements

Your template script must:

- ✅ **Use parent directory structure**: Create apps in `../app_name`
- ✅ **Handle conflicts**: Check for existing directories/databases
- ✅ **Ask for confirmation**: Prompt user before overwriting
- ✅ **Include error handling**: Use `set -e` and proper error messages
- ✅ **Follow naming conventions**: Use consistent variable names
- ✅ **Include validation**: Test the created application

### Template Script Template

```bash
#!/bin/bash

# Your Template Name
# Description of what this template creates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if app name is provided
if [ $# -eq 0 ]; then
    print_error "Please provide an app name"
    echo "Usage: $0 <app_name>"
    exit 1
fi

APP_NAME=$1
APP_NAME_LOWER=$(echo $APP_NAME | tr '[:upper:]' '[:lower:]')
TARGET_DIR="../$APP_NAME_LOWER"

# Pre-check for conflicts
print_status "Checking for potential conflicts..."

CONFLICTS_FOUND=false

# Check if directory already exists
if [ -d "$TARGET_DIR" ]; then
    print_warning "Directory $TARGET_DIR already exists!"
    CONFLICTS_FOUND=true
fi

# Handle conflicts
if [ "$CONFLICTS_FOUND" = true ]; then
    echo ""
    print_warning "Conflicts detected! The following already exist:"
    [ -d "$TARGET_DIR" ] && echo "  - Directory: $TARGET_DIR"
    echo ""
    
    while true; do
        read -p "Do you want to proceed and overwrite existing files? (y/N): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* )
                print_status "Proceeding with overwrite..."
                break
                ;;
            [Nn]* | "" )
                print_error "Operation cancelled by user."
                exit 1
                ;;
            * )
                echo "Please answer yes (y) or no (n)."
                ;;
        esac
    done
else
    print_success "No conflicts detected. Proceeding with creation..."
fi

# Clean up existing directory if we're overwriting
if [ -d "$TARGET_DIR" ] && [ "$CONFLICTS_FOUND" = true ]; then
    print_status "Removing existing directory: $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi

# Your template logic here
print_status "Creating your application..."

# ... your template code ...

print_success "Your template completed successfully!"
```

## 🧪 Testing Your Template

### Running Tests

```bash
# Test a specific template
./scripts/test-template.sh your-template-name

# Run all tests
./scripts/run-tests.sh

# Debug a template
./scripts/debug-template.sh your-template-name detailed
```

### Test Requirements

Your template must pass these tests:

- ✅ **Template structure**: All required files exist
- ✅ **Configuration**: `template.json` is valid
- ✅ **Script execution**: Template script runs without errors
- ✅ **Database setup**: Database is created and migrated
- ✅ **Application startup**: App can start successfully
- ✅ **Feature validation**: All template features work

## 📝 Documentation Requirements

### Template Documentation

Each template should include:

- **README.md**: Detailed setup and usage instructions
- **FEATURES.md**: List of included features
- **TROUBLESHOOTING.md**: Common issues and solutions
- **EXAMPLES.md**: Usage examples and customization

### Code Documentation

- **Comments**: Explain complex logic
- **Function names**: Use descriptive names
- **Error messages**: Provide helpful error messages
- **User prompts**: Make prompts clear and actionable

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Template name and version**
2. **Steps to reproduce**
3. **Expected behavior**
4. **Actual behavior**
5. **System information** (OS, Ruby version, etc.)
6. **Error messages and logs**

## 🔧 Development Setup

### Prerequisites

- Ruby 3.1+
- Rails 8.0+
- PostgreSQL 14+
- Node.js 18+
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/your-username/templatizer.git
cd templatizer

# Install dependencies (if any)
# Add any required gems or packages

# Run tests
./scripts/run-tests.sh

# Debug a template
./scripts/debug-template.sh rails-modern detailed
```

## 📋 Pull Request Guidelines

### Before Submitting

- [ ] Run all tests: `./scripts/run-tests.sh`
- [ ] Test your template: `./scripts/test-template.sh your-template`
- [ ] Debug any issues: `./scripts/debug-template.sh your-template`
- [ ] Update documentation
- [ ] Follow code style guidelines

### Pull Request Template

```markdown
## Description
Brief description of changes

## Template Name
Name of the template being added/modified

## Testing
- [ ] Template tests pass
- [ ] Manual testing completed
- [ ] Documentation updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## 🎯 Contribution Ideas

### New Templates

- **React + TypeScript**: Modern React applications
- **Vue.js**: Vue.js applications with Vite
- **Next.js**: Full-stack Next.js applications
- **Express.js**: Node.js API applications
- **Django**: Python web applications
- **Laravel**: PHP web applications

### Improvements

- **CI/CD**: GitHub Actions for automated testing
- **Documentation**: Better guides and examples
- **Testing**: More comprehensive test coverage
- **Debugging**: Better error messages and diagnostics
- **Performance**: Optimize template execution

## 📞 Getting Help

- **Issues**: Create a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Documentation**: Check the docs directory
- **Examples**: Look at existing templates

## 📄 License

By contributing to Templatizer, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Templatizer! 🚀
