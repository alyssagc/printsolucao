FROM ruby:3.2.2-slim

WORKDIR /app

# Instala dependências do sistema necessárias para gems nativas
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Instala gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without development && bundle install

# Copia o restante do projeto
COPY . .

# Cria diretórios necessários em runtime
RUN mkdir -p log output

CMD ["bundle", "exec", "rake", "jobs:process_pos"]
