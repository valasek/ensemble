# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Avo (see app/avo/resources) calls `String#singularize` without a locale
# argument when it derives the singular "item" name for has_many association
# panels (e.g. the "Create new %{item}" / "Attach %{item}" buttons). That
# method always uses the `:en` inflection rules no matter what `I18n.locale`
# is set to. Because of that, translated plural nouns from
# config/locales/avo.sk.yml get run through English singularization and come
# out wrong (e.g. "Podujatia" -> "Podujatium", "Kategórie" -> "Kategórie"
# unchanged). Registering the Slovak plural/singular pairs as irregular
# inflections in the :en scope is what fixes this, since that's the only
# scope Avo's `.singularize` call ever looks at.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "podujatie", "podujatia"
  inflect.irregular "kategóriu", "kategórie"
end
