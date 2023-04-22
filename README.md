# Smart Book

This project is built on Ruby on Rails as a backend framework, using Ruby version 3.2.2. The UI is built using Vite and React, with the directory for the UI being `book-ui`.

## Installation

1. Clone this repository to your local machine using `git clone https://github.com/maheshdhoran/smart-book.git`.
2. Install the required dependencies by running `bundle install`.
3. Install the Node.js dependencies by running `npm install` in the `book-ui` directory.

## Environment Variables

Refer to `.env.example` for understanding the required environment variables:

1. `MONGODB_URI`: This variable is used to specify the MongoDB connection string.
2. `API_KEY`: This variable is used to specify the OpenAI API key.

## Usage

1. Start the Rails server by running `rails s`.
2. Start the Vite development server by running `npm run dev` in the `book-ui` directory.
3. Visit `localhost:3000` in your web browser to view the application.

## Deployment

This application has been deployed to Netlify and can be accessed at https://smart-book-ai.netlify.app/.