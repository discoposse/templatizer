# 🚀 Templatizer

A powerful Rails application template generator for creating modern Rails 8 applications with pre-configured authentication, modern UI, and best practices. Templatizer allows you to quickly scaffold production-ready Rails applications with everything you need to get started.

## ✨ Features

- 🎯 **Rails 8.1 Template**: Modern Rails application with latest features
- 🔐 **Complete Authentication**: User registration, login, password reset, email confirmation, and magic links
- 🎨 **Modern UI**: Tailwind CSS with responsive design and beautiful components
- ⚡ **Hotwire**: Turbo and Stimulus for modern JavaScript interactions
- 🔧 **Smart Conflict Detection**: Handles existing directories and databases intelligently
- 🧪 **Comprehensive Testing**: Built-in testing framework for templates
- 📚 **Rich Documentation**: Detailed guides and troubleshooting
- ⚡ **Fast Setup**: Get from zero to running app in minutes

## 🎯 How It Works

Templatizer creates new Rails applications in the parent directory (`../`) so that:
- The templatizer itself can be version controlled independently
- Each new app gets its own separate directory and git repository
- You can easily organize multiple projects while keeping templatizer as a standalone tool

### Current Status: ✅ FULLY WORKING

The templatizer has been thoroughly tested and debugged. All major issues have been resolved:

- ✅ **Authentication System**: Complete user authentication with email confirmation, password reset, and magic links
- ✅ **Routing**: Fixed all navigation links and route configurations
- ✅ **Database**: Smart conflict detection and migration handling
- ✅ **UI/UX**: Modern Tailwind CSS with responsive design and consistent styling
- ✅ **Testing**: Comprehensive test framework included

This template creates a modern Rails 8.1 application with:

- **Authentication System**: Complete user authentication with sessions, password reset, email confirmation, and magic links
- **Modern UI**: Tailwind CSS with responsive design and beautiful components
- **Hotwire**: Turbo and Stimulus for modern JavaScript interactions
- **Database**: PostgreSQL (default) or SQLite — choose when creating the app
- **Security**: Secure password handling, CSRF protection, and modern browser requirements
- **Admin Features**: Role-based access control
- **PWA Ready**: Progressive Web App capabilities
- **Email Support**: Letter opener for development, ready for production mailers

## 🚀 Quick Start

### Using the Template

```bash
# Navigate to templatizer directory
cd templatizer

# Use the Rails Modern template (PostgreSQL by default)
chmod +x templates/rails-modern/create_rails_app.sh
./templates/rails-modern/create_rails_app.sh myapp

# Or create an app with SQLite
./templates/rails-modern/create_rails_app.sh myapp sqlite

# Navigate to your new app
cd ../myapp

# Install dependencies (if not already done by the script)
bundle install

# Set up the database (script usually runs migrations; run if needed)
bin/rails db:create
bin/rails db:migrate

# Start the development server
bin/dev
```

Visit `http://localhost:3000` to see your new application. In development, sent emails are available at `http://localhost:3000/letter_opener`.

### Testing Templates

```bash
# Test a specific template
./scripts/test-template.sh rails-modern

# Run all tests
./scripts/run-tests.sh

# Debug a template
./scripts/debug-template.sh rails-modern detailed
```

## What Gets Created

### Core Features
- ✅ User authentication (sign up, sign in, sign out)
- ✅ Password reset with secure email tokens
- ✅ Email confirmation system
- ✅ Magic link authentication
- ✅ Session management with 30-day expiration
- ✅ Admin role management
- ✅ Secure cookie-based sessions

### UI Components
- ✅ Modern landing page with hero section
- ✅ Responsive navigation with user menu
- ✅ Beautiful form styling with Tailwind CSS
- ✅ Consistent login/signup page styling
- ✅ Flash message system
- ✅ Error handling and validation displays

### JavaScript Features
- ✅ Stimulus controllers for interactivity
- ✅ Turbo for seamless page transitions
- ✅ Form handling with validation
- ✅ Modern browser requirements

### Database Schema
- ✅ Users table with secure authentication
- ✅ Sessions table for session management
- ✅ Email confirmation support
- ✅ Admin role support

## File Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── concerns/
│   │   └── authentication.rb
│   ├── sessions_controller.rb
│   ├── sign_ups_controller.rb
│   ├── password_resets_controller.rb
│   ├── email_confirmations_controller.rb
│   └── magic_links_controller.rb
├── models/
│   ├── user.rb
│   ├── session.rb
│   └── current.rb
├── views/
│   ├── layouts/
│   │   ├── application.html.erb
│   │   └── mailer.html.erb
│   ├── home/
│   ├── sessions/
│   ├── sign_ups/
│   ├── password_resets/
│   └── email_confirmations/
├── mailers/
│   ├── application_mailer.rb
│   ├── password_resets_mailer.rb
│   └── email_confirmations_mailer.rb
└── helpers/
    └── application_helper.rb
```

## Configuration Files

- `Gemfile` - All necessary gems including Rails 8.1, Tailwind, Hotwire
- `config/routes.rb` - Complete routing setup with authentication routes
- `config/application.rb` - Rails configuration
- `config/database.yml` - PostgreSQL or SQLite (depending on template option)
- `config/initializers/action_mailer.rb` - Mailer URL options and delivery (development: Letter Opener Web)
- `config/initializers/cloudmailin.rb` - Optional production SMTP (when `CLOUDMAILIN_SMTP_URL` is set)
- `config/tailwind.config.js` - Tailwind CSS configuration
- `config/importmap.rb` - JavaScript import mapping

## Dependencies

### Required System Dependencies
- Ruby 3.1+ (tested with 3.4.8)
- Rails 8.1+
- **Database**: PostgreSQL 14+ (default) or SQLite 3 — pass `sqlite` as second argument for SQLite
- Node.js 18+ (for Tailwind CSS)
- Git

### Gems Included
- `rails` - Rails framework (8.1+)
- `pg` - PostgreSQL adapter
- `bcrypt` - Password hashing
- `tailwindcss-rails` - Tailwind CSS integration
- `turbo-rails` - Hotwire Turbo
- `stimulus-rails` - Hotwire Stimulus
- `importmap-rails` - JavaScript import maps
- `solid_cache` - Database-backed cache
- `solid_queue` - Database-backed job queue
- `solid_cable` - Database-backed Action Cable
- `letter_opener` - Development email preview
- `letter_opener_web` - Web interface for email preview
- `kaminari` - Pagination

## Customization

### Branding
1. Update the app name in `config/application.rb`
2. Replace the logo in views
3. Update colors in `config/tailwind.config.js`
4. Modify the landing page content in `app/views/home/index.html.erb`

### Features
1. Add new models in `app/models/`
2. Create controllers in `app/controllers/`
3. Add routes in `config/routes.rb`
4. Create views in `app/views/`
5. Add Stimulus controllers in `app/javascript/controllers/`

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

## Email Development

In development, emails are opened in the browser using Letter Opener Web. Mailer options (host, port, delivery method) are set in `config/initializers/action_mailer.rb` (not in environment files).

```bash
# Visit the email viewer
open http://localhost:3000/letter_opener
```

All sent emails (password resets, confirmations, etc.) appear here for easy testing.

## Deployment

The template does **not** include Kamal or deployment config by default. Deployment is optional and flexible:

- **Kamal (optional add-on)** — Deploy to your own VPS with Docker. See **[DEPLOYMENT.md](DEPLOYMENT.md)** for Kamal setup, dependencies, and step-by-step instructions.
- **Other platforms** — Use Heroku, Render, Fly.io, Railway, or any host that supports Rails; set production database and `RAILS_MASTER_KEY` as required.

## Security Features

- ✅ Secure password hashing with bcrypt
- ✅ CSRF protection enabled
- ✅ Secure session management with signed cookies
- ✅ Password reset with signed tokens (20-minute expiration)
- ✅ Email confirmation with signed tokens (2-day expiration)
- ✅ Magic links with signed tokens (5-minute expiration)
- ✅ Modern browser requirements
- ✅ SQL injection protection
- ✅ XSS protection
- ✅ Secure cookie settings (httponly, same_site: lax)

## Browser Support

- Modern browsers only (Chrome 90+, Firefox 88+, Safari 14+)
- Progressive Web App capabilities
- Responsive design for all screen sizes

## 🤝 Contributing

Templatizer is an open-source project! We welcome contributions:

### Development

```bash
# Clone the repository
git clone https://github.com/discoposse/templatizer.git
cd templatizer

# Run tests
./scripts/run-tests.sh

# Debug templates
./scripts/debug-template.sh rails-modern detailed

# Generate documentation
./scripts/generate-docs.sh
```

### Project Structure

```
templatizer/
├── templates/           # Template definitions
│   └── rails-modern/    # Rails Modern template
├── scripts/             # Testing and utility scripts
│   ├── test-template.sh # Template testing
│   ├── debug-template.sh # Debugging tools
│   └── run-tests.sh     # Test runner
└── .github/workflows/   # CI/CD pipelines
```

## 🔧 Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## 📚 Documentation

- **[FEATURES.md](FEATURES.md)**: Complete feature list
- **[QUICK_START.md](QUICK_START.md)**: Quick start guide
- **[SETUP.md](SETUP.md)**: Detailed setup instructions
- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Optional Kamal deployment and dependencies
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Common issues and solutions
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Contribution guidelines

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
