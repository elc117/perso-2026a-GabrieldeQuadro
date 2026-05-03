# ── Etapa 1: build ────────────────────────────────────────────
FROM haskell:9.4 AS builder

WORKDIR /app

# Copia o .cabal primeiro para cachear as dependências
COPY pokeguess.cabal ./
RUN cabal update && cabal build --only-dependencies -j4

# Copia o restante do código e compila
COPY . .
RUN cabal build exe:pokeguess -j4

# Copia o executável para um local fixo
RUN cp $(cabal list-bin exe:pokeguess) /app/pokeguess-exe

# ── Etapa 2: imagem final (menor) ─────────────────────────────
FROM debian:bullseye-slim

WORKDIR /app

# Dependências de runtime do GHC
RUN apt-get update && apt-get install -y \
  libgmp10 \
  libffi7 \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copia executável e arquivos estáticos
COPY --from=builder /app/pokeguess-exe ./pokeguess
COPY static/ ./static/

# Porta padrão (o Render injeta $PORT automaticamente)
ENV PORT=3000
EXPOSE 3000

CMD ["./pokeguess"]
