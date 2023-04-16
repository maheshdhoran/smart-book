class Questions
    include Mongoid::Document
    include Mongoid::Timestamps
    field :question, type: String
    field :answer, type: String
    field :counter, type: Integer, default: 1
end