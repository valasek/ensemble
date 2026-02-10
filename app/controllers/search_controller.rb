# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def proxy
    Rails.logger.info "Search params: #{params.inspect}"

    # Parse JSON body
    body = JSON.parse(request.body.read) rescue {}
    Rails.logger.info "Parsed body: #{body.inspect}"

    client = Meilisearch::Client.new(
      ENV.fetch("MEILISEARCH_URL", "http://meilisearch:7700"),
      ENV.fetch("MEILISEARCH_API_KEY", "development_key")
    )

    # Test connection
    begin
      health = client.health
      Rails.logger.info "Meilisearch health: #{health.inspect}"
    rescue => e
      Rails.logger.error "Health check failed: #{e.message}"
      return render json: { error: "Cannot connect to Meilisearch: #{e.message}" }, status: :service_unavailable
    end

    query = body["q"] || ""
    limit = (body["limit"] || 10).to_i

    # Vyhľadávanie vo viacerých indexoch naraz
    results = client.multi_search(
      queries: [
        {
          index_uid: "Performance",
          q: query,
          limit: limit
        },
        {
          index_uid: "Member",
          q: query,
          limit: limit
        }
      ]
    )

    # Skombinuj výsledky z oboch indexov
    combined_hits = []

    # Pridaj Performance výsledky
    if results["results"][0] && results["results"][0]["hits"]
      results["results"][0]["hits"].each do |hit|
        combined_hits << hit.merge("_type" => "performance")
      end
    end

    # Pridaj Member výsledky
    if results["results"][1] && results["results"][1]["hits"]
      results["results"][1]["hits"].each do |hit|
        combined_hits << hit.merge("_type" => "member")
      end
    end

    # Spočítaj celkový počet výsledkov
    total_hits = (results["results"][0]&.dig("estimatedTotalHits") || 0) + 
                 (results["results"][1]&.dig("estimatedTotalHits") || 0)

    processing_time = [
      results["results"][0]&.dig("processingTimeMs") || 0,
      results["results"][1]&.dig("processingTimeMs") || 0
    ].max

    # Vráť skombinované výsledky
    render json: {
      hits: combined_hits,
      estimatedTotalHits: total_hits,
      processingTimeMs: processing_time,
      query: query
    }
  rescue => e
    Rails.logger.error("Search error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
    render json: {
      error: e.message,
      class: e.class.to_s
    }, status: :internal_server_error
  end
end
