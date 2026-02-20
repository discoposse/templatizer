# Setup Guide

This guide will help you set up a new Rails application using the modern template.

## Prerequisites

Before running the template, ensure you have the following installed:

### Required Software
- **Ruby 3.1+** - [Install Ruby](https://www.ruby-lang.org/en/downloads/)
- **Rails 8.0+** - `gem install rails`
- **Database** - [PostgreSQL](https://www.postgresql.org/download/) (default) or SQLite 3. Use the second argument `sqlite` when running the script for SQLite.
- **Node.js 18+** - [Install Node.js](https://nodejs.org/) (for Tailwind CSS)
- **Git** - [Install Git](https://git-scm.com/)

### Verify Installation
```bash
# Check Ruby version
ruby --version

# Check Rails version
rails --version

# Check PostgreSQL
psql --version

# Check Node.js
node --version
```

## Quick Start

1. **Clone or download the template**
   ```bash
   # If using git
   git clone <repository-url>
   cd templatizer
   
   # Or download and extract the templatizer folder
   ```

2. **Make the script executable**
   ```bash
   chmod +x templates/rails-modern/create_rails_app.sh
   ```

3. **Create your Rails app**
   ```bash
   # PostgreSQL (default)
   ./templates/rails-modern/create_rails_app.sh MyAwesomeApp

   # Or SQLite
   ./templates/rails-modern/create_rails_app.sh MyAwesomeApp sqlite
   ```

4. **Start development**
   ```bash
   cd ../myawesomeapp
   bin/dev
   ```

5. **Visit your app**
   Open http://localhost:3000 in your browser

## What the Script Does

The `create_rails_app.sh` script performs the following steps:

### 1. Rails App Generation
- Creates a new Rails 8 application
- Configures PostgreSQL (default) or SQLite as the database (second argument: `sqlite`)
- Sets up Tailwind CSS for styling
- Configures Importmap for JavaScript
- Skips unnecessary files (git, tests initially)

### 2. Authentication System
- Generates User and Session models
- Creates authentication concern
- Sets up secure password handling
- Configures session management
- Adds admin role support

### 3. Controllers and Views
- Creates ApplicationController with authentication
- Sets up HomeController for landing page
- Creates SessionsController for sign in/out
- Creates SignUpsController for user registration
- Generates beautiful, responsive views

### 4. Database Setup
- Creates PostgreSQL database
- Runs all migrations
- Sets up proper indexes
- Configures session management

### 5. UI Components
- Modern landing page with hero section
- Responsive navigation
- Beautiful forms with validation
- Flash message system
- Tailwind CSS styling

## Customization

### App Name and Branding
1. **Update app name**: The script uses your provided name throughout
2. **Logo**: Replace the SVG logo in views with your own
3. **Colors**: Modify `config/tailwind.config.js` for custom theme
4. **Content**: Update text in views to match your brand

### Adding Features
1. **Models**: Add new models in `app/models/`
2. **Controllers**: Create controllers in `app/controllers/`
3. **Views**: Add views in `app/views/`
4. **Routes**: Update `config/routes.rb`
5. **JavaScript**: Add Stimulus controllers in `app/javascript/controllers/`

### Database Modifications
1. **New migrations**: `rails generate migration AddNewField`
2. **Run migrations**: `rails db:migrate`
3. **Rollback if needed**: `rails db:rollback`

## Development Workflow

### Starting Development
```bash
# Start the development server
bin/dev

# Or start individual services
bin/rails server
bin/rails tailwindcss:watch
```

### Database Operations
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed database (if you have seeds)
rails db:seed

# Reset database
rails db:reset
```

### Testing
```bash
# Run tests
bin/rails test

# Run specific test
bin/rails test test/models/user_test.rb
```

### Code Quality
```bash
# Run RuboCop
bin/rubocop

# Run Brakeman security scan
bin/brakeman

# Fix RuboCop issues
bin/rubocop -a
```

## Deployment

Deployment is **optional**. The template does not include Kamal by default.

### Optional: Kamal (VPS with Docker)
See **[DEPLOYMENT.md](DEPLOYMENT.md)** for full Kamal setup, dependencies (Docker, registry, SSH), and step-by-step instructions. In short: add the Kamal gem, run `bin/rails kamal:install`, edit `config/deploy.yml` and secrets, then `kamal deploy`.

### Other options
- **Manual**: Set up production database, set `RAILS_MASTER_KEY` and env, run migrations, start the server.
- **Heroku / Render / Fly.io / Railway**: Follow each platform’s Rails guide; ensure production DB and secrets are set.

## Troubleshooting

### Common Issues

#### Database Connection
```bash
# Check PostgreSQL is running
sudo service postgresql status

# Start PostgreSQL
sudo service postgresql start

# Create database manually
createdb myapp_development
```

#### Missing Dependencies
```bash
# Install missing gems
bundle install

# Install missing Node modules
npm install

# Rebuild Tailwind CSS
rails tailwindcss:build
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x create_rails_app.sh

# Fix bin directory permissions
chmod +x bin/*
```

### Getting Help
- Check Rails logs: `tail -f log/development.log`
- Check browser console for JavaScript errors
- Verify all dependencies are installed
- Check database connection settings

## Next Steps

After creating your app:

1. **Customize the branding** - Update colors, logo, and content
2. **Add your features** - Create models, controllers, and views
3. **Set up testing** - Add test coverage for your features
4. **Configure deployment** - Set up production environment
5. **Add monitoring** - Set up logging and error tracking

## Support

For issues with the template:
1. Check this documentation
2. Review Rails guides: https://guides.rubyonrails.org/
3. Check Tailwind CSS docs: https://tailwindcss.com/docs
4. Review Hotwire docs: https://hotwired.dev/
