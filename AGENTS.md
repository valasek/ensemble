# Ensemble — Agent Guide

A Rails 8.1 app for managing dance ensemble members and performances.

## Domain Model

| Model | Purpose |
|-------|---------|
| `Assembly` | A dance ensemble (has a unique `name` and `subdomain`) |
| `Member` | A dancer belonging to an assembly |
| `Performance` | A show/event belonging to an assembly (has `name`, `date`, `location`, rich-text `description`) |
| `MemberOfAssembly` | Join table tracking which members were in which assembly `year` and `group` |
| `User` | Authenticated user linked to an `Assembly` (Devise + Google OAuth) |

All resources are scoped under an `Assembly`. Routes follow the nesting:
```
/assemblies/:assembly_id/members
/assemblies/:assembly_id/performances
```

## Tech Stack

| Layer | Tool |
|-------|------|
| Framework | Rails 8.1 |
| Database | SQLite 3 (solid_cache, solid_queue, solid_cable) |
| Auth | Devise + omniauth-google-oauth2 |
| Frontend | Hotwire (Turbo + Stimulus), Propshaft, importmap |
| Styling | Tailwind CSS + DaisyUI |
| Search | Meilisearch (`meilisearch-rails` gem) |
| Admin | Avo (`/admin`) |
| Pagination | Kaminari |
| Monitoring | Sentry |
| Deployment | Kamal |
| Testing | Minitest + fixtures (Rails default) |
| Security scanning | Brakeman, bundler-audit, RuboCop |

## Project Layout

```
app/
  models/          # ActiveRecord models
  controllers/     # Standard + nested controllers
  views/           # ERB templates
  avo/resources/   # Avo admin resource definitions
  javascript/controllers/  # Stimulus controllers
db/
  migrate/         # Always use migrations to change schema
  schema.rb        # AUTO-GENERATED — never edit directly
  seeds.rb         # Seed data
config/
  routes.rb        # Route definitions
  initializers/    # Avo, Devise, Meilisearch, CSP config
test/
  fixtures/        # YAML fixture files
  models/          # Model unit tests
  controllers/     # Controller tests
```

## Development Commands

```sh
bin/dev            # Start server + CSS watcher (Foreman)
bin/rails test     # Run full test suite
bin/rails test test/models/member_test.rb  # Run a specific test file
bin/rails db:migrate            # Apply pending migrations
bin/rails db:rollback           # Undo last migration
bin/rails db:seed               # Load seed data
bin/rails routes                # List all routes
bin/rails runner 'Performance.reindex!'  # Reindex Meilisearch
bin/brakeman                    # Security scan
bin/rubocop                     # Lint
bin/bundler-audit               # Dependency CVE check
```

## Deployment (Kamal)

```sh
kamal deploy                    # Full deployment
kamal app exec 'bin/rails ...'  # Run a command in production
kamal app logs                  # View app logs
kamal accessory logs meilisearch
kamal accessory reboot meilisearch
```

## Rails Conventions & Best Practices

- **Migrations only** — never edit `db/schema.rb` directly; always generate a migration (`bin/rails g migration`)
- **Fat models, thin controllers** — keep business logic in models or service objects, not controllers
- **Scopes over class methods** for simple queries (e.g. `scope :sorted_by_name, -> { order(...) }`)
- **`dependent: :destroy`** on `has_many` when child records should not outlive the parent
- **`before_action`** in controllers to share common setup (e.g. finding `@assembly`)
- **Partial templates** (`_form.html.erb`, `_member.html.erb`) to keep views DRY
- **Fixtures** (not factories) for test data — keep them minimal and stable
- **Rich text** via ActionText (`has_rich_text`) — use `to_plain_text` when plain string needed
- **Meilisearch indexing** — after model changes affecting indexed attributes, run `Model.reindex!`
- **Avo resources** in `app/avo/resources/` must be updated when adding model attributes to the admin panel

## Styling Guidelines

- Use **DaisyUI components** first (e.g. `btn`, `card`, `table`, `modal`, `badge`)
- Extend with **Tailwind utility classes** for layout and spacing
- Avoid custom CSS unless DaisyUI/Tailwind cannot cover the need
- Respect existing colour scheme; check `app/assets/tailwind/` for any config overrides

## Search (Meilisearch)

- `Member` and `Performance` are indexed
- Searchable attributes are declared in the `meilisearch` block inside each model
- The `search#proxy` endpoint (`POST /search/proxy`) proxies front-end search requests
- After adding/renaming indexed attributes, run `Model.clear_index!` then `Model.reindex!`

## Security Rules

- **Validate all user input** at the model layer (presence, format, uniqueness)
- **Strong parameters** in every controller — never use `params.permit!`
- **CSP** configured in `config/initializers/content_security_policy.rb` — keep it restrictive
- **Brakeman** must pass before merging — run `bin/brakeman`
- **No credentials in code** — use Rails encrypted credentials (`config/credentials.yml.enc`)

## Things Agents Must NOT Do

1. **Push directly to `main`/`master`** — always work on a feature branch and open a PR
2. **Run destructive DB commands** (`db:drop`, `db:reset`, `db:schema:load` in production) without explicit user confirmation
3. **Edit `db/schema.rb` directly** — use migrations
4. **Use `params.permit!`** — always whitelist parameters explicitly
5. **Commit secrets or credentials** to version control
6. **Skip tests** — always run `bin/rails test` before considering a task complete
7. **Break Meilisearch index** without providing the reindex commands to restore it
