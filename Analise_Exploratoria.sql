#  Nesse arquivo temos os scripts  e explicações a cerca da análise exploratória dos dados possivelmente  fraudulentos e possíveis  insighs que podemos pegar  desses dados.



-- Análise exploratória de dados


-- 1. VISÃO GERAL
--  Como a base tem mais de meio milhão de transações o script abaixo deve demorar aproximadamente um minuto ou mais.

'''
	DICAS  PARA LER OS DADOS
	1-  A QUANTIDADE DE TRANSAÇÕES SÓ MOSTRARÁ QUANTAS TRANSAÇÕES TEMOS NA BASE COMO NÃO TEM FILTRO ALGUM DE TIPO, VALOR ETC
	2-  A QUANTIDADE DE FRAUDES REFLETE O APONTAMENTO DE FRAUDES  RECLAMADA PELOS PROPRIETÁRIOS DE CARTAO
	3 - O VALOR FRAUDADO É A SOMA DO VALOR DAS TRANSAÇÕES QUE FORAM RECLAMADAS COMO FRAUDE
'''

SELECT
    COUNT(*)                                                            AS QTD_TRANSACOES,
    COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)                   AS QTD_FRAUDES,
    ROUND(100.0 * COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)
          / COUNT(*), 4)                                                AS PERCENTUAL_FRAUDE,
    ROUND(SUM(valor) FILTER (WHERE transacao_fraudulenta = 1), 2)       AS VALOR_FRAUDE,
    ROUND(100.0 * SUM(valor) FILTER (WHERE transacao_fraudulenta = 1)
          / SUM(valor), 4)                                              AS PCT_VALOR_FRAUDES,
    COUNT(DISTINCT id_cliente)                                          AS CLIENTES_DISTINTOS,
    COUNT(DISTINCT id_estabelecimento)                                  AS ESTABELECIMENTOS_DISTINTOS
FROM transacoes;


--2. Análise de  qualidade

'''
DICAS SOBRE QUALIDADE 
	1- A CHECAGEM ABAIXO É BASICA E SÓ REPRESENTA O MINIMO QUE DEVER SER  CHECADO.
	2- É UMA BOA PRATICA FAZER UMA ANÁLISE DISTINTA DE CADA UMA DAS COLUNAS E GARANTIR QUE TODAS AS VARIAÇÕES DE CONTEÚDO DENTRO DE CADA COLUNA SEGUE AS DIRETRIZES DA EMPRESA 
	3- SEMPRE CONFIRME COM OS USUÁRIOS RESPONSAVEIS POR GERAR AS INFORMAÇÕES TODAS AS VARIAÇÕES  ENCONTRADAS EM CADA COLUNA
	4- SEMPRE APLIQUE NÃO SÓ CHECAGENS NUMÉRICAS E DE TIPO MAS TAMBÉM O BOM SENCO COMO: EM UM CAMPO IDADE EU POSSO TER  ALGO MAIOR QUE 120?NÃO !
	5- NUMEROS NEGATIVOS PODEM SIM SER CORRETOS PORÉM MUITO CUIDADO COM  COMO ELES FORAM GERADOS 
'''


SELECT
    COUNT(*) FILTER (WHERE valor IS NULL OR valor <= 0)                 AS valor_invalido,
    COUNT(*) FILTER (WHERE tipo_transacao IS NULL)                      AS tipo_nulo,
    COUNT(*) FILTER (WHERE uf_estabelecimento IS NULL)                  AS uf_nula,
    COUNT(*) FILTER (WHERE id_cliente = id_estabelecimento)             AS cliente_igual_estabelecimento,
    COUNT(*) FILTER (WHERE saldo_cliente_anterior < 0
                        OR saldo_posterior < 0)                         AS saldo_cliente_negativo,
    COUNT(*) FILTER (WHERE transacao_fraudulenta NOT IN (0, 1))         AS flag_fraude_invalida
FROM transacoes;

-- Linhas duplicadas
'''
DICAS PARA MELHOR ENTENDIMENTO DE DUPLICADOS

1- NEM SEMPRE O  DUPLICADO É O QUE PARECE, TABELAS CUJO A CHAVE PRIMÁRIA DA TABELA OU A LÓGICA DE NEGOCIO POR TRAZ DA TABELA  PODEM ENGANAR 
2- AO ENCONTRAR DUPLICADO SE POSSÍVEL OPTE PELA DELEÇÃO  OU  FILTRO LÓGICO DESSA INFORMAÇÃO  PARA EVITAR POSSIVEIS PROBLEMAS FUTUROS
3- NÃO É O CASO DESSA TABELA PORÉM ALGUMAS TABELA PODEM CONTER ITENS QUE SÃO ÚNICOS QUANDO RELACIONADOS A OUTRA EXEMPLO UM NUMERO DE CPF NÃO PODE APARECER DUAS VEZES  PARA DOIS CLIENTES  
'''

SELECT tempo_decorrido, tipo_transacao, valor, id_cliente, id_estabelecimento, COUNT(*) AS qtd
FROM transacoes
GROUP BY tempo_decorrido, tipo_transacao, valor, id_cliente, id_estabelecimento
HAVING COUNT(*) > 1
ORDER BY qtd DESC;


-- 3. FRAUDE POR TIPO DE TRANSAÇÃO

'''
DICAS DE  ANÁLISE 
1- SEMPRE SEGREGE AS INFORMAÇÕES POR CADA UM DOS TIPOS E UNIA ISSO A CONTAGENS AS VEZES O DESVIO SE MOSTRA OBVIO 
2 - QUANTIDADE  ALTA DE TRANSAÇÕES FRAUDULENTAS EM UM DETERMINADO TIPO PODE SÓ SIGNIFICAR QUE AQUELE TIPO TEVE MUITO MAIS TRANSAÇÃO  (CUIDADO COM VIES )
3- SEMPE LEVE EM CONTA  QUANTIDADE E VALOR POIS PEGAR MIL FRAUDES DE 0,1 CENTAVO E DEIXAR PASSAR 1 DE 1000 REAIS  NÃO VAI AJUDAR 
4- O IMPACTO NO CLIENTE SEMPRE IMPORTA PRINCIPALMENTE  EM HORÁRIOS E SITUAÇÕES QUE POREM ATÉ SIGUINIFICAR PEDIGO PARA O CLIENTE 

'''

SELECT
    tipo_transacao,
    COUNT(*)                                                            AS qtd,
    COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)                   AS fraudes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)
          / COUNT(*), 4)                                                AS taxa_fraude_pct,
    ROUND(AVG(valor), 2)                                                AS valor_medio,
    ROUND(AVG(valor) FILTER (WHERE transacao_fraudulenta = 1), 2)       AS valor_medio_fraude,
    ROUND(AVG(valor) FILTER (WHERE transacao_fraudulenta = 0), 2)       AS valor_medio_legitima
FROM transacoes
GROUP BY tipo_transacao
ORDER BY fraudes DESC, qtd DESC;

-- 4. FRAUDE POR UF DO ESTABELECIMENTO
'''
DICAS PARA  ANALISAS DADOS EM ESTADOS DIFERENTES 
1- SEMPRE CONSIDERE A REALIDADE DO ESTADO 2000 REAIS EM UM SUPER MERCADO EM SÃO PAULO POR SI SÓ NÃO É UM INDICADOR FORTE MAS NO INTERIOR DO ACRE AS 03:00  DA MANHA 
2- QUANDO POSSIVEL ANALISE SE O VALOR ESTÁ DENTRO DA MÉDIA POR UF E TIPO (O DESVIO PADRAO PEGA MUITA COISA)
3- AO ANASAR NUMEROS PRINCIPALMENTE  FIQUE ATENDO A VALORES MÁXIMOS E MINIMOS POR  PODEM AFETAR A MÉDIA DRASTICAMENTE TENTE LIMPAR ESSES VALOR E SE POSSIVEL USAR A MEDIANA
'''

SELECT
    uf_estabelecimento,
    COUNT(*)                                                            AS qtd,
    COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)                   AS fraudes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)
          / COUNT(*), 2)                                                AS taxa_fraude_pct,
    ROUND(SUM(valor) FILTER (WHERE transacao_fraudulenta = 1), 2)       AS valor_fraudado
FROM transacoes
GROUP BY uf_estabelecimento
ORDER BY fraudes DESC, valor_fraudado DESC NULLS LAST;


-- 5. DISTRIBUIÇÃO DE VALORES: FRAUDE x LEGÍTIMA
'''
DIAS PARA ANÁLISE DE VALORES
1- Na seguimentação de valor  olhe sempre para a concentração todal  de transações naquela faixa de valor não só para  as fraudes naquela faixa de  valor 
2- Os diferentes tipos de usuário costumam ter muita variação  de valor exemplo:  Pessoa milhonária  vs Aposentado que ganha salário minimo  poucas transações na fatia dos mais ricos podem siguinificar muito valor  pouca transaçao
3- Valores baixo e aparentemente normais  quando acontecem em sequencia de tempo  costumam ser perigosos 
'''
SELECT
    transacao_fraudulenta,
    COUNT(*)                                                            AS qtd,
    ROUND(MIN(valor), 2)                                                AS minimo,
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY valor))::numeric, 2) AS p25,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor))::numeric, 2) AS mediana,
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY valor))::numeric, 2) AS p75,
    ROUND((PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY valor))::numeric, 2) AS p95,
    ROUND(MAX(valor), 2)                                                AS maximo,
    ROUND(AVG(valor), 2)                                                AS media
FROM transacoes
GROUP BY transacao_fraudulenta
ORDER BY transacao_fraudulenta;

-- Faixas de valor
'''
DICAS PARA LER  OS DADOS NAS DIFFERENTES FAIXAR DE VALOR 
1- SEMPRE FOQUE NOS VALORES ALTOS  EM ESPECIAL OS SEGUIDOS DE MUITAS TRANSAÇÕES BAIXAS (POC)
2- FAIXA + TIPO JÁ PODE TE DIZER MUITO SEMPRE  CONSIDERE A FAIXA  DE VALOR POR  GRUPO DE  TRANSAÇÕES.
'''

SELECT
    CASE
        WHEN valor <    1000  THEN '1) < 1 mil'
        WHEN valor <   10000  THEN '2) 1 mil - 10 mil'
        WHEN valor <  100000  THEN '3) 10 mil - 100 mil'
        WHEN valor <  200000  THEN '4) 100 mil - 200 mil'
        WHEN valor < 1000000  THEN '5) 200 mil - 1 mi'
        ELSE                       '6) >= 1 mi'
    END                                                                 AS faixa_valor,
    COUNT(*)                                                            AS qtd,
    COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)                   AS fraudes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)
          / COUNT(*), 2)                                                AS taxa_fraude_pct
FROM transacoes
GROUP BY 1
ORDER BY 1;

-- 6. ASSINATURAS DE SALDO (onde a fraude costuma se revelar)
'''
DICAS PARARA  ANALISAR AS TRANSAÇÕES COM BASE NO SALDO 
1 - CLIENTE QUE JÁ ESTAVAM ZERADOS E  TENTAM MULTIPLAS TRANSAÇÕES GERALMENTE GERAM PREOCUPAÇAO 
2 - CLIENTES COM O SALDO MUITO  ALTO MESMO SEM  TRANSAÇÕES FRAUDULENTAS DEVEM SER MONITORADOS DE PROXIMO 
3 - CLIENTES COM SALDO NÃO MODIFICADO A MUITO TEMPO ENTÃO DEREPENTE  O SALDO COMECA A SER DRENADO RAPIDAMENTE  PODE  INDICAR FRAUDES.

'''
SELECT
    transacao_fraudulenta,
    COUNT(*) AS qtd,

    -- esvazia a conta do cliente (tinha saldo e ficou zerada)
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE saldo_cliente_anterior > 0 AND saldo_posterior = 0) / COUNT(*), 2)
        AS pct_esvazia_cliente,

    -- cliente já estava com saldo zero
    ROUND(100.0 * COUNT(*) FILTER (WHERE saldo_cliente_anterior = 0) / COUNT(*), 2)
        AS pct_cliente_saldo_zero,

    -- valor maior que o saldo disponível
    ROUND(100.0 * COUNT(*) FILTER (WHERE valor > saldo_cliente_anterior) / COUNT(*), 2)
        AS pct_valor_maior_que_saldo,

    -- destino (conta C) sem movimento de saldo: o dinheiro "some"
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE LEFT(id_estabelecimento, 1) = 'C'
          AND saldo_estabelecimento_anterior = 0
          AND saldo_estabelecimento_posterior = 0) / COUNT(*), 2)
        AS pct_destino_sem_movimento,

    -- inconsistência contábil no cliente: anterior - valor <> posterior
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE ABS((saldo_cliente_anterior - valor) - saldo_posterior) > 0.01) / COUNT(*), 2)
        AS pct_inconsistencia_cliente,

    -- inconsistência contábil no destino (contas C): anterior + valor <> posterior
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE LEFT(id_estabelecimento, 1) = 'C'
          AND ABS((saldo_estabelecimento_anterior + valor)
                  - saldo_estabelecimento_posterior) > 0.01) / COUNT(*), 2)
        AS pct_inconsistencia_destino
FROM transacoes
GROUP BY transacao_fraudulenta
ORDER BY transacao_fraudulenta;

-- 7.2 Mesmos indicadores agora por tipo
-- O Objetivo dessa análise é  entender qual o  tipo está concentrada a fraude.
SELECT
    tipo_transacao,
    transacao_fraudulenta,
    COUNT(*) AS qtd,
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE saldo_cliente_anterior > 0 AND saldo_posterior = 0) / COUNT(*), 2)
        AS pct_esvazia_cliente,
    ROUND(100.0 * COUNT(*) FILTER (WHERE saldo_cliente_anterior = 0) / COUNT(*), 2)
        AS pct_cliente_saldo_zero,
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE saldo_estabelecimento_anterior = 0
          AND saldo_estabelecimento_posterior = 0) / COUNT(*), 2)
        AS pct_destino_sem_movimento
FROM transacoes
WHERE tipo_transacao IN (SELECT DISTINCT tipo_transacao
                         FROM transacoes
                         WHERE transacao_fraudulenta = 1)
GROUP BY tipo_transacao, transacao_fraudulenta
ORDER BY tipo_transacao, transacao_fraudulenta;




-- 8 Contas que recebem fraude repetidamente (candidatas a "mula")
'''
Dicas para analisar o recebedor da  fraude

1-  Sempre procure um estabelecimento, cliente  que  aparece em  multiplas fraudes 
2 - Sempre olhe para a média de ganhos dos estabelecimentos  de um determinado tipo 
'''

SELECT
    id_estabelecimento,
    COUNT(*)                                                            AS fraudes_recebidas,
    COUNT(DISTINCT id_cliente)                                          AS vitimas_distintas,
    ROUND(SUM(valor), 2)                                                AS valor_recebido,
    MIN(tempo_decorrido)                                                AS primeira_hora,
    MAX(tempo_decorrido)                                                AS ultima_hora,
    ARRAY_AGG(DISTINCT uf_estabelecimento)                              AS ufs
FROM transacoes
WHERE transacao_fraudulenta = 1
GROUP BY id_estabelecimento
HAVING COUNT(*) >= 2
ORDER BY fraudes_recebidas DESC, valor_recebido DESC
LIMIT 50;


-- 9. CLIENTES COM MÚLTIPLAS TRANSAÇÕES (velocidade / sequência)

'''
	1 - Na análise de fraudes a velocidade (quantidade de vezes  em que  um determinado tipo de transações aparece) pode determinar fraudes facilmente
	2 - Na grange maioria das fraudes  que envolvem grande valor o fraudador faz algumas transações  de baixo valor em sequencia antes da transação de alto valor
	3 - Embora a velocidade por si só não diga tanto  mas associada a outra coisas como geografia por exemplo pode evitar muitas fraudes Ex: Transção em mais de uma UF dentro de um curto periodo. 
'''


SELECT
    id_cliente,
    COUNT(*)                                                            AS qtd_transacoes,
    COUNT(*) FILTER (WHERE transacao_fraudulenta = 1)                   AS fraudes,
    ROUND(SUM(valor), 2)                                                AS valor_total,
    MIN(tempo_decorrido)                                                AS primeira_hora,
    MAX(tempo_decorrido)                                                AS ultima_hora
FROM transacoes
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY fraudes DESC, qtd_transacoes DESC
LIMIT 50;


-- 10. EFICIÊNCIA DA REGRA ATUAL (marcada_por_regra) x FRAUDE REAL

'''
Dicas para analisar a eficácia da análise de fraude


1 - A eficacia  de uma estratégia de fraude se resume ao minimo de cliente perturbados com  bloqueios (falso positivo) e  o maior valow monetário possivel.
2 - Mesmo que não estejam sofrendo fraudes no momento  sempre monitore os clientes vip pois importuna-los pode ser tão ruim quanto deixar passar fraudes 
3 - As fraudes de diferentes tipos costumas acontecer em horários diferentes 
4 - A Sobreposição de extratégias de fraude (+ de um tipo de transação sendo marcada pela mesma regra)  deve ser evitada  pois isso por confundir a análise dos dados
'''

SELECT
    marcada_por_regra,
    transacao_fraudulenta,
    COUNT(*)                                                            AS qtd,
    ROUND(SUM(valor), 2)                                                AS valor
FROM transacoes
GROUP BY marcada_por_regra, transacao_fraudulenta
ORDER BY marcada_por_regra, transacao_fraudulenta;

-- Limiar aparente da regra atual
SELECT
    tipo_transacao,
    MIN(valor) FILTER (WHERE marcada_por_regra = 1)                     AS menor_valor_marcado,
    MAX(valor) FILTER (WHERE marcada_por_regra = 0
                         AND transacao_fraudulenta = 1)                 AS maior_fraude_nao_marcada,
    COUNT(*) FILTER (WHERE marcada_por_regra = 0
                       AND transacao_fraudulenta = 1)                   AS fraudes_nao_pegas
FROM transacoes
GROUP BY tipo_transacao;


-- 13. LISTA DE FRAUDES PARA INSPEÇÃO MANUAL
'''
 1 - quando se tem uma base de fraudes registradas sempre priorize a análise dessas transações 
 2 - Sempre cruze o hitórico de  fraudes passadas  para tentar entender a fraude futura 
 3 - Monitore em especial estabelecimentos que foram complacentes com fraude mais de uma vez
 '''

SELECT *
FROM transacoes
WHERE transacao_fraudulenta = 1
ORDER BY tempo_decorrido, valor DESC;