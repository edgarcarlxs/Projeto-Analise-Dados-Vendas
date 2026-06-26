-- PARTE 1
SELECT 
    OD.OrderID AS ID_Pedido,
    P.ProductName AS Nome_Produto,
    P.UnitPrice AS Preco_Tabela,
    OD.UnitPrice AS Preco_Venda,
    ROUND((P.UnitPrice - OD.UnitPrice), 2) AS Diferenca_Preco,
    OD.Quantity AS Quantidade_Vendas
FROM orderdetails OD
JOIN products P ON OD.ProductID = P.ProductID
WHERE OD.UnitPrice < P.UnitPrice -- trazendo os casos onde o preço cobrado foi menor
ORDER BY Diferenca_Preco DESC; -- ordenando os produtos vendidos a partir daqueles com maior diferença

-- PARTE 2
SELECT 
    -- gerando um ranking da performance dos funcionários
    ROW_NUMBER() OVER (ORDER BY SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) DESC) AS Posicao,
    
    -- juntando o nome e o sobrenome do funcionário em uma única coluna
    E.FirstName || ' ' || E.LastName AS Nome_Funcionario,
    
    -- criando uma classificação para destacar funcionário avaliado em relação aos demais no ranking
    CASE 
        WHEN E.FirstName = 'Robert' THEN 'Funcionário Avaliado'
        ELSE 'Demais Funcionários'
    END AS Status_Funcionario,
    
    -- contagem de pedidos atendidos por cada funcionário
    COUNT(DISTINCT O.OrderID) AS Quantidade_Pedidos,
    
    -- soma do valor líquido vendido (considerando preço, quantidade e desconto)
    ROUND(SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)), 2) AS Valor_Total

FROM orders_cleaned O
JOIN employees E ON O.EmployeeID = E.EmployeeID
JOIN orderdetails OD ON O.OrderID = OD.OrderID
WHERE strftime('%Y', O.OrderDate) = '2022' -- verificando apenas o ano de 2022
GROUP BY E.EmployeeID 
ORDER BY Valor_Total DESC; -- ordenando do maior faturamento para o menor

-- PARTE 3
SELECT 
    -- gerando um ranking dos produtos em relação aos preços
    ROW_NUMBER() OVER (ORDER BY P.UnitPrice DESC) AS Posicao,
    P.ProductID AS ID_Produto,
    P.ProductName AS Nome_Produto,
    P.UnitPrice AS Preco
FROM products P
ORDER BY P.UnitPrice DESC -- ordenando do maior preço para o menor
LIMIT 10; -- definindo para exibir os 10 produtos com maiores preços

-- PARTE 4
SELECT 
    S.CompanyName AS Fornecedor,
    
    -- somando o faturamento líquido considerando quantidade, preço e desconto em 2020
    ROUND(SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2020' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END), 2) AS Faturamento_2020,
    
    -- agora em 2021
    ROUND(SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2021' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END), 2) AS Faturamento_2021,
    
    -- calculando a variação subtraindo o ganho de 2020 do ganho de 2021
    ROUND(
        SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2021' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END) - 
        SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2020' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END), 2
    ) AS Variacao,

    -- fazendo uma análise percentual de aumento de um ano para outro
    ROUND(
        ((SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2021' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END) - 
          SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2020' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END)) / 
          NULLIF(SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2020' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END), 0)) * 100, 2
    ) AS Percentual_Crescimento,

    -- classificando o comportamento do fornecedor com base na variação financeira
    CASE 
        WHEN (SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2021' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END) - 
              SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2020' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END)) > 1000 THEN 'Aumento'
        WHEN (SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2021' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END) - 
              SUM(CASE WHEN strftime('%Y', O.OrderDate) = '2020' THEN (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) ELSE 0 END)) < -1000 THEN 'Diminuição'
        ELSE 'Manteve Estável'
    END AS Situacao

FROM orderdetails OD
JOIN orders_cleaned O ON OD.OrderID = O.OrderID
JOIN products P ON OD.ProductID = P.ProductID
JOIN suppliers S ON P.SupplierID = S.SupplierID
WHERE strftime('%Y', O.OrderDate) IN ('2020', '2021') -- processando apenas esses dois anos (2020 e 2021)
GROUP BY S.SupplierID, S.CompanyName -- agrupando por fornecedor para consolidar os valores
ORDER BY Variacao DESC; -- coloca em ordem os fornecedores pelo critério dos que mais cresceram em faturamento