# frozen_string_literal: true

# ============================================================
# Podujatia PDF import pipeline
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
    abort "No text files found in #{EXTRACTED_DIR}. Run podujatia:extract first." if txts.empty?

    txts.each do |txt|
      basename = File.basename(txt, ".txt")
      out_file = PARSED_DIR.join("#{basename}.yml")

      puts "  Parsing: #{File.basename(txt)}"
      result = PodujatiaParser.parse_file(txt)

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
    subdomain = ENV["ASSEMBLY"].presence
    abort "Set the ASSEMBLY env var to the assembly subdomain, e.g. ASSEMBLY=bralen" unless subdomain

    assembly = Assembly.find_by!(subdomain: subdomain)
    ymls     = Dir[PARSED_DIR.join("*.yml")]
    abort "No YAML files found in #{PARSED_DIR}. Run podujatia:parse first." if ymls.empty?

    require "yaml"
    total_years = 0
    total_perfs = 0
    skipped     = 0

    ymls.each do |yml|
      puts "\nImporting #{File.basename(yml)} ..."
      data = YAML.safe_load_file(yml, permitted_classes: [ Symbol ])

      year = data["year"].to_i

      # --- AssemblyYear + rich-text description ---
      ay = AssemblyYear.find_or_create_by!(assembly: assembly, year: year)
      if data["year_description"].present? && ay.description.to_plain_text.blank?
        ay.description = data["year_description"]
        ay.save!
        total_years += 1
        puts "  Set description for year #{year}"
      else
        puts "  Year #{year}: description already set or not present, skipping."
      end

      # --- Performances ---
      (data["performances"] || []).each do |p|
        date_from = Date.parse(p["date_from"]) rescue nil
        next unless date_from

        date_to   = p["date_to"].present? ? (Date.parse(p["date_to"]) rescue nil) : nil
        name      = p["name"].to_s.strip
        location  = p["location"].to_s.strip
        desc_text = p["description"].to_s.strip

        # Idempotency: skip if same (assembly, date, name) already exists
        if Performance.exists?(assembly: assembly, date: date_from, name: name)
          skipped += 1
          next
        end

        perf = Performance.new(
          assembly: assembly,
          date:     date_from,
          end_date: date_to,
          name:     name,
          location: location.presence
        )
        perf.description = desc_text if desc_text.present?
        perf.save!
        total_perfs += 1
      end
    end

    puts "\n=== Import complete ==="
    puts "  AssemblyYears updated : #{total_years}"
    puts "  Performances imported : #{total_perfs}"
    puts "  Skipped (duplicates)  : #{skipped}"
    puts "\nRemember to reindex Meilisearch:"
    puts "  bin/rails runner 'Performance.clear_index!; Performance.reindex!'"
  end
end

# ============================================================
# Parser class (kept here for locality; move to lib/ if grows large)
# ============================================================
class PodujatiaParser
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

  def parse
    performances        = []
    year_desc_lines     = []
    header_collected    = false
    current             = nil

    @lines.each do |line|
      # Lines indented more than 10 chars are embedded program details, not headers
      indent = line.match(/\A( *)/)[1].length
      if indent <= 10 && (parsed = match_date_line(line))
        header_collected = true
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
      elsif !header_collected && line.strip.present? && !ARTIFACT_LINE_RE.match?(line)
        year_desc_lines << line
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
