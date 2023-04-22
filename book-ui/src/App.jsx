import { useState } from "react";
import bookCover from "./images/book-cover.png"
import Typist from "react-typist-component";

function App() {
  const [question, setQuestion] = useState("who is rich dad?");
  const [answer, setAnswer] = useState(null);
  const [loading, setLoading] = useState(false);
  const [typingDone, setTypingDone] = useState(false);

  const fetchAnswer = async () => {
    if (question.trim().length === 0) {
      alert("Question is empty!");
    } else {
      setLoading(true);
      const response = await fetch("https://ec2-43-205-192-178.ap-south-1.compute.amazonaws.com/ask", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          question: question
        }),
      });
      const data = await response.json();
      setAnswer(data.answer);
      setLoading(false);
    }
  };

  const isTypingDone = () => {
    setTypingDone(true);

    window.scrollTo({
      top: document.body.scrollHeight,
      behavior: "smooth",
    });
  };

  const handleRefresh = () => {
    setQuestion("");
    setAnswer(null);
    setLoading(false);
    setTypingDone(false);
  };

  return (
    <>
      <div className={"text-center mt-10 font-serif text-3xl drop-shadow-md"}>
        Smart Book
      </div>
      <div className={"sm:mt-20 mt-10 mx-10"}>
        <div className={"grid sm:grid-cols-3 grid-cols-1 gap-y-10 gap-x-5"}>
          <div className={"sm:col-span-1"}>
            <img
              className={
                "w-32 mx-auto sm:w-60 sm:h-80 shadow-md shadow-gray-300"
              }
              src={bookCover}
            ></img>
          </div>
          <div className={"sm:col-span-2"}>
            <p className={"sm:text-lg text-slate-500"}>
              Ask a question and get a relevant answer from a book's context
              with our AI-powered website. Try it now!
            </p>
            <div className={"w-full mt-5"}>
              <textarea
                className={
                  "appearance-none placeholder:italic placeholder:text-slate-400 border-2 rounded-md w-full sm:w-3/5 font-mono block p-2"
                }
                placeholder={"Your question goes here..."}
                value={question}
                onChange={(e) => setQuestion(e.target.value)}
              ></textarea>
              {!answer && (
                <button
                  className={`hover:bg-gray-400 ${
                    loading ? "bg-gray-400" : "bg-gray-300"
                  } text-gray-800 font-bold py-2 px-4 mt-5 rounded`}
                  onClick={fetchAnswer}
                  disabled={loading}
                >
                  {loading ? "Asking..." : "Ask question"}
                </button>
              )}
              {answer && (
                <div className={"sm:w-3/5 mt-5"}>
                  <p>
                    <b>Answer:</b>{" "}
                    <Typist typingDelay={40} onTypingDone={isTypingDone}>
                      {answer}
                    </Typist>
                  </p>
                </div>
              )}
              {typingDone && (
                <button
                  onClick={handleRefresh}
                  className={
                    "hover:bg-gray-400 bg-gray-300 text-gray-800 font-bold py-2 px-4 mt-5 mb-2 rounded"
                  }
                >
                  Ask another question
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default App;
