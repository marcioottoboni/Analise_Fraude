# Passo a passo para a importação do CSV tratado no Postgres


## Passo 1 - Criação da tabela


CREATE TABLE transacoes (
    TEMPO_DECORRIDO INTEGER,
    TIPO_TRANSACAO VARCHAR(20),
    VALOR NUMERIC(18, 2),
    ID_CLIENTE VARCHAR(50),
    SALDO_CLIENTE_ANTERIOR NUMERIC(18, 2),
    SALDO_POSTERIOR NUMERIC(18, 2),
    ID_ESTABELECIMENTO VARCHAR(50),
    SALDO_ESTABELECIMENTO_ANTERIOR NUMERIC(18, 2),
    SALDO_ESTABELECIMENTO_POSTERIOR NUMERIC(18, 2),
    TRANSACAO_FRAUDULENTA INTEGER,
    MARCADA_POR_REGRA INTEGER,
    UF_ESTABELECIMENTO CHAR(2)
);


## Passo 2 -  Importação do .csv

copy transacoes FROM '/Users/user/Documents/DevAgregarti/Portifolio Web/Arquivos Projetos/Análise de Fraudes/dados_analise_fraude_v2.csv' WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');																