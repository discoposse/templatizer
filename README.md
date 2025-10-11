# 🚀 Templatizer

A powerful, open-source template generator for creating modern web applications with pre-configured setups. Templatizer allows you to quickly scaffold applications with best practices, authentication, modern UI frameworks, and more.

## ✨ Features

- 🎯 **Multiple Templates**: Rails, React, Vue.js, and more
- 🔧 **Smart Conflict Detection**: Handles existing directories and databases
- 🧪 **Comprehensive Testing**: Built-in testing framework for templates
- 📚 **Rich Documentation**: Detailed guides and troubleshooting
- 🤝 **Community Driven**: Open source with contribution guidelines
- ⚡ **Fast Setup**: Get from zero to running app in minutes

## 🎯 How It Works

Templatizer creates new applications in the parent directory (`../`) so that:
- The templatizer itself can be version controlled independently
- Each new app gets its own separate directory and git repository
- You can easily organize multiple projects while keeping templatizer as a standalone tool

### Current Status: ✅ FULLY WORKING

The templatizer has been thoroughly tested and debugged. All major issues have been resolved:

- ✅ **Authentication System**: Complete user authentication with proper class methods
- ✅ **Routing**: Fixed all navigation links and route configurations
- ✅ **Database**: Smart conflict detection and migration handling
- ✅ **UI/UX**: Modern Tailwind CSS with responsive design
- ✅ **Testing**: Comprehensive test framework included

This template creates a modern Rails 8 application with:

- **Authentication System**: Complete user authentication with sessions, password reset, and email confirmation
- **Modern UI**: Tailwind CSS with responsive design and beautiful components
- **Hotwire**: Turbo and Stimulus for modern JavaScript interactions
- **Database**: PostgreSQL with proper migrations
- **Security**: Secure password handling, CSRF protection, and modern browser requirements
- **Admin Features**: Role-based access control
- **PWA Ready**: Progressive Web App capabilities

## 🚀 Quick Start

### Using a Template

```bash
# Navigate to templatizer directory
cd templatizer

# List available templates
ls templates/

# Use a template (e.g., Rails Modern)
chmod +x templates/rails-modern/create_rails_app.sh
./templates/rails-modern/create_rails_app.sh myapp

# Navigate to your new app
cd ../myapp

# Start the development server
bin/dev
```

### Testing Templates

```bash
# Test a specific template
./scripts/test-template.sh rails-modern

# Run all tests
./scripts/run-tests.sh

# Debug a template
./scripts/debug-template.sh rails-modern detailed
```

### Sample Application

Templatizer includes a sample application to demonstrate all features:

```bash
# Test the sample app
./scripts/test-sample-app.sh

# Navigate to the sample app
cd sample-app

# Start the development server
bin/dev

# Visit the application
open http://localhost:3000
```

The sample app includes:
- ✅ **Complete Authentication**: User registration, login, logout
- ✅ **Modern UI**: Tailwind CSS with responsive design
- ✅ **Database**: PostgreSQL with proper migrations
- ✅ **Hotwire**: Turbo and Stimulus integration
- ✅ **Testing**: Comprehensive test coverage

## What Gets Created

### Core Features
- ✅ User authentication (sign up, sign in, sign out)
- ✅ Password reset with email tokens
- ✅ Email confirmation system
- ✅ User profiles and settings
- ✅ Admin role management
- ✅ Session management with security

### UI Components
- ✅ Modern landing page with hero section
- ✅ Responsive navigation with user menu
- ✅ Beautiful form styling with Tailwind CSS
- ✅ Flash message system
- ✅ Modal dialogs for confirmations
- ✅ Interactive buttons and components

### JavaScript Features
- ✅ Stimulus controllers for interactivity
- ✅ Turbo for seamless page transitions
- ✅ Form handling with validation
- ✅ Modal management
- ✅ Delete confirmations

### Database Schema
- ✅ Users table with secure authentication
- ✅ Sessions table for session management
- ✅ Password reset tokens
- ✅ Email confirmation tokens
- ✅ Admin role support

## File Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── concerns/authentication.rb
│   ├── sessions_controller.rb
│   ├── sign_ups_controller.rb
│   ├── passwords_controller.rb
│   └── settings/
├── models/
│   ├── user.rb
│   └── session.rb
├── views/
│   ├── layouts/application.html.erb
│   ├── home/
│   ├── sessions/
│   ├── sign_ups/
│   ├── passwords/
│   └── settings/
├── javascript/
│   ├── application.js
│   └── controllers/
└── assets/
    └── stylesheets/
        └── application.tailwind.css
```

## Configuration Files

- `Gemfile` - All necessary gems including Rails 8, Tailwind, Hotwire
- `config/routes.rb` - Complete routing setup
- `config/application.rb` - Rails configuration
- `config/database.yml` - PostgreSQL configuration
- `config/tailwind.config.js` - Tailwind CSS configuration
- `config/importmap.rb` - JavaScript import mapping

## Dependencies

### Required System Dependencies
- Ruby 3.1+
- Rails 8.0+
- PostgreSQL
- Node.js (for Tailwind CSS)
- Git

### Gems Included
- `rails` - Rails framework
- `pg` - PostgreSQL adapter
- `bcrypt` - Password hashing
- `tailwindcss-rails` - Tailwind CSS integration
- `turbo-rails` - Hotwire Turbo
- `stimulus-rails` - Hotwire Stimulus
- `importmap-rails` - JavaScript import maps
- `solid_cache` - Database-backed cache
- `solid_queue` - Database-backed job queue
- `solid_cable` - Database-backed Action Cable

## Customization

### Branding
1. Update the app name in `config/application.rb`
2. Replace the logo in `app/assets/images/`
3. Update colors in `config/tailwind.config.js`
4. Modify the landing page content in `app/views/home/index.html.erb`

### Features
1. Add new models in `app/models/`
2. Create controllers in `app/controllers/`
3. Add routes in `config/routes.rb`
4. Create views in `app/views/`
4. Add Stimulus controllers in `app/javascript/controllers/`

### Styling
1. Modify `app/assets/stylesheets/application.tailwind.css`
2. Update `config/tailwind.config.js` for custom theme
3. Add custom CSS classes as needed

## Development

```bash
# Start the development server
bin/dev

# Run tests
bin/rails test

# Run linting
bin/rubocop

# Run security scan
bin/brakeman
```

## Deployment

The template includes Kamal deployment configuration:

```bash
# Deploy with Kamal
bin/kamal deploy
```

## Security Features

- ✅ Secure password hashing with bcrypt
- ✅ CSRF protection enabled
- ✅ Secure session management
- ✅ Password reset with signed tokens
- ✅ Email confirmation system
- ✅ Modern browser requirements
- ✅ SQL injection protection
- ✅ XSS protection

## Browser Support

- Modern browsers only (Chrome 90+, Firefox 88+, Safari 14+)
- Progressive Web App capabilities
- Responsive design for all screen sizes

## 🤝 Contributing

Templatizer is an open-source project! We welcome contributions:

### Adding New Templates

1. **Create template directory**: `mkdir templates/your-template-name`
2. **Add configuration**: Create `template.json` with metadata
3. **Create script**: Build your template creation script
4. **Test thoroughly**: Use our testing framework
5. **Submit PR**: Follow our contribution guidelines

### Development

```bash
# Clone the repository
git clone https://github.com/your-org/templatizer.git
cd templatizer

# Run tests
./scripts/run-tests.sh

# Debug templates
./scripts/debug-template.sh template-name detailed

# Generate documentation
./scripts/generate-docs.sh
```

### Project Structure

```
templatizer/
├── templates/           # Template definitions
│   ├── rails-modern/    # Rails Modern template
│   └── your-template/   # Your custom template
├── scripts/             # Testing and utility scripts
│   ├── test-template.sh # Template testing
│   ├── debug-template.sh # Debugging tools
│   └── run-tests.sh     # Test runner
├── docs/               # Generated documentation
├── examples/            # Usage examples
└── .github/workflows/   # CI/CD pipelines
```

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. Authentication Errors
**Problem**: `NoMethodError: undefined method 'unauthenticated_access_only'`
**Solution**: This has been fixed in the template. If you encounter this:
```bash
# Restart your Rails server
# The template now properly defines this as a class method
```

#### 2. Routing Errors
**Problem**: `ActionController::RoutingError: No route matches [GET] "/sign_up"`
**Solution**: Use the correct routes:
- Sign up form: `/sign_up/new` (not `/sign_up`)
- Sign in form: `/session/new` (not `/session`)

#### 3. Database Conflicts
**Problem**: `PG::DuplicateTable: ERROR: relation "users" already exists`
**Solution**: The template now includes smart conflict detection:
- Automatically detects existing databases
- Prompts for overwrite confirmation
- Performs clean database reset when needed

#### 4. Migration Errors
**Problem**: `ActiveRecord::DuplicateMigrationNameError`
**Solution**: Fixed in template - now uses proper migration handling:
- Finds generated migrations automatically
- Updates content without creating duplicates
- Handles index creation intelligently

#### 5. Tailwind CSS Issues
**Problem**: `Specified input file ./app/assets/tailwind/application.css does not exist`
**Solution**: Template now creates the required input file automatically

### Getting Help

1. **Check the logs**: Look at your Rails server output for specific errors
2. **Test the sample app**: Run `./scripts/test-sample-app.sh` to verify functionality
3. **Debug mode**: Use `./scripts/debug-template.sh rails-modern detailed` for detailed output
4. **Restart server**: Many issues are resolved by restarting the Rails server

## 📚 Documentation

- **[Templates](docs/TEMPLATES.md)**: Available templates
- **[API](docs/API.md)**: Template development API
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Common issues and solutions
- **[Contributing](CONTRIBUTING.md)**: Contribution guidelines

## 🧪 Testing

Templatizer includes a comprehensive testing framework:

- **Template Validation**: Ensures templates work correctly
- **Conflict Detection**: Tests directory and database handling
- **Feature Validation**: Verifies all template features
- **CI/CD Pipeline**: Automated testing on multiple platforms

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Rails team for the amazing framework
- Tailwind CSS for beautiful styling
- Hotwire for modern JavaScript
- All contributors who make this project better
