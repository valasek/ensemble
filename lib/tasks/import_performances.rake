# frozen_string_literal: true

# ============================================================
# Performances PDF import pipeline
# ============================================================
#
# Workflow (run in order):
#
#   1. Drop PDF files into db/data/pdfs/
#      Naming convention: "YYYY <anything>.pdf"   e.g. "2000 Podujatia.pdf"
#
#   2. bin/rails performances:extract
#        Uses pdftotext (poppler-utils) to create plain-text files in
#        db/data/extracted/
#
#   3. bin/rails performances:parse
#        Parses the text files into YAML review files in db/data/parsed/
#        **REVIEW AND EDIT THESE FILES MANUALLY BEFORE THE NEXT STEP**
#
#   4. bin/rails performances:import ASSEMBLY=<subdomain>
#        Reads the reviewed YAML files and writes to the database.
#        Idempotent: skips records where (assembly, date, name) already exist.
#
# ============================================================

PDF_DIR       = Rails.root.join("db/data/pdfs")
EXTRACTED_DIR = Rails.root.join("db/data/extracted")
PARSED_DIR    = Rails.root.join("db/data/parsed")

# Fixes the fi-ligature extraction problem: pdftotext maps the PDF fi-ligature glyph
# to a plain space (0x20) instead of the two characters "fi". pdftohtml handles the
# ligature correctly, so we use its output as a reference word list to patch the text.
#
# Strategy:
#   - Words with fi in the middle (e.g. "choreografie"):
#     the broken form is "choreogra e" — replace via word-boundary regex.
#   - Words starting with fi (e.g. "finančnej"):
#     the broken form is the remainder without fi ("nančnej") — replace as whole token.
FIX_FI_HELPER = lambda do |text, pdf_path|
  html = `pdftohtml -stdout -noframes -enc UTF-8 "#{pdf_path}" 2>/dev/null`
  return text if html.empty?

  plain = html
    .gsub(/<[^>]+>/, " ")
    .gsub(/&amp;/, "&").gsub(/&lt;/, "<").gsub(/&gt;/, ">")
    .gsub(/&quot;/, '"').gsub(/&#160;/, " ")
    .gsub(/&#(\d+);/) { [ $1.to_i ].pack("U") }
    .gsub(/&[a-z]+;/, " ")

  fixed = text.dup

  # Mid-word fi (at least one alpha char on each side of "fi")
  plain.scan(/[[:alpha:]]+fi[[:alpha:]]+/).uniq.each do |word|
    parts   = word.split("fi", -1)
    pattern = "\\b" + parts.map { |p| Regexp.escape(p) }.join("\\s+") + "\\b"
    fixed.gsub!(Regexp.new(pattern), word)
  end

  # Word-initial fi (the leading "fi" is dropped; remainder appears as standalone token)
  plain.scan(/\bfi[[:alpha:]]{2,}/).uniq.each do |word|
    rest = word[2..]
    fixed.gsub!(Regexp.new("\\b" + Regexp.escape(rest) + "\\b"), word)
  end

  fixed
end

namespace :performances do
  # ----------------------------------------------------------
  # STEP 1 – Extract text from PDFs
  # ----------------------------------------------------------
  desc "Extract text from PDFs in db/data/pdfs/ → db/data/extracted/"
  task extract: :environment do
    pdfs = Dir[PDF_DIR.join("*.pdf")]
    abort "No PDF files found in #{PDF_DIR}" if pdfs.empty?

    pdfs.each do |pdf|
      basename  = File.basename(pdf, ".pdf")
      out_file  = EXTRACTED_DIR.join("#{basename}.txt")
      # -layout preserves column alignment; -enc UTF-8 ensures correct encoding
      cmd = %(pdftotext -layout -enc UTF-8 "#{pdf}" "#{out_file}")
      puts "  Extracting: #{File.basename(pdf)}"
      system(cmd) or abort "pdftotext failed for #{pdf}"

      # pdftotext maps the PDF fi-ligature glyph to a space; patch it using pdftohtml
      text  = File.read(out_file, encoding: "UTF-8")
      fixed = FIX_FI_HELPER.call(text, pdf)
      File.write(out_file, fixed, encoding: "UTF-8") if fixed != text

      puts "    → #{out_file}"
    end

    puts "\nDone. Review text files in #{EXTRACTED_DIR} if needed, then run performances:parse"
  end

  # ----------------------------------------------------------
  # STEP 2 – Parse text → YAML for human review
  # ----------------------------------------------------------
  desc "Parse extracted text files → YAML review files in db/data/parsed/"
  task parse: :environment do
    txts = Dir[EXTRACTED_DIR.join("*.txt")]
    abort "No text files found in #{EXTRACTED_DIR}. Run performances:extract first." if txts.empty?

    txts.each do |txt|
      basename = File.basename(txt, ".txt")
      out_file = PARSED_DIR.join("#{basename}.yml")

      puts "  Parsing: #{File.basename(txt)}"
      result = PerformanceParser.parse_file(txt)

      require "yaml"
      File.write(out_file, result.to_yaml)
      puts "    → #{out_file}  (#{result["performances"].size} performances)"
    end

    puts "\nDone. REVIEW AND EDIT the YAML files in #{PARSED_DIR}, then run:"
    puts "  bin/rails performances:import ASSEMBLY=<subdomain>"
  end

  # ----------------------------------------------------------
  # STEP 3 – Import reviewed YAML into the database
  # ----------------------------------------------------------
  desc "Import reviewed YAML files into the DB. Set ASSEMBLY=<subdomain> env var."
  task import: :environment do
    require "cgi"

    # Convert plain text to Trix-compatible HTML (div-per-line, matching what the
    # rich text editor produces). Leading spaces are converted to &nbsp; to preserve
    # indentation, since browsers collapse regular whitespace inside block elements.
    plain_to_html = ->(text) do
      text.to_s.strip.split("\n").map do |line|
        escaped = CGI.escapeHTML(line)
        escaped.gsub!(/\A( +)/) { "&nbsp;" * $1.length }
        escaped.empty? ? "<div><br></div>" : "<div>#{escaped}</div>"
      end.join
    end

    subdomain = ENV["ASSEMBLY"].presence
    abort "Set the ASSEMBLY env var to the assembly subdomain, e.g. ASSEMBLY=bralen" unless subdomain

    assembly = Assembly.find_by!(subdomain: subdomain)
    ymls     = Dir[PARSED_DIR.join("*.yml")]
    abort "No YAML files found in #{PARSED_DIR}. Run performances:parse first." if ymls.empty?

    require "yaml"
    total_years   = 0
    total_created = 0
    total_updated = 0

    ymls.each do |yml|
      puts "\nImporting #{File.basename(yml)} ..."
      data = YAML.safe_load_file(yml, permitted_classes: [ Symbol ])

      year = data["year"].to_i

      # --- AssemblyYear + rich-text description ---
      ay = AssemblyYear.find_or_create_by!(assembly: assembly, year: year)
      if data["year_description"].present?
        ay.description = plain_to_html.call(data["year_description"])
        ay.save!
        total_years += 1
        puts "  Updated description for year #{year}"
      else
        puts "  Year #{year}: no description in YAML, skipping."
      end

      # --- Performances ---
      (data["performances"] || []).each do |p|
        date_from = Date.parse(p["date_from"]) rescue nil
        next unless date_from

        date_to   = p["date_to"].present? ? (Date.parse(p["date_to"]) rescue nil) : nil
        name      = p["name"].to_s.strip
        next if name.blank?

        location  = p["location"].to_s.strip
        desc_text = p["description"].to_s.strip

        perf = Performance.find_or_initialize_by(assembly: assembly, date: date_from, name: name)
        is_new = perf.new_record?

        perf.end_date  = date_to
        perf.location  = location.presence
        perf.description = desc_text.present? ? plain_to_html.call(desc_text) : nil
        unless perf.save
          puts "  WARNING: skipping invalid record (#{date_from} / #{name.inspect}): #{perf.errors.full_messages.join(', ')}"
          next
        end

        if is_new
          total_created += 1
        else
          total_updated += 1
        end
      end
    end

    puts "\n=== Import complete ==="
    puts "  AssemblyYears updated  : #{total_years}"
    puts "  Performances created   : #{total_created}"
    puts "  Performances updated   : #{total_updated}"
    puts "\nRemember to reindex Meilisearch:"
    puts "  bin/rails runner 'Performance.clear_index!; Performance.reindex!'"
  end
end

# ============================================================
# Parser class (kept here for locality; move to lib/ if grows large)
# ============================================================
class PerformanceParser
  EN_DASH = "\u2013"
  D = "[#{EN_DASH}\\-]"   # matches hyphen or en-dash

  # Pattern B: full range  dd.mm. - dd.mm. YYYY   e.g. "23.4.-4.5. 1990"
  FULL_RANGE_RE = /\A\s*(\d{1,2})\.(\d{1,2})\.\s*#{D}\s*(\d{1,2})\.(\d{1,2})\.\s*(\d{4})(?:\s+(.+))?/
  # Pattern C: abbrev range  dd. - dd.mm. YYYY     e.g. "17.-30.6. 1990", "3.–10.1. 2000"
  ABBR_RANGE_RE = /\A\s*(\d{1,2})\.\s*#{D}\s*(\d{1,2})\.(\d{1,2})\.\s*(\d{4})(?:\s+(.+))?/
  # Pattern D: "a" range    dd. a dd.mm. YYYY      e.g. "11. a 12.4. 2000"
  AND_RANGE_RE  = /\A\s*(\d{1,2})\.\s+a\s+(\d{1,2})\.(\d{1,2})\.\s*(\d{4})(?:\s+(.+))?/
  # Pattern A: single date  dd.mm. YYYY or dd.mm.YYYY
  SINGLE_RE     = /\A\s*(\d{1,2})\.(\d{1,2})\.\s*(\d{4})(?:\s+(.+))?/

  # Lines that are pure PDF artifacts — stripped from descriptions and ignored globally
  SLOVAK_MONTHS = %w[JANUÁR FEBRUÁR MAREC APRÍL MÁJ JÚN JÚL AUGUST SEPTEMBER OKTÓBER NOVEMBER DECEMBER].freeze
  ARTIFACT_LINE_RE = /\A\s*(?:[fFiIlL]{1,3}|\d+\s+z\s+\d+)\s*\z/

  def self.parse_file(path)
    year = File.basename(path, ".txt").match(/\d{4}/)&.to_s&.to_i
    raw_lines = File.readlines(path, encoding: "UTF-8", chomp: true)
    lines = preprocess(raw_lines, year)
    new(lines, year).parse
  end

  # Remove PDF page-header/footer artifacts before parsing:
  #   - lines containing a form-feed character (\f) — page separators injected by pdftotext
  #   - lines that are purely whitespace + year number — top-of-page running headers
  #   - lines that are a single uppercase Slovak month name
  def self.preprocess(lines, year)
    lines.reject do |line|
      stripped = line.strip
      line.include?("\f") ||
        stripped == year.to_s ||
        SLOVAK_MONTHS.include?(stripped)
    end
  end

  def initialize(lines, year)
    @lines = lines
    @year  = year
  end

  PODUJATIA_RE = /\APODUJATIA\s*\z/

  def parse
    performances    = []
    current         = nil

    # Split on the "PODUJATIA" sentinel line.
    # Everything before it is the year description; everything after is performance records.
    split_idx = @lines.index { |l| PODUJATIA_RE.match?(l.strip) }

    if split_idx
      year_desc_lines   = @lines[0...split_idx]
      performance_lines = @lines[(split_idx + 1)..]
    else
      # Fallback: no sentinel found — use original heuristic (first date line boundary)
      year_desc_lines   = []
      performance_lines = @lines
    end

    year_desc_lines = year_desc_lines.reject { |l| ARTIFACT_LINE_RE.match?(l) }

    performance_lines.each do |line|
      # Lines indented more than 10 chars are embedded program details, not headers
      indent = line.match(/\A( *)/)[1].length
      if indent <= 10 && (parsed = match_date_line(line))
        performances << finalize(current) if current

        name, location = split_header(parsed[:rest].to_s.strip)
        current = {
          "date_from"  => parsed[:date_from],
          "date_to"    => parsed[:date_to],
          "raw_header" => parsed[:rest].to_s.strip,
          "name"       => name,
          "location"   => location,
          "desc_lines" => []
        }
      elsif current
        current["desc_lines"] << line unless ARTIFACT_LINE_RE.match?(line)
      end
    end

    performances << finalize(current) if current

    # Deduplicate: same (date_from, name) → keep the entry with longest description
    performances = deduplicate(performances)

    {
      "year"             => @year,
      "year_description" => year_desc_lines.join("\n").strip.presence,
      "performances"     => performances
    }
  end

  private

  def match_date_line(line)
    if (m = FULL_RANGE_RE.match(line))
      sd, sm, ed, em, yr, rest = m.captures
      # Cross-year range: year given is end-date year; if end_month < start_month, start is prior year
      start_yr = em.to_i < sm.to_i ? yr.to_i - 1 : yr.to_i
      { date_from: safe_date(start_yr, sm, sd), date_to: safe_date(yr, em, ed), rest: rest }
    elsif (m = ABBR_RANGE_RE.match(line))
      sd, ed, em, yr, rest = m.captures
      { date_from: safe_date(yr, em, sd), date_to: safe_date(yr, em, ed), rest: rest }
    elsif (m = AND_RANGE_RE.match(line))
      sd, ed, em, yr, rest = m.captures
      { date_from: safe_date(yr, em, sd), date_to: safe_date(yr, em, ed), rest: rest }
    elsif (m = SINGLE_RE.match(line))
      sd, sm, yr, rest = m.captures
      { date_from: safe_date(yr, sm, sd), date_to: nil, rest: rest }
    end
  end

  def deduplicate(performances)
    performances
      .group_by { |p| [ p["date_from"], p["name"] ] }
      .values
      .map { |group| group.max_by { |p| p["description"].to_s.length } }
      .sort_by { |p| p["date_from"].to_s }
  end

  # Heuristic: last comma segment → location; everything before → name
  # (institution embedded in name is cleaned manually via Avo)
  def split_header(text)
    return [ text, nil ] if text.blank?

    parts = text.split(/,\s*/)
    if parts.size >= 2
      location = parts.pop.strip
      [ parts.join(", ").strip, location ]
    else
      [ text.strip, nil ]
    end
  end

  def safe_date(year, month, day)
    Date.new(year.to_i, month.to_i, day.to_i).to_s
  rescue Date::Error
    nil
  end

  def finalize(entry)
    return unless entry

    desc = entry["desc_lines"]
             .join("\n")
             .gsub(/[ \t]+\n/, "\n")      # trailing whitespace per line
             .gsub(/\n{3,}/, "\n\n")      # collapse excess blank lines
             .strip

    entry.delete("desc_lines")
    entry["description"] = desc.presence
    entry
  end
end
