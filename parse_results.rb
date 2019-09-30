require "open3"
require "net/http"
require "json"
require "time"

@headers = {
  "Content-Type": "application/json",
  "Accept": "application/vnd.github.antiope-preview+json",
  "Authorization": "Bearer #{ENV.fetch("GITHUB_TOKEN")}",
  "User-Agent": "sorbet-action"
}

@event = JSON.parse(File.read(ENV["GITHUB_EVENT_PATH"]))
@repository = @event["repository"]
@owner = @repository["owner"]["login"]
@repo = @repository["name"]

def create_check
  payload = {
    name: "Sorbet",
    head_sha: ENV["GITHUB_SHA"],
    status: "in_progress",
    started_at: Time.now.iso8601
  }

  http = Net::HTTP.new("api.github.com", 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs"

  res = http.post(path, payload.to_json, @headers)

  if res.code.to_i >= 300
    raise res.message
  end

  data = JSON.parse(res.body)
  data["id"]
end

def update_check(id:, conclusion:, output:)
  payload = {
    name: "Sorbet",
    head_sha: ENV["GITHUB_SHA"],
    status: "completed",
    completed_at: Time.now.iso8601,
    conclusion: conclusion,
    output: output
  }

  http = Net::HTTP.new('api.github.com', 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs/#{id}"

  puts payload.to_json

  res = http.patch(path, payload.to_json, @headers)

  if res.code.to_i >= 300
    raise res.message
  end
end

def run_sorbet
  _stdout, stderr, _status = Open3.capture3("bundle exec srb tc")

  output = stderr.split("\n")

  if output[0].strip == "No errors! Great job."
    # handle success here
    check_result = {
      title: "Sorbet",
      summary: "No problems found",
      annotations: []
    }
    return [
      check_result,
      "success"
    ]
  end

  annotations = []
  current_annotation = {}
  output.each do |line|
    # skip the line summarizing the number of errors
    next if line =~ /^Errors: \d+/

    if line =~ /^\S+:\d+/
      # start a new annotation
      parts = line.split(":")
      current_annotation = {
        path: parts[0],
        start_line: parts[1],
        end_line: parts[1],
        annotation_level: "failure",
        message: ""
      }
      annotations << current_annotation
    end
    current_annotation[:message] << line
  end

  check_result = {
    title: "Sorbet",
    summary: "#{annotations.count} problem(s) found",
    annotations: annotations
  }

  [
    check_result,
    "failure"
  ]
end

def run
  check_id = create_check
  begin
    output, conclusion = run_sorbet
    update_check(id: check_id, conclusion: conclusion, output: output)
    fail if conclusion == "failure"
  rescue
    update_check(id: check_id, conclusion: "failure", output: nil)
    fail
  end
end

run
