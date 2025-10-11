# Rails Modern App Template

This template creates a modern Rails 8 application with:

- **Authentication System**: Complete user authentication with sessions, password reset, and email confirmation
- **Modern UI**: Tailwind CSS with responsive design and beautiful components
- **Hotwire**: Turbo and Stimulus for modern JavaScript interactions
- **Database**: PostgreSQL with proper migrations
- **Security**: Secure password handling, CSRF protection, and modern browser requirements
- **Admin Features**: Role-based access control
- **PWA Ready**: Progressive Web App capabilities

## Quick Start

```bash
# Make the script executable
chmod +x create_rails_app.sh

# Create a new Rails app
./create_rails_app.sh myapp

# Navigate to your new app
cd myapp

# Start the development server
bin/dev
```

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

## License

This template is provided as-is for creating modern Rails applications.
