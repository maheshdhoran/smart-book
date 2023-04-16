class AskController < ApplicationController
  COMPLETIONS_MODEL = "text-davinci-003"

  MODEL_NAME = "curie"
  QUERY_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-query-001"

  MAX_SECTION_LEN = 500
  SEPARATOR = "\n* "
  $separator_len = 3

  COMPLETIONS_API_PARAMS = {
    "temperature": 0.0,
    "max_tokens": 150,
    "model": COMPLETIONS_MODEL,
  }
  
  def ask
    if !params.key?(:question)
      render json: { error: "question key not found in payload" }, status: :bad_request
      return
    end

    raw_question = params[:question].to_s.strip
    if raw_question.empty?
      render json: { error: "question is empty" }, status: :bad_request
      return
    end

    if raw_question[-1] != "?"
      raw_question += "?"
    end

    question = Questions.where({question: raw_question.downcase.chomp("?").strip}).first
    if question.nil?
      answer = getAnswer(raw_question)
      
      new_question = Questions.new(question: raw_question.downcase.chomp("?").strip, answer: answer.strip)
      new_question.save

      render json: { answer: answer.strip }, status: :ok
    else
      question.counter += 1
      question.save
      render json: { answer: question.answer }, status: :ok
    end
  end

  def get_embedding(text, model)
    result = CLIENT.embeddings(
      parameters: {
        model: "text-search-curie-doc-001",
        input: text
      }
    )
    Numo::NArray.cast(result["data"][0]["embedding"])
  end

  def get_query_embedding(text)
    get_embedding(text, QUERY_EMBEDDINGS_MODEL)
  end

  def vector_similarity(x, y)
      x.dot(y)
  end

  def order_document_sections_by_query_similarity(query, contexts)
    query_embedding = get_query_embedding(query)

    document_similarities = contexts.map do |doc_index, doc_embedding|
      [vector_similarity(query_embedding, doc_embedding), doc_index]
    end.sort_by { |similarity, _| -similarity }

    document_similarities
  end

  def construct_prompt(question, context_embeddings, df)
    most_relevant_document_sections = order_document_sections_by_query_similarity(question, context_embeddings)

    chosen_sections = []
    chosen_sections_len = 0
    chosen_sections_indexes = []

    most_relevant_document_sections.each do |_, section_index|
      document_section = df.find { |row| row['title'] == section_index }

      chosen_sections_len += document_section['tokens'].to_i + $separator_len
      if chosen_sections_len > MAX_SECTION_LEN
        space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
        chosen_sections << "#{SEPARATOR}#{document_section['content'][0...space_left]}"
        chosen_sections_indexes << section_index.to_s
        break
      end

      chosen_sections << "#{SEPARATOR}#{document_section['content']}"
      chosen_sections_indexes << section_index.to_s
    end

    chosen_sections.join('')+"\n\n\nQ: " + question + "\n\nA: "
  end


  def answer_query_with_context(query, df, document_embeddings)
    prompt = construct_prompt(query, document_embeddings, df)

    response= CLIENT.completions(
      parameters: {
        prompt: prompt,
        **COMPLETIONS_API_PARAMS
    })
    response["choices"][0]["text"].gsub("\n\n", "")
  end

  def load_embeddings(fname)
    df = CSV.read(fname, headers: true)
    max_dim = df.headers.reject{ |h| h == "title" }.map(&:to_i).max
    embeddings = {}
      df.each do |row|
        title = row['title']
        embedding = (0..max_dim).map{ |i| row[i.to_s].to_f }
        embeddings[title] = embedding
      end
    embeddings
  end


  def getAnswer(question_asked)
    df = CSV.read("#{Rails.root}/storage/book.pdf.pages.csv", headers: true)
    document_embeddings = load_embeddings("#{Rails.root}/storage/book.pdf.embeddings.csv")

    return answer_query_with_context(question_asked, df, document_embeddings)
  end
end