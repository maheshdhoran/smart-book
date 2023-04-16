#`require 'dotenv'
require 'pdf-reader'
require 'blingfire'
require 'openai'
require 'csv'
require 'json'
require 'rest-client'

#Dotenv.load('.env')
$client = OpenAI::Client.new(access_token: "YOUR_API_TOKEN")

$tokenizer = BlingFire.load_model("gpt2.bin")

COMPLETIONS_MODEL = 'text-davinci-003'
MODEL_NAME = 'curie'
DOC_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-doc-001"


def count_tokens(text)
  $tokenizer.text_to_ids(text).length
end

def extract_pages(page_text, index)
  return [] if page_text.empty?

  content = page_text.gsub(/\s+/, ' ').strip
  outputs = [["Page #{index}", content, count_tokens(content) + 4]]
end

filename = ARGV[0]

reader = PDF::Reader.new(filename)

res = []
i = 1

reader.pages.each do |page|
  res += extract_pages(page.text, i)
  i += 1
end

df = CSV.generate do |csv|
  csv << ['title', 'content', 'tokens']
  res.select { |r| r.last < 2046 }.each do |row|
    csv << row
  end
end

File.write("#{filename}.pages.csv", df)


def get_embedding(text, model)
  result = $client.embeddings(
    parameters: {
        model: model,
        input: text
    }
  )
  result['data'][0]['embedding']
end

def get_doc_embedding(text)
  get_embedding(text, DOC_EMBEDDINGS_MODEL)
end

def compute_doc_embeddings(df)
  embeddings = {}
  df.each_with_index do |row, i|
    embeddings[i] = get_doc_embedding(row['content'])
  end
  embeddings
end

df = CSV.read("#{filename}.pages.csv", headers: true)
doc_embeddings = compute_doc_embeddings(df)

CSV.open("#{filename}.embeddings.csv", 'w') do |csv|
  csv << ['title'] + (0...4096).to_a
  doc_embeddings.each do |i, embedding|
    csv << ["Page #{i + 1}"] + embedding
  end
end
