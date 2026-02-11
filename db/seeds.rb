# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Data specific for TD Bralen, which is the only assembly we have at the moment. Stored in db/data/.
require "csv"

def prune_db
  print "Cleaning up db... \n"
  MemberOfAssembly.delete_all
  Member.delete_all
  Performance.delete_all
  Assembly.delete_all
end

def load_data
  print "Loading data ... \n"
  assemblies_lookup = {}

  CSV.foreach(Rails.root.join("db/data/assemblies.csv"), headers: true) do |row|
    assembly = Assembly.create!(
      name: row["name"],
      subdomain: row["subdomain"]
    )
    assemblies_lookup[row["assembly_code"]] = assembly
  end
  print "  loaded #{assemblies_lookup.size} assemblies ... \n"

  members_lookup = {}
  print "  loading members ... "
  CSV.foreach(Rails.root.join("db/data/members.csv"), headers: true) do |row|
    assembly = assemblies_lookup[row["assembly_code"]]
    member = Member.create!(
      name: row["name"],
      assembly: assembly
    )
    members_lookup[row["member_code"]] = member
  end
  print "  loaded #{members_lookup.size} members ... \n"

  members_of_assemblies_count = 0
  print "  loading relations ... "
  CSV.foreach(Rails.root.join("db/data/member_of_assemblies.csv"), headers: true) do |row|
    # print "  loading record #{row} ... \n"
    assembly = assemblies_lookup[row["assembly_code"]]
    member = members_lookup[row["member_code"]]
    begin
      MemberOfAssembly.create!(
        member: member,
        assembly: assembly,
        year: row["year"],
        group: row["group"],
      )
      members_of_assemblies_count += 1
    rescue ActiveRecord::RecordInvalid => e
      print "  \nSKIP: skipping record #{row} with error #{e}"
    end
  end
  print "  \nloaded #{members_of_assemblies_count} members of assemblies ... \n"
end

def index_data
  print "Indexing data ... \n"
  Member.clear_index!
  Performance.clear_index!
  Performance.reindex!
  Member.reindex!
end

prune_db
load_data
index_data
